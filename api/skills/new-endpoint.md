Scaffold a complete new API feature for ShopNStop.

When given a feature name (e.g., "Pincode check"), create:

1. **DTO** in `api/DTOs/` — Request and Response classes with data annotations
2. **Repository** in `api/Repositories/` — Calls the matching stored procedure via Dapper
3. **Service** in `api/Services/` — Business logic, calls repository
4. **Controller** in `api/Controllers/` — HTTP endpoints, calls service, returns `ApiResponse<T>`

Follow these patterns exactly:
- Controller inherits `ControllerBase`, has `[ApiController]` and `[Route("api/[controller]")]`
- All endpoints return `Task<IActionResult>` with `ApiResponse<T>` body
- Inject dependencies via constructor
- Protected routes use `[Authorize]`, public routes use `[AllowAnonymous]`
- Read existing controllers before generating to match the exact pattern used in this codebase
