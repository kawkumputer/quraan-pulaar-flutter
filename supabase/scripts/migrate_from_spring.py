#!/usr/bin/env python3
"""
Copie les ventes / codes du Postgres Spring (DigitalOcean) vers Supabase.

Les appareils ne sont PAS recopiés : l'ancienne app envoyait Build.ID
(version du firmware, partagée par de nombreux téléphones) au lieu d'un vrai
identifiant. Les codes utilisés sont migrés sans appareil (device_id null) et
se rattachent au vrai appareil au premier lancement de l'app 2.10+
(voir supabase/migrations/002_code_based_validation.sql).

Idempotent : peut être relancé autant de fois que nécessaire (synchro finale
au moment de la bascule). Ne « dé-active » jamais un code côté Supabase.

Variables d'environnement (jamais de secrets dans ce fichier) :
  OLD_DATABASE_URL       postgresql://postgres:***@127.0.0.1:5442/quran_db (via tunnel SSH)
  SUPABASE_DATABASE_URL  chaîne « Session pooler » (Dashboard > Connect), rôle postgres

Usage :
  pip install -r requirements.txt
  python migrate_from_spring.py            # simulation (rollback)
  python migrate_from_spring.py --commit   # écrit réellement
"""

import os
import sys

import psycopg
from psycopg.rows import dict_row

OLD_QUERY = """
select v.id               as vente_id,
       v.name, v.phone, v.country,
       v.mru_price, v.cfa_price, v.dollar_price,
       v.created_date, v.updated_date, v.is_used,
       c.code,
       u.username         as seller,
       d.device_model, d.unique_id
  from vente v
  left join code c              on c.id = v.code_id
  left join device_info_model d on d.id = v.device_info_model_id
  left join app_user u          on u.id = v.created_by_id
 order by v.id
"""

UPSERT_CODE = """
insert into public.activation_codes
  (code, is_used, buyer_name, buyer_phone, buyer_country,
   price_mru, price_cfa, price_usd, activated_at, created_at,
   legacy_id, legacy_seller, legacy_device_model, legacy_device_uid)
values (%s, %s, %s, %s, %s, %s, %s, %s, %s, coalesce(%s, now()), %s, %s, %s, %s)
on conflict (code) do update
   set buyer_name          = excluded.buyer_name,
       buyer_phone         = excluded.buyer_phone,
       buyer_country       = excluded.buyer_country,
       price_mru           = excluded.price_mru,
       price_cfa           = excluded.price_cfa,
       price_usd           = excluded.price_usd,
       legacy_id           = excluded.legacy_id,
       legacy_seller       = excluded.legacy_seller,
       legacy_device_model = excluded.legacy_device_model,
       legacy_device_uid   = excluded.legacy_device_uid,
       -- Code rattaché à un appareil (client passé en 2.10+) : Supabase fait foi,
       -- on ne le désactive jamais. Sinon on suit Spring (activation ou
       -- réinitialisation faite dans l'ancienne app admin).
       is_used             = case when public.activation_codes.device_id is not null
                                  then true else excluded.is_used end,
       activated_at        = case when public.activation_codes.device_id is not null
                                  then public.activation_codes.activated_at
                                  else excluded.activated_at end
"""


def env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        sys.exit(f"Variable d'environnement manquante : {name}")
    return value


def pick_one_per_code(rows):
    """Plusieurs ventes peuvent partager un code (bug de Spring).
    On garde la vente utilisée avec appareil, sinon utilisée, sinon la plus ancienne."""
    by_code = {}
    for r in rows:
        if r["code"] is None:
            continue
        by_code.setdefault(str(r["code"]), []).append(r)

    kept, dropped = [], []
    for code, group in by_code.items():
        group.sort(key=lambda r: (not r["is_used"], r["unique_id"] is None, r["vente_id"]))
        kept.append(group[0])
        dropped.extend((code, r) for r in group[1:])
    return kept, dropped


def main() -> None:
    commit = "--commit" in sys.argv

    with psycopg.connect(env("OLD_DATABASE_URL"), row_factory=dict_row) as old, \
         psycopg.connect(env("SUPABASE_DATABASE_URL")) as new:

        rows = old.execute(OLD_QUERY).fetchall()
        no_code = [r["vente_id"] for r in rows if r["code"] is None]
        kept, dropped = pick_one_per_code(rows)
        expected_used = sum(1 for r in kept if r["is_used"])

        print(f"Spring : {len(rows)} ventes, {sum(1 for r in rows if r['is_used'])} utilisées")
        for vente_id in no_code:
            print(f"  ! vente {vente_id} sans code : ignorée")
        for code, r in dropped:
            print(f"  ! code {code} partagé : vente {r['vente_id']} "
                  f"({'utilisée' if r['is_used'] else 'non utilisée'}) non migrée, "
                  f"on garde la vente {next(k['vente_id'] for k in kept if str(k['code']) == code)}")

        with new.cursor() as cur:
            for r in kept:
                is_used = bool(r["is_used"])
                cur.execute(UPSERT_CODE, (
                    str(r["code"]), is_used, r["name"], r["phone"], r["country"],
                    r["mru_price"], r["cfa_price"], r["dollar_price"],
                    (r["updated_date"] or r["created_date"]) if is_used else None,
                    r["created_date"], r["vente_id"], r["seller"],
                    r["device_model"], r["unique_id"],
                ))

            total, used = cur.execute(
                "select count(*), count(*) filter (where is_used) "
                "from public.activation_codes where legacy_id is not null"
            ).fetchone()

        print(f"Supabase : {total} codes migrés ({used} utilisés) ; attendu {len(kept)} ({expected_used} utilisés)")
        if (total, used) != (len(kept), expected_used):
            print("  ! Écart : vérifier avant --commit "
                  "(des codes ont pu être activés entre-temps côté Supabase).")

        if commit:
            new.commit()
            print("Écriture validée (COMMIT).")
        else:
            new.rollback()
            print("Simulation : rien n'a été écrit. Relancer avec --commit.")


if __name__ == "__main__":
    main()
