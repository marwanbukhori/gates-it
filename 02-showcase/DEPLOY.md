# Deploying Pawmise

Two pieces, split so the always-on front-end costs nothing:

| Piece | Host | Cost |
|-------|------|------|
| Flutter web app | Cloudflare Pages / GitHub Pages | Free (static) |
| Laravel API + MySQL | Railway | ~$5 trial credit, then $5/mo Hobby |

Source of truth: **GitHub `marwanbukhori/gates-it`** (public).

---

## 1. Backend — Railway (from the marwanbukhori GitHub repo)

The service **root directory** must be `02-showcase/laravel` (monorepo). Railway
builds the `Dockerfile` there (single web process; migrations + idempotent seed
run on boot).

### One-time: authenticate Railway as the marwanbukhori account
```bash
railway login          # opens a browser — log in with the GitHub acc you want to own this
railway whoami         # confirm it's the intended account (NOT a shared/company one)
```

### Provision + deploy
```bash
cd 02-showcase/laravel

# Create the project (links this dir to it)
railway init --name pawmise-api

# Add a MySQL database service
railway add --database mysql

# App env — Laravel needs an APP_KEY; point DB at the Railway MySQL service
railway variables --set "APP_KEY=$(php artisan key:generate --show)"
railway variables --set "APP_ENV=production"
railway variables --set "APP_DEBUG=false"
railway variables --set "DB_CONNECTION=mysql"
railway variables --set 'DB_URL=${{MySQL.MYSQL_URL}}'      # reference the MySQL service

# Deploy this directory
railway up --ci

# Give it a public URL
railway domain
```

Set `APP_URL` to the printed domain (`railway variables --set "APP_URL=https://<your>.up.railway.app"`).

### Verify
```bash
curl https://<your>.up.railway.app/api/v1/pets    # should return seeded pets
```

**Alternative (deploy from GitHub, auto-redeploy on push):** in the Railway
dashboard → New → Deploy from GitHub repo → `marwanbukhori/gates-it` → set the
service **Root Directory** to `02-showcase/laravel`. Requires installing the
Railway GitHub app on the marwanbukhori account (one-time OAuth).

---

## 2. Frontend — Flutter web (free)

```bash
cd 02-showcase/flutter
flutter build web --release --dart-define=API_BASE_URL=https://<your>.up.railway.app/api/v1
```

Deploy `build/web/` to **Cloudflare Pages** (or GitHub Pages / Netlify) — a static
upload, free, no cold starts. Point it at the Railway API via the
`--dart-define` above.

---

## Notes / follow-ups
- `artisan serve` is used for simplicity; for real production traffic swap the
  Dockerfile CMD for FrankenPHP or php-fpm + nginx.
- **CORS:** the browser (Flutter web) calls the API cross-origin. Confirm
  `config/cors.php` (or the `HandleCors` middleware) allows the Pages origin for
  `api/*` before the hosted demo will work end-to-end.
- The seed is idempotent (`DatabaseSeeder` guards on existing pets), so redeploys
  won't duplicate data.
