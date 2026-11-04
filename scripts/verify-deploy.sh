#!/usr/bin/env bash
# Post-deployment verification for StopNShop.
#
#   ./scripts/verify-deploy.sh https://stop-n-shop.prakashsoftwares.com \
#                              https://stop-n-shop-api.prakashsoftwares.com
#
# Exits non-zero if the deployment is not healthy. Safe to run repeatedly —
# every request is anonymous and read-only except one OPTIONS preflight.

set -uo pipefail

UI="${1:-https://stop-n-shop.prakashsoftwares.com}"
API="${2:-https://stop-n-shop-api.prakashsoftwares.com}"
UI="${UI%/}"; API="${API%/}"

pass=0; fail=0
ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$1"; pass=$((pass+1)); }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; printf '        %s\n' "$2"; fail=$((fail+1)); }

echo
echo "UI  = $UI"
echo "API = $API"
echo

# ── 1. The API host itself ───────────────────────────────────────────────────
echo "API host"
body=$(curl -fsS --max-time 20 "$API/api/menu" 2>/dev/null)
if [ -n "$body" ]; then ok "GET $API/api/menu returns a body"
else bad "GET $API/api/menu" "No JSON returned — API is down or the DB is unreachable."; fi

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$API/api/products")
case "$code" in
  200) ok "GET $API/api/products -> 200" ;;
  500) bad "GET $API/api/products -> 500" "Stale schema. The db container publishes the DACPAC on start; check: docker compose logs db | grep -i 'schema sync'" ;;
  *)   bad "GET $API/api/products -> $code" "Expected 200." ;;
esac

# ── 2. The outage this script exists to catch ────────────────────────────────
echo
echo "UI host /api routing  (the 405 / HTML outage)"
read -r code ctype < <(curl -s -o /dev/null -w '%{http_code} %{content_type}' --max-time 20 "$UI/api/menu")
if [ "$code" = "200" ] && [[ "$ctype" == application/json* ]]; then
  ok "GET $UI/api/menu -> 200 application/json"
elif [[ "$ctype" == text/html* ]]; then
  bad "GET $UI/api/menu -> $code $ctype" \
      "index.html came back, so /api is hitting a STATIC file server. The vhost is serving a dist/ folder instead of proxying to the ui container. Install deploy/nginx/stop-n-shop.conf."
else
  bad "GET $UI/api/menu -> $code $ctype" "Expected 200 application/json."
fi

code=$(curl -s -o /dev/null -w '%{http_code}' -X POST --max-time 20 \
       -H 'Content-Type: application/json' -d '{}' "$UI/api/auth/buyer/register")
if [ "$code" = "405" ]; then
  bad "POST $UI/api/auth/buyer/register -> 405" \
      "nginx refusing POST to a static file — the same root cause as above. Registration and login cannot work until this returns 400."
elif [ "$code" = "400" ] || [ "$code" = "422" ]; then
  ok "POST $UI/api/auth/buyer/register -> $code (reached the API; empty body correctly rejected)"
else
  bad "POST $UI/api/auth/buyer/register -> $code" "Expected 400 from the API's validation."
fi

read -r code ctype < <(curl -s -o /dev/null -w '%{http_code} %{content_type}' --max-time 20 "$UI/uploads/")
if [[ "$ctype" == text/html* ]]; then
  bad "GET $UI/uploads/ -> $ctype" "The /uploads proxy is missing too — product images will 404. Same vhost fix."
else
  ok "GET $UI/uploads/ is not answered by the SPA fallback"
fi

# ── 3. Proof the container build is being served, not a hand-built dist/ ──────
echo
echo "Served artifact"
html=$(curl -fsS --max-time 20 "$UI/" 2>/dev/null)
bundle=$(printf '%s' "$html" | grep -o 'assets/index-[^"]*\.js' | head -1)
if [ -n "$bundle" ]; then ok "Bundle served: $bundle"
else bad "Could not find assets/index-*.js in $UI/" "The UI is not serving a Vite build."; fi

if [ "$bundle" = "assets/index-B8FYGKiu.js" ]; then
  bad "Bundle is still index-B8FYGKiu.js" "That is the broken pre-fix build. The new image was not deployed, or a cache/CDN is in front."
else
  ok "Bundle hash differs from the known-broken build"
fi

if printf '%s' "$html" | grep -q 'prisco'; then
  bad "index.html contains the hand-injected prisco tracker <script>" \
      "That string exists nowhere in this repository, so the old hand-built dist/ is still being served."
else
  ok "index.html has no hand-injected script (it is the container build)"
fi

# ── 4. CORS (only matters for a split-host build) ─────────────────────────────
echo
echo "CORS"
acao=$(curl -s -D- -o /dev/null --max-time 20 -X OPTIONS \
       -H "Origin: $UI" -H 'Access-Control-Request-Method: POST' \
       "$API/api/menu" | tr -d '\r' | awk -F': ' 'tolower($1)=="access-control-allow-origin"{print $2}')
if [ "$acao" = "$UI" ]; then ok "API echoes Access-Control-Allow-Origin: $acao"
else bad "Access-Control-Allow-Origin was '${acao:-<missing>}'" \
         "Set ALLOWED_ORIGINS=$UI in .env and restart the api container."; fi

echo
printf 'passed %d, failed %d\n\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
