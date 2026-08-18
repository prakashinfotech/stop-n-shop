## Input Validation Rules

- All POST/PUT/PATCH request bodies must use a typed DTO with data annotations
- Check `ModelState.IsValid` at the start of every action that accepts a request body, or use a global action filter
- Never trust client-supplied IDs for ownership checks — always resolve the user from JWT claims and verify ownership in the service layer
- Validate file uploads: check extension, MIME type, and size before saving
- Sanitise all string inputs that will be stored and later displayed (prevent stored XSS)
