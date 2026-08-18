Create a new DTO file for a feature in `api/DTOs/`.

Rules:
- One file per feature area (e.g., `ProductDtos.cs` contains all product-related DTOs)
- Request DTOs are suffixed `Request` (e.g., `CreateProductRequest`)
- Response DTOs are suffixed `Response` or `Dto` (e.g., `ProductResponse`)
- Use data annotations for validation: `[Required]`, `[MaxLength]`, `[Range]`, `[EmailAddress]`, etc.
- Never expose sensitive fields in Response DTOs (passwords, tokens, internal IDs where not needed)
- Read existing DTO files before creating to match the namespace and style used in this project
