-- Vérifications à lancer dans le SQL Editor APRÈS 001_init.sql et 002_code_based_validation.sql.
-- Renvoie un seul tableau : chaque ligne doit avoir statut = OK.
-- Tout s'exécute dans une transaction annulée : aucune donnée ne reste.

begin;

insert into public.activation_codes (code) values ('TEST000001'), ('TEST000002');
-- Ancien code migré depuis Spring : utilisé, sans appareil.
insert into public.activation_codes (code, is_used) values ('LEGACY0001', true), ('LEGACY0002', true);

create temp table _results (
  ordre   serial,
  test    text,
  attendu text,
  obtenu  text
) on commit drop;

do $$
declare
  t text[] := '{}';
  a text[] := '{}';
  o text[] := '{}';
  v text;
  i int;
begin
  set local role anon;

  -- 1. anon n'a aucun accès direct
  begin
    perform 1 from public.activation_codes;  v := 'autorisé';
  exception when insufficient_privilege then v := 'refusé'; end;
  t := array_append(t, 'anon lit activation_codes'); a := array_append(a, 'refusé'); o := array_append(o, v);

  begin
    perform 1 from public.devices;  v := 'autorisé';
  exception when insufficient_privilege then v := 'refusé'; end;
  t := array_append(t, 'anon lit devices'); a := array_append(a, 'refusé'); o := array_append(o, v);

  begin
    update public.activation_codes set is_used = true;  v := 'autorisé';
  exception when insufficient_privilege then v := 'refusé'; end;
  t := array_append(t, 'anon modifie activation_codes'); a := array_append(a, 'refusé'); o := array_append(o, v);

  begin
    perform public.reset_code('TEST000002');  v := 'autorisé';
  exception when insufficient_privilege then v := 'refusé'; end;
  t := array_append(t, 'anon appelle reset_code'); a := array_append(a, 'refusé'); o := array_append(o, v);

  begin
    perform public.create_sale('x', 'x', 'x');  v := 'autorisé';
  exception when insufficient_privilege then v := 'refusé'; end;
  t := array_append(t, 'anon appelle create_sale'); a := array_append(a, 'refusé'); o := array_append(o, v);

  begin
    perform public._upsert_device('x', null, null, null, null, null);  v := 'autorisé';
  exception when insufficient_privilege then v := 'refusé'; end;
  t := array_append(t, 'anon appelle _upsert_device'); a := array_append(a, 'refusé'); o := array_append(o, v);

  -- 2. Activation d'un nouveau code
  v := coalesce(public.activate_code('TEST000001', 'dev-A') ->> 'error', 'success');
  t := array_append(t, 'code valide'); a := array_append(a, 'success'); o := array_append(o, v);

  v := coalesce(public.activate_code('TEST000001', 'dev-A') ->> 'error', 'success');
  t := array_append(t, 'même appareil (réinstallation)'); a := array_append(a, 'success'); o := array_append(o, v);

  v := coalesce(public.activate_code('TEST000001', 'dev-B') ->> 'error', 'success');
  t := array_append(t, 'code pris par un autre appareil'); a := array_append(a, 'code_already_used'); o := array_append(o, v);

  v := coalesce(public.activate_code('9999999999', 'dev-C') ->> 'error', 'success');
  t := array_append(t, 'code inexistant'); a := array_append(a, 'invalid_code'); o := array_append(o, v);

  -- 3. Validation par code
  t := array_append(t, 'check dev-A + son code');      a := array_append(a, 'valid');   o := array_append(o, public.check_device('dev-A', 'TEST000001'));
  t := array_append(t, 'check dev-B + code de dev-A'); a := array_append(a, 'invalid'); o := array_append(o, public.check_device('dev-B', 'TEST000001'));
  t := array_append(t, 'check code non activé');       a := array_append(a, 'invalid'); o := array_append(o, public.check_device('dev-A', 'TEST000002'));
  t := array_append(t, 'check sans code');             a := array_append(a, 'unknown'); o := array_append(o, public.check_device('dev-A'));

  -- 4. Anciens codes Spring (utilisés, sans appareil)
  t := array_append(t, 'ancien code : 1er check rattache'); a := array_append(a, 'valid');   o := array_append(o, public.check_device('dev-L1', 'LEGACY0001'));
  t := array_append(t, 'ancien code : autre appareil');     a := array_append(a, 'invalid'); o := array_append(o, public.check_device('dev-X', 'LEGACY0001'));

  v := coalesce(public.activate_code('LEGACY0002', 'dev-L2') ->> 'error', 'success');
  t := array_append(t, 'ancien code : activation rattache'); a := array_append(a, 'success'); o := array_append(o, v);

  v := coalesce(public.activate_code('LEGACY0002', 'dev-Y') ->> 'error', 'success');
  t := array_append(t, 'ancien code : 2e appareil refusé'); a := array_append(a, 'code_already_used'); o := array_append(o, v);

  -- 5. Anti force brute : 5 échecs puis blocage (activation et vérification)
  for i in 1..5 loop
    perform public.activate_code('000000000' || i, 'dev-brute');
  end loop;
  v := coalesce(public.activate_code('0000000006', 'dev-brute') ->> 'error', 'success');
  t := array_append(t, '6e activation échouée'); a := array_append(a, 'too_many_attempts'); o := array_append(o, v);

  t := array_append(t, 'check bloqué après 5 échecs'); a := array_append(a, 'unknown'); o := array_append(o, public.check_device('dev-brute', 'LEGACY0001'));

  reset role;

  insert into _results (test, attendu, obtenu)
  select t[k], a[k], o[k] from generate_subscripts(t, 1) k order by k;
end $$;

select ordre, test, attendu, obtenu,
       case when attendu = obtenu then 'OK' else 'ECHEC' end as statut
  from _results
 order by (attendu = obtenu), ordre;   -- les ECHEC en premier

rollback;
