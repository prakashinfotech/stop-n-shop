## Error Handling Rules

- Do not use try/catch in controllers or services to swallow exceptions silently
- All unhandled exceptions are caught and formatted by `ExceptionMiddleware` in `api/Middleware/ExceptionMiddleware.cs`
- Throw meaningful exceptions with descriptive messages — they will be logged by the middleware
- For expected business errors (e.g., "product not found"), return the appropriate HTTP status via `ApiResponse.Fail()` — do not throw exceptions for these
- Never expose stack traces or internal error details in API responses in production
