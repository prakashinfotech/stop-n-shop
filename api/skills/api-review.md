Review the provided controller or service file. Check for:

1. **Auth** — every endpoint has either `[Authorize]` or `[AllowAnonymous]`; no endpoint is accidentally public
2. **Response format** — all responses use `ApiResponse<T>` wrapper, never raw objects or `Ok(data)` directly
3. **Validation** — ModelState is checked or FluentValidation is applied before processing
4. **Error handling** — no try/catch that swallows exceptions; errors propagate to `ExceptionMiddleware`
5. **Repository pattern** — no Dapper/SQL calls inside the controller or service
6. **HTTP verbs** — GET for reads, POST for creates, PUT for full updates, PATCH for partial, DELETE for removal
7. **Naming** — endpoints follow REST conventions; no verb in route names (e.g., `/products` not `/getProducts`)

Report issues as: Critical / Warning / Suggestion.
