## Stored Procedure Standards

- Always begin with `SET NOCOUNT ON`
- Always schema-qualify objects: `dbo.TableName` not just `TableName`
- Never use `SELECT *` — always name columns explicitly
- Always use `CREATE OR ALTER PROCEDURE` (not `CREATE` alone)
- Wrap all data-modifying logic in `BEGIN TRY / BEGIN CATCH` with `THROW` in CATCH
- Use transactions (`BEGIN TRAN / COMMIT / ROLLBACK`) when modifying multiple tables
- Never use cursors — use set-based operations
- Use `EXISTS` instead of `COUNT(*)` for existence checks
- All input parameters must be validated for NULL before use
