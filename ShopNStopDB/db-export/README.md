# DB Export — clone the live ShopNShop_db onto another machine

This folder holds two artefacts for moving the exact current database to another local SQL Server instance. Pick **whichever fits your situation**.

## Files in this folder

| File | What | Size |
|---|---|---|
| `ShopNShop_db.bacpac` | Microsoft's native schema + data package. Single binary file. Restore creates the DB from nothing. | ~124 KB |
| `Seed_DataDump.sql` | Plain-text `INSERT` statements for every row in every table (1167 inserts across 22 tables), wrapped with `DELETE FROM` guards and `IDENTITY_INSERT` toggles. Git-diffable. Applies on top of the SSDT-published schema. | ~525 KB |

## Option A — BACPAC (fastest, recommended for one-off clone)

On the **target** machine, install `sqlpackage` once:

```bash
dotnet tool install -g microsoft.sqlpackage
```

Then from the repo root:

```bash
ShopNStopDB\scripts\db-restore.bat                                  # uses default localhost\SQLEXPRESS01 / ShopNShop_db
ShopNStopDB\scripts\db-restore.bat "MYHOST\SQLEXPRESS" ShopNShop_db # or specify server/db
```

Behind the scenes this runs:

```
sqlpackage /Action:Import
  /SourceFile:ShopNStopDB\db-export\ShopNShop_db.bacpac
  /TargetServerName:localhost\SQLEXPRESS01
  /TargetDatabaseName:ShopNShop_db
  /TargetTrustServerCertificate:true
```

**The target DB must not already exist** — the importer creates it fresh. Drop it first if needed:

```sql
DROP DATABASE ShopNShop_db;
```

## Option B — Seed_DataDump.sql (repeatable, fits SSDT flow)

Use this if you want to:
- Keep the schema under SSDT (build/publish from `ShopNStopDB/`)
- Layer data on top via a single re-runnable SQL script
- Commit the seed data alongside the schema in git

Steps:

1. **Publish the schema first** (creates empty tables):
   ```bash
   cd ShopNStopDB
   BuildProject.bat --deploy "<server>" ShopNShop_db
   ```
2. **Apply the data dump**:
   ```bash
   sqlcmd -S "<server>" -E -d ShopNShop_db -b -I -i ShopNStopDB\db-export\Seed_DataDump.sql
   ```

The script:
- Disables triggers up-front so audit tables don't balloon
- Deletes every row from every table in reverse-FK order
- Re-inserts every row in FK-safe order with `IDENTITY_INSERT` toggled per table
- Re-enables triggers
- Prints `Seed_DataDump.sql complete.` on success

Safe to re-run — it always lands on the same final state.

## Refreshing the export after you've made changes

From the **source** machine, run from the repo root:

```bash
ShopNStopDB\scripts\db-export.bat        # writes ShopNStopDB\db-export\ShopNShop_db.bacpac
sqlcmd -S "localhost\SQLEXPRESS01" -E -d ShopNShop_db -b -I -y 0 \
    -i ShopNStopDB\scripts\generate-seed-dump.sql \
    -o ShopNStopDB\db-export\Seed_DataDump.sql   # regenerates the .sql dump
```

Then commit (or copy) the updated files.

## What's NOT in these files

- `appsettings.json` JWT secret / SMTP creds / ImgBB key — copy those manually, never commit them.
- The two leftover `wwwroot/uploads/products/*.png` files (133 of the 135 image rows already use ImgBB URLs; the remaining product images are hosted there).
- DB users, logins, server-level objects — only the database itself.
