# Database — Claude Rules

> Read [ARCHITECTURE.md](ARCHITECTURE.md) before any DB work.

## Tool Rule
Always use **Bash** tool for shell commands. Never PowerShell tool.

## Rules
- **SSDT-managed project — never use `CREATE OR ALTER PROCEDURE`, never `DROP` + `CREATE`, never `ALTER PROCEDURE`.** Every SP file declares `CREATE PROCEDURE` exactly once. The SSDT build/publish (SqlPackage / `dotnet build` on the .sqlproj / dacpac deployment) is what reconciles the schema in the target DB. Hand-running raw `CREATE OR ALTER` outside the build bypasses drift detection and corrupts the dacpac contract.
- To change an existing SP: edit the body inside the existing `CREATE PROCEDURE` block — leave the `CREATE PROCEDURE` keyword alone — and let the next build/deploy push the diff.
- To add a new SP: new file with `CREATE PROCEDURE` only. Never wrap edits in `IF EXISTS DROP` guards.
- All SPs must use `SET NOCOUNT ON` as the first statement after `BEGIN`.
- Follow naming convention: `usp_{Domain}_{Action}` (see ARCHITECTURE.md).
- Output parameters for IDs returned after INSERT.
- Use transactions for multi-table writes.
- Never modify table schemas without updating the corresponding `dbo/Tables/*.sql` file.

## Adding a New Stored Procedure Checklist
1. Create `dbo/StoredProcedures/usp_{Domain}_{Action}.sql`.
2. Implement with `CREATE PROCEDURE` (never `CREATE OR ALTER`).
3. Wire up in `api/Repositories/` via Dapper.
4. Build the .sqlproj / publish dacpac — the deployment applies the change. Do not run the raw `.sql` against the DB manually.
