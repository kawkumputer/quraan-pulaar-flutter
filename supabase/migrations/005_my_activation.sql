-- Quraan Pulaar - 005 : écran « Mon activation » de l'app.
-- Renvoie l'état d'activation de CET appareil, uniquement si le code est rattaché à lui.
-- Aucune donnée personnelle de l'acheteur (nom, téléphone) n'est renvoyée.

create or replace function public.my_activation(p_unique_id text, p_code text)
returns json
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select json_build_object(
              'activated', true,
              'activated_at', c.activated_at,
              'device_model', nullif(btrim(concat_ws(' ', d.manufacturer, d.device_model)), ''))
       from public.activation_codes c
       join public.devices d on d.id = c.device_id
      where c.code = btrim(p_code)
        and c.is_used
        and d.unique_id = btrim(p_unique_id)
      limit 1),
    json_build_object('activated', false)
  );
$$;

revoke execute on function public.my_activation(text, text) from public;
grant execute on function public.my_activation(text, text) to anon, authenticated;
