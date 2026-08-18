#!/bin/bash
set -e

/opt/mssql/bin/sqlservr &
MSSQL_PID=$!

echo "[db-init] Waiting for SQL Server to accept connections..."
RETRIES=0
until /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C \
      -Q "SELECT 1" > /dev/null 2>&1
do
  RETRIES=$((RETRIES + 1))
  if [ "$RETRIES" -ge 40 ]; then
    echo "[db-init] ERROR: SQL Server did not start within 80 s"
    exit 1
  fi
  sleep 2
done
echo "[db-init] SQL Server is ready."

DB_EXISTS=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C \
  -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = 'ShopNShop_db'" \
  -h -1 -W 2>/dev/null | tr -d '[:space:]')

if [ "$DB_EXISTS" != "1" ]; then
  echo "[db-init] Creating database..."
  /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C \
    -Q "CREATE DATABASE ShopNShop_db COLLATE SQL_Latin1_General_CP1_CI_AS;"

  echo "[db-init] Applying schema..."
  /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C \
    -d ShopNShop_db -i /db-init/schema.sql
  echo "[db-init] Schema applied."

  echo "[db-init] Loading seed data..."
  /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C \
    -d ShopNShop_db -i /db-init/seed.sql
  echo "[db-init] Seed data loaded. Database ready."
else
  echo "[db-init] Database already exists — skipping init."
fi

wait $MSSQL_PID
