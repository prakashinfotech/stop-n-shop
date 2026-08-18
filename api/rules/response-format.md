## API Response Format

All endpoints must return `ApiResponse<T>` defined in `api/Common/ApiResponse.cs`.

Never return:
- `Ok(data)` — use `Ok(ApiResponse<T>.Success(data))`
- `BadRequest("message")` — use `BadRequest(ApiResponse<T>.Fail("message"))`
- Raw objects directly

This ensures the frontend always receives a consistent shape:
```json
{ "success": true, "data": {}, "message": "" }
```
