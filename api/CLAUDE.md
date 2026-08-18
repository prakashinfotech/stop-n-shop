# API — Claude Rules

> Read [ARCHITECTURE.md](ARCHITECTURE.md) before any backend work.

## Tool Rule
Always use **Bash** tool for shell commands. Never PowerShell tool.

## Dev Commands
```bash
dotnet run          # starts on http://localhost:5000
dotnet build        # verify compile
dotnet publish -c Release
```

## Coding Rules
- Every controller method returns `ActionResult<ApiResponse<T>>`.
- Every repository method must call a stored proc — no `db.Execute("SELECT ...")` inline.
- Services contain ALL business logic — controllers only validate auth, call service, return result.
- Use `async Task<T>` everywhere. Never `.Result` or `.Wait()`.
- Inject via constructor — no `ServiceLocator` or static access.
- FluentValidation for all request DTOs that come in from external callers.

## Adding a New Feature Checklist
1. Write SP in `ShopNStopDB/dbo/StoredProcedures/` following naming convention.
2. Add DTO in `api/DTOs/`.
3. Add Repository method (calls SP via Dapper).
4. Add Service method (calls Repository, applies logic).
5. Add Controller action (calls Service, wraps in `ApiResponse<T>`).
6. Register any new service/repo in `Program.cs` DI.

## Known Issues
- `SellerInventoryController` delegates to `SellerProductService` — not a separate InventoryService.
- No unit tests yet — only integration is manual via browser/Postman.
