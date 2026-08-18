# StopNShop — Database Migrations & Setup

All database code is kept **separate from the application code**. There are two
representations of the schema, kept intentionally distinct:

| Location | Purpose | Used by |
|---|---|---|
| [`ShopNStopDB/`](../ShopNStopDB/) | SSDT / SQL Server Data Tools project — the **source of truth** (65 tables, 198 stored procedures, 21 seed scripts). Schema is reconciled via dacpac build/publish. | Local dev with Visual Studio / SqlPackage |
| [`db/`](.) | Runtime bootstrap bundle — a flat `schema.sql` + `seed.sql` plus ordered `patches/`, applied by the DB container on first boot. | `docker compose up` |

> **Golden rule (SSDT):** never use `CREATE OR ALTER`, `DROP`+`CREATE`, or `ALTER PROCEDURE`
> in the `ShopNStopDB/` project. Each object is declared once with `CREATE`; the
> build/publish reconciles the diff. See [`ShopNStopDB/CLAUDE.md`](../ShopNStopDB/CLAUDE.md).

---

## Option A — Docker (recommended, zero manual steps)

The `db` service builds from [`db/Dockerfile`](./Dockerfile) and runs
[`entrypoint.sh`](./entrypoint.sh), which on **first boot only**:

1. Waits for SQL Server to accept connections.
2. Creates the `ShopNShop_db` database.
3. Applies [`schema.sql`](./schema.sql).
4. Loads [`seed.sql`](./seed.sql).

On subsequent boots it detects the existing database and skips init (data persists
in the `sqlserver_data` volume). To force a clean rebuild:

```bash
docker compose down -v      # drops the volume
docker compose up -d --build
```

## Option B — Manual (local SQL Server, no Docker)

Run against your instance, in order:

```bash
sqlcmd -S localhost\SQLEXPRESS -C -Q "CREATE DATABASE ShopNShop_db;"
sqlcmd -S localhost\SQLEXPRESS -C -d ShopNShop_db -i db/schema.sql
sqlcmd -S localhost\SQLEXPRESS -C -d ShopNShop_db -i db/seed.sql
```

## Option C — SSDT publish (source of truth)

```bash
cd ShopNStopDB
dotnet build                # produces the .dacpac
# publish the dacpac with SqlPackage against your target DB
```

---

## Incremental patches

Dated, additive migration scripts live in [`db/patches/`](./patches) and are applied
**in filename order** on top of an existing database. They are cumulative — apply any
that post-date your current schema:

| Script | What it adds |
|---|---|
| `2026_05_26_inventory_init.sql` | Inventory tables + initial stock movement |
| `2026_05_26_variant_upsert_sp.sql` | Product-variant upsert stored procedure |
| `2026_05_26_order_status_progression.sql` | Order status state-machine |
| `2026_05_26_order_tracking_timeline.sql` | Buyer-facing order tracking timeline |
| `2026_05_26_settlements_sps.sql` | Seller settlement stored procedures |
| `2026_05_26_settlements_data.sql` | Settlement seed data |
| `2026_05_26_home_data.sql` | Home/CMS section seed data |
| `2026_05_27_dispatcher_schema_L1.sql` | Dispatcher workstream schema (L1) |
| `2026_05_27_dispatcher_L2_sps_and_demo.sql` | Dispatcher pickup flow SPs + demo data (L2) |
| `2026_05_28_dispatcher_delivery_otp.sql` | OTP-verified delivery flow (L3) |

Apply a patch manually:

```bash
sqlcmd -S localhost\SQLEXPRESS -C -d ShopNShop_db -i db/patches/<script>.sql
```

---

## Credentials

**No database passwords are stored in this repo.** The SQL Server `sa` password is
supplied at runtime via the `SA_PASSWORD` environment variable (see `.env.example`).
The real values are handed off separately — never committed.
