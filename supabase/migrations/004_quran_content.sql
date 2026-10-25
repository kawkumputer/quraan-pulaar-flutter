-- Quraan Pulaar - 004 : texte du Coran dans Supabase (remplace la collection Firestore « sourates »)
--
--  * quran_surahs / quran_verses : 114 sourates, 6 236 versets (arabe + traduction pulaar).
--  * Seule la traduction pulaar est modifiable (droits par colonne) ; chaque modification
--    est historisée dans quran_verse_history (retour arrière possible).
--  * Aucun accès direct pour anon : l'app passe par quran_sync(), qui ne renvoie le contenu
--    payant qu'aux appareils activés (code utilisé ET rattaché à cet appareil).
--  * Admins (app_admins) : lecture et correction du pulaar.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.quran_surahs (
  number       int primary key check (number between 1 and 114),
  name_arabic  text not null,
  name_pulaar  text not null,
  audio_url    text,
  juz          int,
  verses_count int not null,
  updated_at   timestamptz not null default now()
);

create table if not exists public.quran_verses (
  surah_number int not null references public.quran_surahs(number) on delete cascade,
  number       int not null check (number > 0),
  arabic       text not null,
  pulaar       text not null default '',
  updated_at   timestamptz not null default now(),
  updated_by   uuid references auth.users(id) on delete set null,
  primary key (surah_number, number)
);

create index if not exists quran_verses_updated_at_idx on public.quran_verses (updated_at);

create table if not exists public.quran_verse_history (
  id           bigint generated always as identity primary key,
  surah_number int not null,
  verse_number int not null,
  old_pulaar   text,
  new_pulaar   text,
  changed_at   timestamptz not null default now(),
  changed_by   uuid references auth.users(id) on delete set null
);

create index if not exists quran_verse_history_verse_idx
  on public.quran_verse_history (surah_number, verse_number, changed_at desc);

-- ---------------------------------------------------------------------------
-- Correction : date, auteur et historique ; arabe intouchable depuis l'app / le site
-- ---------------------------------------------------------------------------

create or replace function public.tg_quran_verse_changed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Les utilisateurs connectés (admins) ne peuvent pas modifier l'arabe.
  -- Les scripts de maintenance (rôle postgres, sans auth.uid()) le peuvent.
  if new.arabic is distinct from old.arabic and auth.uid() is not null then
    raise exception 'Le texte arabe ne peut pas être modifié.' using errcode = '42501';
  end if;

  if new.pulaar is distinct from old.pulaar then
    new.updated_at := now();
    new.updated_by := auth.uid();
    insert into public.quran_verse_history (surah_number, verse_number, old_pulaar, new_pulaar, changed_by)
    values (old.surah_number, old.number, old.pulaar, new.pulaar, auth.uid());
  elsif new.arabic is distinct from old.arabic then
    new.updated_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists quran_verse_changed on public.quran_verses;
create trigger quran_verse_changed before update on public.quran_verses
  for each row execute function public.tg_quran_verse_changed();

-- ---------------------------------------------------------------------------
-- Droits
-- ---------------------------------------------------------------------------

alter table public.quran_surahs        enable row level security;
alter table public.quran_verses        enable row level security;
alter table public.quran_verse_history enable row level security;

revoke all on public.quran_surahs, public.quran_verses, public.quran_verse_history from anon, authenticated;

grant select on public.quran_surahs, public.quran_verses, public.quran_verse_history to authenticated;
grant update (pulaar) on public.quran_verses to authenticated;   -- seule colonne modifiable

drop policy if exists "admins_read" on public.quran_surahs;
create policy "admins_read" on public.quran_surahs for select to authenticated using (public.is_admin());

drop policy if exists "admins_read" on public.quran_verses;
create policy "admins_read" on public.quran_verses for select to authenticated using (public.is_admin());

drop policy if exists "admins_correct" on public.quran_verses;
create policy "admins_correct" on public.quran_verses for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins_read" on public.quran_verse_history;
create policy "admins_read" on public.quran_verse_history for select to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------------
-- Synchronisation de l'app
-- ---------------------------------------------------------------------------
-- p_since null : tout le contenu accessible ; sinon seulement ce qui a changé depuis.
-- L'app doit repartir de null quand son état d'activation change (champ « activated »).
-- Réponse : { server_time, activated, surahs: [...], verses: [{s, n, ar, ff}] }

create or replace function public.quran_sync(
  p_unique_id text default null,
  p_code      text default null,
  p_since     timestamptz default null
)
returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_activated boolean;
  v_free int[] := array[1, 112, 113, 114];
begin
  -- Activé = code utilisé ET déjà rattaché à cet appareil (pas d'oracle sur les codes).
  v_activated := p_code is not null and p_unique_id is not null and exists (
    select 1
      from public.activation_codes c
      join public.devices d on d.id = c.device_id
     where c.code = btrim(p_code)
       and c.is_used
       and d.unique_id = btrim(p_unique_id)
  );

  return json_build_object(
    'server_time', now(),
    'activated', v_activated,
    'surahs', coalesce((
      select json_agg(json_build_object(
               'number', s.number, 'name_arabic', s.name_arabic, 'name_pulaar', s.name_pulaar,
               'audio_url', s.audio_url, 'juz', s.juz, 'verses_count', s.verses_count)
             order by s.number)
        from public.quran_surahs s
       where (v_activated or s.number = any (v_free))
         and (p_since is null or s.updated_at > p_since)
    ), '[]'::json),
    'verses', coalesce((
      select json_agg(json_build_object('s', v.surah_number, 'n', v.number, 'ar', v.arabic, 'ff', v.pulaar)
             order by v.surah_number, v.number)
        from public.quran_verses v
       where (v_activated or v.surah_number = any (v_free))
         and (p_since is null or v.updated_at > p_since)
    ), '[]'::json)
  );
end;
$$;

revoke execute on function public.quran_sync(text, text, timestamptz) from public;
grant execute on function public.quran_sync(text, text, timestamptz) to anon, authenticated;
