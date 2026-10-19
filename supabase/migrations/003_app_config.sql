-- Quraan Pulaar - 003 : version minimale / dernière version par plateforme
--
-- L'app lit cette config au démarrage :
--   version installée < min_version    -> écran bloquant « mettre à jour »
--   version installée < latest_version -> proposition (au plus une fois par semaine)
-- Modifier les valeurs depuis le Table Editor (table app_config).

create table if not exists public.app_config (
  platform        text primary key check (platform in ('android', 'ios')),
  min_version     text not null,
  latest_version  text,
  store_url       text,
  message         text,               -- message facultatif affiché dans le dialogue
  updated_at      timestamptz not null default now()
);

alter table public.app_config enable row level security;
revoke all on public.app_config from anon;

create policy "admins_all_app_config" on public.app_config
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

insert into public.app_config (platform, min_version, latest_version, store_url) values
  ('android', '2.10.0', '2.10.0', 'https://play.google.com/store/apps/details?id=mr.quran_pulaar'),
  ('ios',     '2.10.0', '2.10.0', 'https://apps.apple.com/app/id6742410170')
on conflict (platform) do nothing;

create or replace function public.get_app_config(p_platform text)
returns json
language sql
stable
security definer
set search_path = ''
as $$
  select json_build_object(
           'min_version',    c.min_version,
           'latest_version', c.latest_version,
           'store_url',      c.store_url,
           'message',        c.message)
    from public.app_config c
   where c.platform = p_platform;
$$;

revoke execute on function public.get_app_config(text) from public;
grant  execute on function public.get_app_config(text) to anon, authenticated;
