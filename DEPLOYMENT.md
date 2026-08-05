# Deploying to erp.zeracreative.com (cPanel)

## Architecture

- **Backend** (NestJS): runs as a cPanel "Node.js App" (Phusion Passenger),
  reachable at `erp.zeracreative.com/api`. Same-origin as the frontend, so no
  CORS configuration is needed and no extra subdomain/SSL cert is required.
- **Frontend** (Flutter Web): built locally into static files and uploaded to
  the subdomain's document root. cPanel shared hosting doesn't have the
  Flutter SDK, so the frontend is never built on the server — only the
  compiled `build/web` output is uploaded.
- **Database**: PostgreSQL via cPanel's "PostgreSQL Databases" tool.
- **Deploys**: cPanel's Git Version Control feature pulls this repo; a
  `.cpanel.yml` in the repo root then runs the backend build + migrations and
  restarts the app automatically. The frontend is a separate, manual upload
  step (see Step 6) since it isn't built on the server.

## One-time setup

### Step 1 — PostgreSQL database

cPanel → **PostgreSQL Databases**:
1. Create a database (e.g. `zeraerp` — cPanel will prefix it with your
   cPanel username, giving something like `youruser_zeraerp`).
2. Create a database user with a strong password.
3. Add the user to the database with **ALL PRIVILEGES**.
4. Note the final DB name, username, and password — you'll need them in
   Step 3. Host is almost always `localhost`, port `5432`.

### Step 2 — Git Version Control

cPanel → **Git Version Control** → **Create**:
- Clone URL: `https://github.com/noushadr/zera-erp.git`
- Repository Path: `repositories/Custom-ERP` (this doc assumes this path —
  if you pick something else, adjust `.cpanel.yml` accordingly)
- Branch: `main`

After creating it, open **Manage** for this repo — you'll use the
**Pull or Deploy** tab there for every future deploy.

### Step 3 — Node.js App

cPanel → **Setup Node.js App** → **Create Application**:
- Node.js version: latest available LTS (24.x or newer)
- Application mode: **Production**
- Application root: `repositories/Custom-ERP/backend`
- Application URL: `erp.zeracreative.com` with path `/api`
- Application startup file: `dist/main.js`
- Save.

On the resulting app page:
1. Copy the `source /home/.../nodevenv/.../bin/activate` command shown near
   the top — you'll paste it into `.cpanel.yml` in Step 4.
2. Under **Environment Variables**, add every key from
   [`backend/.env.production.example`](backend/.env.production.example)
   *except* `PORT` (Passenger assigns that itself — don't set it). Use the
   real DB credentials from Step 1. Generate the two JWT secrets with:
   ```bash
   openssl rand -hex 32
   ```
   Run it twice — `JWT_SECRET` and `JWT_REFRESH_SECRET` must be different
   values. Never reuse the `change_me_*` dev placeholders in production.
3. Click **Save**.

### Step 4 — Fill in `.cpanel.yml`

Edit the two lines at the top of [`.cpanel.yml`](.cpanel.yml):
```yaml
- export APP_ROOT=$HOME/repositories/Custom-ERP/backend
- export NODE_ENV_ACTIVATE=$HOME/nodevenv/repositories/Custom-ERP/backend/24/bin/activate
```
Replace the `NODE_ENV_ACTIVATE` line with the exact `source ...activate` path
cPanel showed you in Step 3 (the Node version segment, e.g. `24`, must match
what cPanel actually created). Commit and push this change — it only needs
doing once.

### Step 5 — First deploy (backend)

In cPanel Git Version Control → your repo → **Pull or Deploy** →
**Update from Remote**, then **Deploy HEAD Commit**. This runs
`.cpanel.yml`'s tasks: `npm ci`, `npm run build`, `npm run migration:run`,
then restarts the app. Watch the task output for errors.

Then, over SSH, run the one-time seed (creates default roles/permissions and
the super admin — safe to run only once):
```bash
source $HOME/nodevenv/repositories/Custom-ERP/backend/24/bin/activate
cd $HOME/repositories/Custom-ERP/backend
npm run seed
```

Confirm the API is up:
```bash
curl https://erp.zeracreative.com/api/employees
```
(a 401 Unauthorized is expected here — it means the app is running and
guarding routes correctly).

### Step 6 — Build & upload the frontend

On your local machine, from `frontend/`:
```bash
flutter build web --release --dart-define=API_BASE_URL=https://erp.zeracreative.com/api
```
Then upload the contents of `build/web/` to the subdomain's document root
(find the exact path in cPanel → **Domains** → `erp.zeracreative.com` →
Document Root). For example, via `rsync` over SSH:
```bash
rsync -avz --delete build/web/ youruser@erp.zeracreative.com:~/erp.zeracreative.com/
```
Replace the destination path with the real document root if different.

### Step 7 — Verify

Visit `https://erp.zeracreative.com` and confirm the login page loads and
you can sign in with the seeded super admin credentials, then change that
password immediately.

## Ongoing deploys

- **Backend changes**: push to `main` → cPanel Git UI → Update from Remote →
  Deploy HEAD Commit. `.cpanel.yml` handles install/build/migrate/restart.
- **New migrations**: generate them locally the normal way
  (`npm run migration:generate -- src/migrations/<Name>`) against a schema
  that actually differs from your entities, commit them, and they'll run
  automatically on the next deploy via `migration:run`.
- **Frontend changes**: repeat Step 6 (build locally, upload `build/web/`).

## Troubleshooting

- **Deploy task fails on `npm run migration:run`**: SSH in, activate the venv,
  `cd` into the app root, and run `npm run migration:run` manually to see
  the full error. A common cause is env vars not saved correctly in Step 3.
- **App doesn't pick up changes after deploy**: the `touch tmp/restart.txt`
  trick doesn't always force Passenger to reload on every hosting setup —
  as a fallback, go to Setup Node.js App and click **Restart** manually.
- **500s referencing `ECONNREFUSED` to Postgres**: double check `DB_HOST` is
  `localhost` and the DB user/password/name match exactly what cPanel shows
  under PostgreSQL Databases (cPanel prefixes both the DB name and username
  with your account username).
- **Photos/avatars 404 in production**: uploads create `backend/uploads/avatars/`
  on demand (see `avatar-upload.config.ts`), so this is only relevant if you
  imported employees with photos directly on the server rather than through
  the upload endpoint — in that case the directory needs to exist first:
  `mkdir -p $APP_ROOT/uploads/avatars`.
