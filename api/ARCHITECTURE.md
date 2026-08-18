# API Architecture — StopNShop Backend

## Stack
- **Runtime:** ASP.NET Core 8 Web API
- **ORM:** Dapper (micro-ORM — raw SQL via stored procs)
- **DB:** SQL Server SQLEXPRESS01 → database `ShopNShop_db`
- **Auth:** JWT Bearer (30-day tokens), BCrypt password hashing
- **Validation:** FluentValidation
- **Port:** `http://localhost:5000` (dev, HTTP only)
- **Static files:** `wwwroot/uploads/products/` served at `/uploads/products/{filename}`

## Layered Architecture
```
HTTP Request
    ↓
Controller           (api/Controllers/)       — routes, auth guards, calls Service
    ↓
Service              (api/Services/)           — business logic, calls Repository
    ↓
Repository           (api/Repositories/)      — Dapper + stored procs, returns DTOs
    ↓
SQL Server (stored procedures only — ZERO inline SQL anywhere)
```

## Response Contract
Every endpoint returns `ApiResponse<T>` from `api/Common/ApiResponse.cs`:
```csharp
{ success: bool, message: string, data: T | null, errors: string[] | null }
```

## Controllers → Services → Repositories (1:1:1 mapping)

| Controller | Service | Repository | Domain |
|---|---|---|---|
| AuthController | AuthService | AuthRepository | Customer auth, OTP, profile, addresses |
| SellerAuthController | SellerAuthService | SellerRepository | Seller login/signup/profile/onboarding |
| ProductsController | ProductService | ProductRepository | Public product listing, detail, search |
| SellerProductController | SellerProductService | SellerProductRepository | Seller CRUD products, images, variants |
| SellerInventoryController | SellerProductService | SellerProductRepository | Stock management |
| CatalogueController | CatalogueService | CatalogueRepository | Categories, brands, filters |
| CartController | CartOrderService | CartOrderRepository | Cart add/remove/update |
| OrdersController | CartOrderService | CartOrderRepository | Checkout, order history |
| WishlistController | (inline) | (inline) | Wishlist add/remove/list |
| BrandsController | BrandService | BrandRepository | Brand listing |
| AddressesController | AuthService | AuthRepository | User delivery addresses |
| SellerDashboardController | SellerDashboardService | SellerDashboardRepository | Stats, analytics |
| SellerOrderController | SellerOrderService | SellerOrderRepository | Seller order management |
| SellerAnalyticsController | SellerDashboardService | SellerDashboardRepository | Sales analytics |
| SellerController | SellerAuthService | SellerRepository | Seller onboarding complete |

## Auth & Roles
- Two separate auth flows: Customer (`/api/auth/`) and Seller (`/api/seller/auth/`)
- JWT claims: `ClaimTypes.NameIdentifier` = userId, `ClaimTypes.Role` = "Customer" | "Seller"
- Route guards: `[Authorize(Roles = "Customer")]`, `[Authorize(Roles = "Seller")]`
- Seller approval gate: `isApproved` flag on Sellers table; unapproved sellers cannot list products publicly

## DTOs (api/DTOs/)
| File | Domain |
|---|---|
| AuthDtos.cs | Login/register/OTP/profile DTOs |
| SellerDtos.cs | Seller signup/login/profile/product DTOs |
| ProductDtos.cs | Public product list/detail DTOs |
| CartOrderDtos.cs | Cart items, order create/detail |
| CatalogueDtos.cs | Category, subcategory, filter DTOs |
| BrandDtos.cs | Brand list DTO |

## Key Files
| File | Purpose |
|---|---|
| `Program.cs` | DI registration, middleware pipeline, JWT config, CORS, static files |
| `api/Common/ApiResponse.cs` | Response wrapper — always use this |
| `api/Middleware/ExceptionMiddleware.cs` | Global exception handler → 500 response |
| `api/Validators/SellerValidators.cs` | FluentValidation rules for seller flows |
| `appsettings.json` | DB connection string key: `DefaultConnection`, JWT: `Jwt:*` |
| `appsettings.Development.json` | Dev overrides (not committed — see .gitignore) |

## Image Upload Pattern
```csharp
// POST /api/seller/products/images/upload
// multipart/form-data, field: "files", max 10 files × 5MB
// Saved to: wwwroot/uploads/products/{guid}.jpg
// URL returned: /uploads/products/{guid}.jpg
```

## Stored Procedure Naming Convention
- Customer auth SPs: `usp_Auth_*`
- Seller SPs: `sp_Seller*` or `usp_Seller_*`
- Product SPs: `usp_Product_*`
- Cart/Order SPs: `usp_Cart_*`, `usp_Order_*`
- Admin SPs: `usp_Admin_*`
- Catalogue SPs: `usp_Catalogue_*`, `usp_CMS_*`
