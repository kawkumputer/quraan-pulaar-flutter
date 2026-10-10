# Supabase – activation par code

Remplace le backend Spring (`quran-backend`, DigitalOcean). Le contenu (sourates, hadiths, audio) reste sur Firebase.

## Mise en place

1. **Créer le projet** sur supabase.com (région proche des utilisateurs, ex. `eu-west`).
2. **Schéma** : SQL Editor → exécuter `migrations/001_init.sql` puis `migrations/002_code_based_validation.sql`.
3. **Désactiver les inscriptions** : Authentication → Sign In / Providers → *Allow new users to sign up* = OFF.
4. **Vérifier la sécurité** : SQL Editor → exécuter `tests/verify_security.sql` (tout est annulé à la fin). Un seul tableau : toutes les lignes doivent être `OK`.
5. **Admins** : Authentication → Users → *Add user* (email + mot de passe), puis :
   ```sql
   insert into public.app_admins (user_id)
   select id from auth.users where email = 'admin@exemple.com';
   ```
6. **Données** (depuis le Postgres DigitalOcean, après un `pg_dump` de sauvegarde) :
   ```bash
   # Tunnel SSH vers le Postgres DigitalOcean (laisser ouvert, forcer l'IPv4) :
   ssh -N -L 127.0.0.1:5442:127.0.0.1:5442 root@146.190.150.139

   # Dans un autre terminal (PowerShell : $env:NOM = '...') :
   cd supabase/scripts
   pip install -r requirements.txt
   export OLD_DATABASE_URL='postgresql://postgres:<MDP_DO>@127.0.0.1:5442/quran_db'
   export SUPABASE_DATABASE_URL='postgresql://postgres.aruetqtlcdoabgukpjcz:<MDP_SUPABASE>@aws-1-eu-central-1.pooler.supabase.com:5432/postgres'
   python migrate_from_spring.py            # simulation
   python migrate_from_spring.py --commit   # écriture
   ```
   Ne jamais écrire les mots de passe dans ce fichier. Caractères spéciaux à encoder dans l'URL (`@` → `%40`).
   Relançable sans risque pour la synchro finale.
7. **App** : renseigner l'URL et la clé *publishable* dans `lib/core/config/supabase_config.dart`.

## API

| Appelant | RPC | Rôle |
|---|---|---|
| App (anon) | `activate_code(p_code, p_unique_id, …)` | `{success, error}` — erreurs : `invalid_request`, `too_many_attempts`, `invalid_code`, `code_already_used` |
| App (anon) | `check_device(p_unique_id)` | `'valid'` / `'invalid'` |
| Admin | `create_sale(p_buyer_name, p_buyer_phone, p_buyer_country, p_price_mru, p_price_cfa, p_price_usd)` | crée une vente avec un code à 10 chiffres |
| Admin | `reset_code(p_code)` | libère un code (l'ancien appareil sera désactivé) |
| Admin | `select` / `update` sur `activation_codes`, `devices` | listes, recherche par téléphone, etc. |

Correspondance avec l'ancien backend pour l'app admin :

| Spring | Supabase |
|---|---|
| `POST /token` | `supabase.auth.signInWithPassword(email, password)` |
| `POST /ventes` | `rpc('create_sale', …)` (création) / `from('activation_codes').update(…)` (modification) |
| `GET /ventes` | `from('activation_codes').select('*, devices(*)')` |
| `GET /ventes/{code}` | `…select().eq('code', code)` |
| `GET /ventes/byPhoneNumber/{p}` | `…select().eq('buyer_phone', p)` |
| `GET /ventes/reinitialiseUsedByCode/{code}` | `rpc('reset_code', {'p_code': code})` |
| `GET /codes/generateCode`, `POST /codes` | inutiles : `create_sale` génère le code |
