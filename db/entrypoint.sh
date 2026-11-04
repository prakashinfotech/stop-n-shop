#!/bin/bash
# Starts SQL Server, then on EVERY start:
#   1. creates ShopNShop_db if it does not exist
#   2. publishes the DACPAC (adds missing tables/procedures, keeps data, refuses to drop data)
#   3. loads db/seed.sql only if the catalog is empty (fresh database)
#   4. writes /tmp/db-ready  -> the container healthcheck only passes after this
# If the schema sync fails the container stays UNHEALTHY (API will not start against a stale DB)
# and the reason is in `docker logs`.
set -u
SQLCMD="/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -C"
DB=ShopNShop_db
rm -f /tmp/db-ready

/opt/mssql/bin/sqlservr &
MSSQL_PID=$!

echo "[db-init] Waiting for SQL Server to accept connections..."
RETRIES=0
until $SQLCMD -Q "SELECT 1" > /dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [ "$RETRIES" -ge 60 ]; then echo "[db-init] ERROR: SQL Server did not start within 120 s"; exit 1; fi
  sleep 2
done
echo "[db-init] SQL Server is ready."

EXISTS=$($SQLCMD -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '$DB'" 2>/dev/null | tr -d '[:space:]')
if [ "$EXISTS" != "1" ]; then
  echo "[db-init] Creating database $DB..."
  $SQLCMD -Q "CREATE DATABASE $DB COLLATE SQL_Latin1_General_CP1_CI_AS;" || { echo "[db-init] ERROR: could not create database"; wait $MSSQL_PID; exit 1; }
fi

echo "[db-init] Syncing schema from DACPAC (adds anything missing, keeps data)..."
if /opt/sqlpackage/sqlpackage /Action:Publish \
     /SourceFile:/db-init/ShopNStopDB.dacpac \
     /TargetConnectionString:"Server=localhost;Database=$DB;User Id=sa;Password=$SA_PASSWORD;TrustServerCertificate=True;" \
     /p:BlockOnPossibleDataLoss=True \
     /p:DropObjectsNotInSource=False \
     /Quiet:True; then
  echo "[db-init] Schema sync OK."
else
  echo "[db-init] ##### SCHEMA SYNC FAILED - database is NOT ready. See the sqlpackage output above. #####"
  wait $MSSQL_PID
  exit 1
fi

PRODUCTS=$($SQLCMD -d $DB -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.Products" 2>/dev/null | tr -d '[:space:]')
if [ "$PRODUCTS" = "0" ]; then
  echo "[db-init] Catalog is empty - loading seed data..."
  $SQLCMD -d $DB -b -i /db-init/seed.sql || echo "[db-init] WARNING: seed load reported errors"
else
  echo "[db-init] Catalog already has data ($PRODUCTS products) - skipping seed."
fi

touch /tmp/db-ready
echo "[db-init] Database ready."
wait $MSSQL_PID
