## Repository Pattern

Data access layers are strictly separated:

- **Controllers** — HTTP only; call Services, never Repositories or SQL directly
- **Services** — Business logic; call Repositories only
- **Repositories** — All Dapper calls and stored procedure invocations live here only

No SQL strings, no `IDbConnection`, no Dapper imports in Controllers or Services.

Repository methods map 1:1 to stored procedures where possible.
Stored procedure name goes in the repository method as a constant or inline string — never built dynamically.
