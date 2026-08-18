## API Authentication Rules

- Every controller action must have either `[Authorize]` or `[AllowAnonymous]` — never leave it implicit
- Controllers serving both public and private routes: apply `[Authorize]` at controller level, `[AllowAnonymous]` on specific public actions
- JWT is the only authentication mechanism — no session cookies
- User ID must be extracted from the JWT claims, never accepted as a request parameter (prevents IDOR)
- Admin-only endpoints must check for the Admin role: `[Authorize(Roles = "Admin")]`
- Seller-only endpoints: `[Authorize(Roles = "Seller")]`
