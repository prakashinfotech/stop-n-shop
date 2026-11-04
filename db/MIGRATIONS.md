# StopNShop — Database Setup & Updates

**One source of truth:** the SSDT project in [`ShopNStopDB/`](../ShopNStopDB/) (65 tables,
198 stored procedures). There is no separate hand-kept schema script.

> **Golden rule (SSDT):** never use `CREATE OR ALTER`, `DROP`+`CREATE`, or `ALTER PROCEDURE`
> in `ShopNStopDB/`. Declare each object once with `CREATE`; the publish works out the diff.
> See [`ShopNStopDB/CLAUDE.md`](../ShopNStopDB/CLAUDE.md).

## Docker (the normal way — nothing to run by hand)

The `db` image ([`Dockerfile`](./Dockerfile), build context = **repo root**) compiles
`ShopNStopDB/` into a DACPAC. [`entrypoint.sh`](./entrypoint.sh) then does this on
**every container start**:

1. Creates `ShopNShop_db` if it does not exist.
2. Publishes the DACPAC — adds any missing tables/procedures/columns, **keeps all data**,
   and refuses (`BlockOnPossibleDataLoss=True`, `DropObjectsNotInSource=False`) to drop anything.
3. Loads [`seed.sql`](./seed.sql) **only if the catalog is empty** (fresh database).
4. Marks the container healthy. The API waits for this (`depends_on: service_healthy`).

So **deploying = pull the latest code, rebuild, restart**. A new server and an old, out-of-date
server both end up correct:

```bash
git pull origin master
docker compose build --no-cache          # or: docker compose -f docker-compose.prod.yml build --no-cache
docker compose up -d                     # or: ... -f docker-compose.prod.yml up -d
docker compose logs db | grep db-init    # expect: "Schema sync OK." then "Database ready."
```

If the sync cannot be applied (for example it would drop populated columns), the container
stays **unhealthy**, the API does not start against a stale schema, and `docker compose logs db`
shows `SCHEMA SYNC FAILED` with the reason.

> **Never run `docker compose down -v` on a server with live data** — `-v` deletes the database
> volume. A plain `down`/`up` keeps it.

Rebuilding the db image is required whenever anything under `ShopNStopDB/` changes, because the
DACPAC is compiled into the image.

## Manual — local SQL Server, no Docker

```bash
cd ShopNStopDB
dotnet build ShopNStopDB.sqlproj -c Release
sqlcmd -S localhost\SQLEXPRESS -C -Q "IF DB_ID('ShopNShop_db') IS NULL CREATE DATABASE ShopNShop_db;"
sqlpackage /Action:Publish /SourceFile:"bin/Release/ShopNStopDB.dacpac" \
           /TargetServerName:"localhost\SQLEXPRESS" /TargetDatabaseName:ShopNShop_db \
           /TargetTrustServerCertificate:True /p:BlockOnPossibleDataLoss=True
cd .. && sqlcmd -S localhost\SQLEXPRESS -C -d ShopNShop_db -i db/seed.sql     # fresh database only
```

For an existing database, run `/Action:DeployReport` first (same arguments plus
`/OutputPath:deploy-report.xml`) and review it before publishing.

## Verify a database is current

Run against the database named in the API's `ConnectionStrings__ShopNShop`:

```sql
SELECT COUNT(*) FROM sys.procedures;                                                 -- expect 198
SELECT name FROM sys.procedures WHERE name = 'usp_Inventory_Reservation_ExpireDue';  -- expect 1 row
```

## Optional patches

[`patches/`](./patches) holds older dated scripts. Their schema and procedure changes are
already in `ShopNStopDB/`, so they are **not needed**. The `*_data.sql` /
`*_inventory_init.sql` / `*_demo.sql` files only add optional demo or baseline rows
(warehouses, stock, settlements, dispatcher demo) and may be applied by hand if wanted:

```bash
sqlcmd -S localhost\SQLEXPRESS -C -d ShopNShop_db -i db/patches/<script>.sql
```

## Credentials

**No database passwords are stored in this repo.** The SQL Server `sa` password is supplied at
runtime via `SA_PASSWORD` (see `.env.example`). Avoid `;` and `"` in it — it is placed in a
connection string.
