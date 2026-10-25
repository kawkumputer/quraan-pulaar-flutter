#!/usr/bin/env python3
"""
Importe le texte du Coran dans Supabase (tables quran_surahs / quran_verses, migration 004).

Sources combinées :
  - structure + arabe : fichier local propre (6 236 versets, numérotation standard)
      D:/pulaar-projects/AI-Pulaar/data/coran/coran_ar_pul.jsonl
  - traduction pulaar  : Firestore « sourates » (version la plus récente), associée par le
                          texte arabe ; repli sur le fichier local si aucune correspondance
  - métadonnées        : Firestore (noms, lien audio, juz)

Cas particuliers connus dans Firestore (traités ici) :
  53:20, 86:10  arabe doublé       -> arabe local, pulaar Firestore à la même position
  69:34         arabe/pulaar inversés -> pulaar pris dans le champ arabe
  42:28         « Hello World »    -> pulaar laissé vide (à traduire)

Usage :
  python import_quran.py            # simulation : rapport, rien n'est écrit
  python import_quran.py --commit   # écrit dans Supabase (upsert), puis vérifie
Variables : SUPABASE_DATABASE_URL dans .env (même dossier).
"""

import json
import re
import sys
from pathlib import Path

import psycopg
import requests

COMMIT = "--commit" in sys.argv
LOCAL = Path(r"D:/pulaar-projects/AI-Pulaar/data/coran/coran_ar_pul.jsonl")
FIRESTORE = ("https://firestore.googleapis.com/v1/projects/quran-pulaar-dmwdqo/databases/(default)"
             "/documents/sourates")
API_KEY = "AIzaSyBTkrQNZPlu_gj28CGwRd1eOOK-D8qFnxQ"  # clé publique de l'app Android

# Versets dont l'arabe Firestore est abîmé : pulaar repris tel quel dans Firestore.
FIRESTORE_PULAAR_OVERRIDES = {
    (53, 20): ("pulaar", lambda ay: ay.get("pulaar")),
    (86, 10): ("pulaar", lambda ay: ay.get("pulaar")),
    (69, 34): ("arabe", lambda ay: ay.get("arabe")),   # champs inversés
}
TO_TRANSLATE = {(42, 28)}


def env(name):
    for line in Path(__file__).with_name(".env").read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            if k.strip() == name:
                return v.strip().strip('"').strip("'")
    sys.exit(f"{name} manquant dans .env")


def norm_ar(t: str) -> str:
    t = re.sub(r"[\u064B-\u065F\u0670\u06D6-\u06ED\u0640\u0610-\u061A\u08D3-\u08FF]", "", t)
    for a, b in (("ٱ", "ا"), ("أ", "ا"), ("إ", "ا"), ("آ", "ا"), ("ى", "ي"), ("ة", "ه"),
                 ("ؤ", "و"), ("ئ", "ي"), ("ء", ""), ("ۥ", ""), ("ۦ", "")):
        t = t.replace(a, b)
    return re.sub(r"[^\u0621-\u064A]", "", t)


def clean(text: str | None) -> str:
    """Espaces et retours à la ligne parasites."""
    return re.sub(r"\s+", " ", text or "").strip()


def fs_value(v):
    for t in ("stringValue", "integerValue", "doubleValue", "booleanValue"):
        if t in v:
            return v[t]
    if "mapValue" in v:
        return {k: fs_value(x) for k, x in v["mapValue"].get("fields", {}).items()}
    if "arrayValue" in v:
        return [fs_value(x) for x in v["arrayValue"].get("values", [])]
    return None


def fetch_firestore() -> dict[int, dict]:
    docs, token = [], None
    while True:
        params = {"pageSize": 50, "key": API_KEY, **({"pageToken": token} if token else {})}
        r = requests.get(FIRESTORE, params=params, timeout=60)
        r.raise_for_status()
        j = r.json()
        docs += j.get("documents", [])
        token = j.get("nextPageToken")
        if not token:
            break
    surahs = {}
    for d in docs:
        s = {k: fs_value(x) for k, x in d["fields"].items()}
        surahs[int(s["suratNumber"])] = s
    return surahs


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    local = [json.loads(l) for l in LOCAL.read_text(encoding="utf-8").splitlines() if l.strip()]
    fs = fetch_firestore()
    assert len(local) == 6236 and len(fs) == 114, (len(local), len(fs))

    surahs, verses, report = [], [], {"firestore": 0, "local": 0, "override": 0, "a_traduire": []}
    by_surah: dict[int, list] = {}
    for r in local:
        by_surah.setdefault(r["surah"], []).append(r)

    for n in range(1, 115):
        doc = fs[n]
        ayats = doc.get("ayats") or []
        fs_by_ar = {}
        for a in ayats:
            fs_by_ar.setdefault(norm_ar(a.get("arabe") or ""), a)
        rows = sorted(by_surah[n], key=lambda r: r["ayah"])
        surahs.append({
            "number": n,
            "name_arabic": clean(doc.get("arabeTitle")),
            "name_pulaar": clean(doc.get("pulaarTitle")),
            "audio_url": doc.get("sourateUrl") or None,
            "juz": int(doc["juzzNumber"]) if doc.get("juzzNumber") not in (None, "") else None,
            "verses_count": len(rows),
        })
        for r in rows:
            key = (n, r["ayah"])
            if key in TO_TRANSLATE:
                pulaar = ""
                report["a_traduire"].append(f"{n}:{r['ayah']}")
            elif key in FIRESTORE_PULAAR_OVERRIDES:
                # même position dans Firestore (numéro identique)
                ay = next(a for a in ayats if int(a.get("number", 0)) == r["ayah"])
                pulaar = clean(FIRESTORE_PULAAR_OVERRIDES[key][1](ay))
                report["override"] += 1
            elif norm_ar(r["ar"]) in fs_by_ar:
                pulaar = clean(fs_by_ar[norm_ar(r["ar"])].get("pulaar"))
                report["firestore"] += 1
            else:
                pulaar = clean(r["pul"])
                report["local"] += 1
            verses.append({"surah_number": n, "number": r["ayah"], "arabic": r["ar"].strip(), "pulaar": pulaar})

    print(f"Sourates : {len(surahs)} ; versets : {len(verses)}")
    print(f"Pulaar : {report['firestore']} depuis Firestore, {report['override']} cas particuliers, "
          f"{report['local']} depuis le fichier local ; à traduire : {report['a_traduire']}")
    print("Sans audio :", [s["number"] for s in surahs if not s["audio_url"]] or "aucune")

    if not COMMIT:
        print("Simulation : rien n'a été écrit. Relancer avec --commit.")
        return

    with psycopg.connect(env("SUPABASE_DATABASE_URL")) as c:
        with c.cursor() as cur:
            cur.executemany(
                """insert into public.quran_surahs (number, name_arabic, name_pulaar, audio_url, juz, verses_count)
                   values (%(number)s, %(name_arabic)s, %(name_pulaar)s, %(audio_url)s, %(juz)s, %(verses_count)s)
                   on conflict (number) do update set name_arabic = excluded.name_arabic,
                     name_pulaar = excluded.name_pulaar, audio_url = excluded.audio_url,
                     juz = excluded.juz, verses_count = excluded.verses_count, updated_at = now()""",
                surahs,
            )
            # Ne remplace pas une traduction déjà corrigée dans Supabase (updated_by renseigné).
            cur.executemany(
                """insert into public.quran_verses (surah_number, number, arabic, pulaar)
                   values (%(surah_number)s, %(number)s, %(arabic)s, %(pulaar)s)
                   on conflict (surah_number, number) do update set arabic = excluded.arabic,
                     pulaar = case when public.quran_verses.updated_by is null then excluded.pulaar
                                   else public.quran_verses.pulaar end""",
                verses,
            )
        c.commit()

        # Vérification : comptes et contenu verset par verset.
        db = {(s, n): (ar, ff) for s, n, ar, ff in
              c.execute("select surah_number, number, arabic, pulaar from public.quran_verses").fetchall()}
        mismatch = sum(1 for v in verses if db.get((v["surah_number"], v["number"])) != (v["arabic"], v["pulaar"]))
        n_surahs = c.execute("select count(*) from public.quran_surahs").fetchone()[0]
        print(f"Vérification : {n_surahs} sourates, {len(db)} versets en base, {mismatch} écart(s) avec l'import.")
    print("Import terminé.")


if __name__ == "__main__":
    main()
