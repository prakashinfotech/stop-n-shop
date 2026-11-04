# Production deployment — StopNShop

This directory holds the **edge** (host) configuration. Everything inside the
containers comes from the repo; this is the one layer that lives on the server.

- [`nginx/stop-n-shop.conf`](nginx/stop-n-shop.conf) — public UI vhost
- [`nginx/stop-n-shop-api.conf`](nginx/stop-n-shop-api.conf) — public API vhost

---

## The outage this fixes

**Symptom**

```
POST https://stop-n-shop.prakashsoftwares.com/api/auth/buyer/register  -> 405 Not Allowed
GET  https://stop-n-shop.prakashsoftwares.com/api/menu                 -> 200 text/html
GET  https://stop-n-shop-api.prakashsoftwares.com/api/menu             -> 200 application/json  (fine)
```

**Cause**

The UI bundle calls `/api` on its own origin — correct, and the intended design.
The `ui` container's nginx ([`stopnshop-ui/nginx.conf`](../stopnshop-ui/nginx.conf))
proxies `/api/` and `/uploads/` to the `api` container, and has done so since the
first commit (18 Aug 2026 — the file has never been modified).

But the public vhost was **serving a hand-built `dist/` folder from disk** instead
of proxying to that container. A static file server cannot route `/api`, so:

- `GET /api/*` falls through the SPA rewrite and returns `index.html`
- `POST /api/*` returns **405** — nginx will not accept POST to a static file

The API itself was never broken. The request simply never reached it.

**Proof the served files were hand-built, not the container image:** the live
`index.html` contained
`<script src="https://prisco.prakashsoftwares.com/api/public-activity/tracker.js">`.
That string exists nowhere in this repository, so no image built from this repo
could serve it.

> This was **not** a code bug, which is why nothing in the git history looked wrong.
> It was a deployment-topology mistake made outside the repo.

---

## Deploying

### 1. Pull and set the environment

```bash
git pull origin master
cp -n .env.example .env     # first time only
```

Edit `.env`. These two decide whether the site works:

| Variable | Production value |
|---|---|
| `ALLOWED_ORIGINS` | `https://stop-n-shop.prakashsoftwares.com` — exact scheme + host, **no trailing slash** |
| `VITE_API_URL` | `/api` — leave as-is for the same-origin setup below |

Also set `SA_PASSWORD` and `JWT_SECRET_KEY` to the values this server already uses.
`ALLOWED_ORIGINS` is now **mandatory**: the `api` container refuses to start without
it rather than silently booting with a localhost default.

### 2. Start the stack

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

Use `docker-compose.prod.yml`, **not** `docker-compose.yml` — the dev file hardcodes
`AllowedOrigins` to `http://localhost:3000`.

This gives you:

| Container | Host port | Serves |
|---|---|---|
| `stopnshop-ui` | 3000 | SPA **plus** `/api` and `/uploads` proxied to the api container |
| `stopnshop-api` | 5000 | the API |
| `stopnshop-db` | — | SQL Server; publishes the DACPAC on every start |

> **Never run `docker compose down -v`** — the `-v` destroys the `sqlserver_data`
> volume and with it all live data.

### 3. Install the edge vhost — the step that actually fixes the 405

```bash
sudo cp deploy/nginx/stop-n-shop.conf     /etc/nginx/sites-available/
sudo cp deploy/nginx/stop-n-shop-api.conf /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/stop-n-shop.conf     /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/stop-n-shop-api.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo nginx -s reload
```

Check the TLS certificate paths in those files match what certbot already issued on
this host before reloading.

**Then remove the old static web root** (or at minimum stop serving it) so nobody
redeploys into it by mistake:

```bash
ls -la /var/www/stopnshop-ui/   # or wherever dist/ was copied
```

### 4. Verify

```bash
./scripts/verify-deploy.sh https://stop-n-shop.prakashsoftwares.com \
                           https://stop-n-shop-api.prakashsoftwares.com
```

It exits non-zero on any failure and names the cause. All checks must pass —
in particular:

- `GET /api/menu` on the **UI host** returns `application/json`, not `text/html`
- `POST /api/auth/buyer/register` returns **400** (validation), not **405**
- the bundle hash is **not** `index-B8FYGKiu.js` (the broken pre-fix build)
- `index.html` contains no `prisco` script tag

---

## What must never be done again

| Don't | Why |
|---|---|
| `npm run build` on the host and copy `dist/` to a web root | Bypasses the container nginx — no `/api` proxy — this is the exact outage |
| Serve the UI vhost with `root /var/www/...` | Same thing |
| Add a `location /api` to the edge vhost | Unnecessary; the ui container already handles it. Two proxies in series drift out of sync |
| Deploy with `docker-compose.yml` in production | Hardcodes `AllowedOrigins=http://localhost:3000`; CORS blocks every call |
| Download the `ui-build` CI artifact and deploy it | It is a build-inspection artifact, not a deployable |

---

## Split-host alternative (only if you want the browser to call the API subdomain)

Not required — the setup above is simpler and needs no rebuild when the API moves.
If you do want it, `VITE_API_URL` is baked into the JS at **build time**, so the
image must be rebuilt:

```bash
# in .env
VITE_API_URL=https://stop-n-shop-api.prakashsoftwares.com/api
ALLOWED_ORIGINS=https://stop-n-shop.prakashsoftwares.com

docker compose -f docker-compose.prod.yml up -d --build ui
```

Setting `VITE_API_URL` as a shell variable before a **Docker** build does nothing —
it must reach the image as a build arg, which the compose files now do.

---

## Known separate issue: `GET /api/products` returns 500

Different root cause — a stale database schema, not routing. The `db` container now
publishes the SSDT DACPAC on every start, so step 2 above fixes it. Confirm with:

```bash
docker compose -f docker-compose.prod.yml logs db | grep -i 'schema sync'
```

If this server's SQL Server is **external** (not the `db` container), publish the
DACPAC manually — see [`db/MIGRATIONS.md`](../db/MIGRATIONS.md).
