-- Quraan Pulaar - 002 : validation par code + rattachement des anciens codes
--
-- Pourquoi : jusqu'en 2.9.x l'app Android envoyait Build.ID (version du firmware,
-- partagée par des dizaines de téléphones et modifiée à chaque mise à jour)
-- comme identifiant d'appareil. À partir de 2.10.0 elle envoie ANDROID_ID.
--
--   * Les codes migrés depuis Spring n'ont pas d'appareil (device_id null).
--     Ils se rattachent au premier appareil qui présente le code
--     (activate_code ou check_device).
--   * check_device reçoit le code : un code reste valide tant qu'il est utilisé
--     et rattaché à cet appareil. Réinitialisation admin => invalide.
--   * check_device est soumis au même anti force brute que activate_code.
--
-- À exécuter une fois dans le SQL Editor, après 001_init.sql.

alter table public.activation_codes
  add column if not exists legacy_device_model text,   -- modèle (Spring), pour l'affichage admin
  add column if not exists legacy_device_uid   text;   -- Build.ID envoyé par l'ancienne app (info seulement)

-- ---------------------------------------------------------------------------
-- Helpers internes
-- ---------------------------------------------------------------------------

create or replace function public._too_many_failures(p_unique_id text, p_ip text)
returns boolean
language sql
stable
set search_path = ''
as $$
  select (select count(*) from public.activation_attempts
           where unique_id = p_unique_id and not success
             and attempted_at > now() - interval '1 hour') >= 5
      or (p_ip is not null and (select count(*) from public.activation_attempts
           where ip = p_ip and not success
             and attempted_at > now() - interval '1 hour') >= 20);
$$;

-- Crée / met à jour l'appareil et renvoie son id.
create or replace function public._upsert_device(
  p_unique_id          text,
  p_base_os            text,
  p_device_name        text,
  p_device_model       text,
  p_manufacturer       text,
  p_first_install_time text
)
returns bigint
language plpgsql
set search_path = ''
as $$
declare
  v_id bigint;
begin
  insert into public.devices (unique_id, base_os, device_name, device_model,
                              manufacturer, first_install_time)
  values (p_unique_id, p_base_os, p_device_name, p_device_model,
          p_manufacturer, p_first_install_time)
  on conflict (unique_id) do update
     set base_os            = coalesce(excluded.base_os,            public.devices.base_os),
         device_name        = coalesce(excluded.device_name,        public.devices.device_name),
         device_model       = coalesce(excluded.device_model,       public.devices.device_model),
         manufacturer       = coalesce(excluded.manufacturer,       public.devices.manufacturer),
         first_install_time = coalesce(excluded.first_install_time, public.devices.first_install_time),
         last_seen_at       = now()
  returning id into v_id;
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- activate_code : un code utilisé SANS appareil (ancien code) peut être rattaché
-- ---------------------------------------------------------------------------

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

  if public._too_many_failures(v_uid, v_ip) then
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

  -- Code déjà rattaché à un AUTRE appareil.
  if v_code.device_id is not null
     and not exists (select 1 from public.devices d
                      where d.id = v_code.device_id and d.unique_id = v_uid) then
    insert into public.activation_attempts(unique_id, ip, success) values (v_uid, v_ip, false);
    return json_build_object('success', false, 'error', 'code_already_used');
  end if;

  -- Code libre, ancien code sans appareil, ou réinstallation sur le même appareil.
  v_device_id := public._upsert_device(v_uid, p_base_os, p_device_name, p_device_model,
                                       p_manufacturer, p_first_install_time);

  update public.activation_codes
     set is_used      = true,
         device_id    = v_device_id,
         activated_at = coalesce(activated_at, now())
   where id = v_code.id;

  insert into public.activation_attempts(unique_id, ip, success) values (v_uid, v_ip, true);
  return json_build_object('success', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- check_device : validation par code
--   'valid'   : code utilisé et rattaché à cet appareil (rattachement auto si ancien code)
--   'invalid' : code inconnu, réinitialisé, ou rattaché à un autre appareil
--   'unknown' : pas de code fourni -> l'app garde son activation locale
-- ---------------------------------------------------------------------------

drop function if exists public.check_device(text);

create or replace function public.check_device(p_unique_id text, p_code text default null)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code      public.activation_codes%rowtype;
  v_ip        text := public._client_ip();
  v_uid       text := btrim(p_unique_id);
  v_code_text text := btrim(p_code);
  v_device_id bigint;
begin
  if v_uid is null or v_uid = '' or v_code_text is null or v_code_text = '' then
    return 'unknown';
  end if;

  if public._too_many_failures(v_uid, v_ip) then
    return 'unknown';
  end if;

  select * into v_code
    from public.activation_codes
   where code = v_code_text
   for update;

  if not found or not v_code.is_used then
    insert into public.activation_attempts(unique_id, ip, success) values (v_uid, v_ip, false);
    return 'invalid';
  end if;

  if v_code.device_id is null then
    -- Ancien code (migré depuis Spring) : rattachement à cet appareil.
    v_device_id := public._upsert_device(v_uid, null, null, null, null, null);
    update public.activation_codes set device_id = v_device_id where id = v_code.id;
    return 'valid';
  end if;

  if exists (select 1 from public.devices d
              where d.id = v_code.device_id and d.unique_id = v_uid) then
    update public.devices set last_seen_at = now() where id = v_code.device_id;
    return 'valid';
  end if;

  insert into public.activation_attempts(unique_id, ip, success) values (v_uid, v_ip, false);
  return 'invalid';
end;
$$;

-- ---------------------------------------------------------------------------
-- Droits
-- ---------------------------------------------------------------------------

revoke execute on function public._too_many_failures(text, text)                    from public, anon, authenticated;
revoke execute on function public._upsert_device(text, text, text, text, text, text) from public, anon, authenticated;
revoke execute on function public.check_device(text, text)                           from public;
grant  execute on function public.check_device(text, text)                           to anon, authenticated;
