-- Quraan Pulaar - schéma Supabase (remplace le backend Spring)
--
-- Principe de sécurité :
--   * La clé anon (embarquée dans l'app) n'a AUCUN accès direct aux tables.
--   * L'app mobile passe uniquement par les RPC activate_code() et check_device().
--   * Les admins (comptes Supabase Auth listés dans app_admins) ont accès complet.
--
-- À exécuter une fois dans Dashboard > SQL Editor d'un projet vierge.
-- Penser aussi à désactiver les inscriptions : Authentication > Sign In / Providers
-- > "Allow new users to sign up" = OFF.

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.devices (
  id                 bigint generated always as identity primary key,
  unique_id          text not null unique,
  base_os            text,
  device_name        text,
  device_model       text,
  manufacturer       text,
  first_install_time text,
  first_seen_at      timestamptz not null default now(),
  last_seen_at       timestamptz not null default now(),
  legacy_id          bigint unique            -- id dans device_info_model (Spring)
);

create table public.activation_codes (
  id             bigint generated always as identity primary key,
  code           text not null unique,
  is_used        boolean not null default false,

  buyer_name     text,
  buyer_phone    text,
  buyer_country  text,
  price_mru      numeric,
  price_cfa      numeric,
  price_usd      numeric,

  device_id      bigint references public.devices(id) on delete set null,
  activated_at   timestamptz,

  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  created_by     uuid references auth.users(id) on delete set null,
  updated_by     uuid references auth.users(id) on delete set null,

  legacy_id      bigint unique,               -- id dans vente (Spring)
  legacy_seller  text                         -- username du vendeur (Spring)
);

create index activation_codes_device_id_idx on public.activation_codes(device_id);
create index activation_codes_buyer_phone_idx on public.activation_codes(buyer_phone);

create table public.activation_attempts (
  id            bigint generated always as identity primary key,
  unique_id     text,
  ip            text,
  success       boolean not null,
  attempted_at  timestamptz not null default now()
);

create index activation_attempts_uid_idx on public.activation_attempts(unique_id, attempted_at);
create index activation_attempts_ip_idx  on public.activation_attempts(ip, attempted_at);

create table public.app_admins (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- updated_at / updated_by automatiques
-- ---------------------------------------------------------------------------

create or replace function public.tg_activation_codes_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  if auth.uid() is not null then
    new.updated_by := auth.uid();
  end if;
  return new;
end;
$$;

create trigger activation_codes_touch
  before update on public.activation_codes
  for each row execute function public.tg_activation_codes_touch();

-- ---------------------------------------------------------------------------
-- Rôle admin
-- ---------------------------------------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.app_admins where user_id = auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security : rien pour anon, tout pour les admins
-- ---------------------------------------------------------------------------

alter table public.devices             enable row level security;
alter table public.activation_codes    enable row level security;
alter table public.activation_attempts enable row level security;
alter table public.app_admins          enable row level security;

revoke all on public.devices, public.activation_codes,
              public.activation_attempts, public.app_admins from anon;

create policy "admins_all_devices" on public.devices
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "admins_all_codes" on public.activation_codes
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "admins_read_attempts" on public.activation_attempts
  for select to authenticated
  using (public.is_admin());

create policy "admins_read_admins" on public.app_admins
  for select to authenticated
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- RPC app mobile
-- ---------------------------------------------------------------------------

-- IP du client telle que transmise par l'API Gateway Supabase.
create or replace function public._client_ip()
returns text
language sql
stable
set search_path = ''
as $$
  select nullif(split_part(
    coalesce(current_setting('request.headers', true)::json ->> 'x-forwarded-for', ''),
    ',', 1), '');
$$;

-- Active un code pour un appareil.
-- Renvoie {"success": true} ou {"success": false, "error": "<raison>"}.
--   invalid_request | too_many_attempts | invalid_code | code_already_used
create or replace function public.activate_code(
  p_code               text,
  p_unique_id          text,
  p_base_os            text default null,
  p_device_name        text default null,
  p_device_model       text default null,
  p_manufacturer       text default null,
  p_first_install_time text default null
)
returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code       public.activation_codes%rowtype;
  v_device_id  bigint;
  v_ip         text := public._client_ip();
  v_code_text  text := btrim(p_code);
  v_uid        text := btrim(p_unique_id);
begin
  if v_uid is null or v_uid = '' or v_code_text is null or v_code_text = '' then
    return json_build_object('success', false, 'error', 'invalid_request');
  end if;

  -- Anti force brute : 5 échecs/heure par appareil, 20 échecs/heure par IP.
  if (select count(*) from public.activation_attempts
        where unique_id = v_uid and not success
          and attempted_at > now() - interval '1 hour') >= 5
     or (v_ip is not null and (select count(*) from public.activation_attempts
        where ip = v_ip and not success
          and attempted_at > now() - interval '1 hour') >= 20)
  then
    return json_build_object('success', false, 'error', 'too_many_attempts');
  end if;

  select * into v_code
    from public.activation_codes
   where code = v_code_text
   for update;

  if not found then
    insert into public.activation_attempts(unique_id, ip, success) values (v_uid, v_ip, false);
    return json_build_object('success', false, 'error', 'invalid_code');
  end if;

  if v_code.is_used then
    -- Réinstallation sur le même appareil : on accepte.
    if exists (select 1 from public.devices d
                where d.id = v_code.device_id and d.unique_id = v_uid) then
      update public.devices set last_seen_at = now() where id = v_code.device_id;
      insert into public.activation_attempts(unique_id, ip, success) values (v_uid, v_ip, true);
      return json_build_object('success', true);
    end if;

    insert into public.activation_attempts(unique_id, ip, success) values (v_uid, v_ip, false);
    return json_build_object('success', false, 'error', 'code_already_used');
  end if;

  insert into public.devices (unique_id, base_os, device_name, device_model,
                              manufacturer, first_install_time)
  values (v_uid, p_base_os, p_device_name, p_device_model,
          p_manufacturer, p_first_install_time)
  on conflict (unique_id) do update
     set base_os            = excluded.base_os,
         device_name        = excluded.device_name,
         device_model       = excluded.device_model,
         manufacturer       = excluded.manufacturer,
         first_install_time = excluded.first_install_time,
         last_seen_at       = now()
  returning id into v_device_id;

  update public.activation_codes
     set is_used      = true,
         device_id    = v_device_id,
         activated_at = now()
   where id = v_code.id;

  insert into public.activation_attempts(unique_id, ip, success) values (v_uid, v_ip, true);
  return json_build_object('success', true);
end;
$$;

-- Vérifie qu'un appareil possède un code actif. Renvoie 'valid' ou 'invalid'.
create or replace function public.check_device(p_unique_id text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_device_id bigint;
begin
  select d.id into v_device_id
    from public.devices d
    join public.activation_codes c on c.device_id = d.id and c.is_used
   where d.unique_id = btrim(p_unique_id)
   limit 1;

  if v_device_id is null then
    return 'invalid';
  end if;

  update public.devices set last_seen_at = now() where id = v_device_id;
  return 'valid';
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC admin
-- ---------------------------------------------------------------------------

-- Crée une vente avec un nouveau code aléatoire à 10 chiffres.
create or replace function public.create_sale(
  p_buyer_name    text,
  p_buyer_phone   text,
  p_buyer_country text,
  p_price_mru     numeric default null,
  p_price_cfa     numeric default null,
  p_price_usd     numeric default null
)
returns public.activation_codes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code text;
  v_row  public.activation_codes;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  loop
    v_code := lpad(((('x' || encode(extensions.gen_random_bytes(8), 'hex'))::bit(64)::bigint
                     & 9223372036854775807) % 10000000000)::text, 10, '0');
    exit when left(v_code, 1) <> '0'
          and not exists (select 1 from public.activation_codes where code = v_code);
  end loop;

  insert into public.activation_codes
    (code, buyer_name, buyer_phone, buyer_country,
     price_mru, price_cfa, price_usd, created_by, updated_by)
  values
    (v_code, p_buyer_name, p_buyer_phone, p_buyer_country,
     p_price_mru, p_price_cfa, p_price_usd, auth.uid(), auth.uid())
  returning * into v_row;

  return v_row;
end;
$$;

-- Libère un code (remplace /ventes/reinitialiseUsedByCode/{code}).
-- L'ancien appareil sera désactivé à sa prochaine vérification.
create or replace function public.reset_code(p_code text)
returns public.activation_codes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.activation_codes;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  update public.activation_codes
     set is_used = false, device_id = null, activated_at = null
   where code = btrim(p_code)
  returning * into v_row;

  if v_row.id is null then
    raise exception 'code_not_found' using errcode = 'P0002';
  end if;

  return v_row;
end;
$$;

-- ---------------------------------------------------------------------------
-- Droits d'exécution
-- ---------------------------------------------------------------------------

revoke execute on all functions in schema public from public, anon, authenticated;

grant execute on function public.activate_code(text, text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.check_device(text)                                       to anon, authenticated;
grant execute on function public.is_admin()                                               to authenticated;
grant execute on function public.create_sale(text, text, text, numeric, numeric, numeric) to authenticated;
grant execute on function public.reset_code(text)                                         to authenticated;
