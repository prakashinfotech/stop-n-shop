# StopNShop — Claude Code Rules

## ⚠️ CRITICAL RULES — READ BEFORE ANY TASK

### Rule 1: No Assumptions — Always Verify All Three Layers
**BEFORE making ANY change, you MUST check that UI, API, and Database are in sync:**
1. **Database**: Check stored procedures, table schemas, and data exist
2. **API**: Check the correct endpoint is being called and returns expected data structure
3. **UI**: Check which API endpoint the frontend calls (via grep in code, not assumptions)

**NEVER assume** an endpoint exists or works without verifying it's called, returns correct data, and the frontend uses it.

**If changing ANY ONE of these three, you MUST:**
- Document exactly what changed in each layer
- Verify all three work together end-to-end by testing
- Before committing, state: "UI: [change], API: [change], DB: [change]"

### Rule 2: Pre-Commit Validation — Only Push Required Files
**BEFORE running `git commit`, execute:**
```bash
git status --short
```

**Files to NEVER commit:**
- `kill5000.bat`, `kill3000.bat`, `run*.bat`, `run*.sh` — process management scripts
- `WHAT_TO_PUSH.md`, `READY_TO_PUSH.md` — scratch planning docs
- `*.log`, `*.tmp` — temporary files
- `.env`, `credentials.json` — secrets
- `node_modules/`, `bin/`, `obj/`, `dist/` — build outputs
- `.DS_Store`, `Thumbs.db` — OS files

**Allowed files:**
- `*.cs`, `*.tsx`, `*.ts`, `*.sql`, `*.md`, `*.json` (except .env/secrets) — source code and docs
- `.github/workflows/` — CI/CD config

### Rule 3: Read Instructions First — No Repeating Mistakes
**ALWAYS read relevant files before starting work:**
- `CLAUDE.md` in the repo root and sub-project (api/, stopnshop-ui/, ShopNStopDB/)
- `ARCHITECTURE.md` for the module you're touching
- Existing patterns in the codebase (grep for similar features)

**Never skip this step.** If you make the same mistake twice, it means you didn't read the constraints.

---

## Permission Policy

**This is an evaluation-deadline project. Asking for permission on routine work wastes time the user does not have. DO NOT ASK.**

**Default behaviour: proceed without asking on EVERYTHING except explicit bug fixes.** For all evaluation-prep work (UI phases, feature additions, refactors, new pages, new endpoints, new SPs, new tests, builds, Docker rebuilds, commits, pushes, PR creation, dependency installs, config tweaks) — just run the tools. No "may I", no "should I", no "let me check first", no per-step confirmation. Permission is granted for the lifetime of the task and ALL follow-up turns until the user explicitly revokes it.

**The ONLY time to pause and ask is during a bug-fix flow** when the proposed change could destroy data or break existing logic in a non-reversible way. Specifically:
- Schema-breaking DB changes (dropping/renaming columns, narrowing types, NOT NULL on populated tables, removing FKs).
- Renaming or removing public API endpoints the UI already calls.
- Renaming or deleting public TypeScript exports other modules import.
- Deleting or rewriting existing tests beyond mechanical updates.
- Destructive git operations (force-push, reset --hard, branch -D, history rewrites).
- Removing a DI registration in `Program.cs` that other code depends on.

For everything else — additive schema, new endpoints, new files, new tests, formatting, class swaps, Docker rebuilds, dependency upgrades within a major version, commits, pushes — proceed without asking.

**If a tool call triggers a harness-level permission prompt**, the user has not "denied" the action — the harness is checking its own allowlist. Update `~/.claude/settings.json` allowlist to cover the pattern instead of stopping to ask.

---

## Tool Preferences
- **Always use the Bash tool** for shell commands — NEVER the PowerShell tool.
- Use `find`, `cat`, `grep` etc. via Bash. Never `Get-ChildItem` or other PS cmdlets.

---

## Git Commit Checklist (MANDATORY before every commit)

```bash
# Step 1: Review what you're about to commit
git status --short
git diff --name-only

# Step 2: Verify ONLY source files are included (no .bat, .sh, scratch docs, logs)
# Step 3: Check commit message format (see below)
# Step 4: Stage files explicitly by name (NOT git add -A or git add .)
git add api/Controllers/SomeController.cs stopnshop-ui/src/api/someApi.ts ShopNStopDB/dbo/StoredProcedures/usp_Example.sql

# Step 5: Create commit with proper message
git commit -m "..."
```

**Commit message format:**
```
type: brief description of what changed (50 chars max)

- Changed UI: [specific files, what changed]
- Changed API: [specific endpoints, what changed]  
- Changed DB: [stored procedures, tables, what changed]

Reason: [why this change was needed]
```

**Example:**
```
fix: category menu now shows Women and Kids categories

- Changed UI: no frontend changes (already uses /menu endpoint)
- Changed API: /menu endpoint returns correct category hierarchy via sp_GetMegaMenu
- Changed DB: created Men/Women/Kids categories linked to Menus table, added subcategories

Reason: Categories were created but not linked to correct MenuIds, preventing them from showing in header navigation
```

---

## Bug-Fixing Protocol

When the user says **"Fix this issue: {issueNumber}"**:

1. **Log immediately** — append the issue to `docs/issuesList.md` with: issue number, description, date, status = Open.
2. **Ask first** — if the exact symptom or reproduction step is unclear, ask one targeted question before touching any code.
3. **Three-strike rule** — after 3 failed fix attempts on the same issue, stop, re-read the original issue entry in `docs/issuesList.md`, then ask the user to confirm the root cause before attempting again.
4. **Update status** — mark the issue Resolved in `docs/issuesList.md` once confirmed working.

---

## Project Overview
Enterprise fashion ecommerce platform (Shoppers Stop clone). Evaluation assignment targeting 80+ score.

**Solution:** `C:\Users\dolly\Projects\Stop-N-Shop\StopNShop.sln`

**Sub-projects:**
| Folder | What it is | Architecture doc |
|---|---|---|
| `api/` | ASP.NET Core 8 Web API | [api/ARCHITECTURE.md](api/ARCHITECTURE.md) |
| `stopnshop-ui/` | React + Vite + TypeScript frontend | [stopnshop-ui/ARCHITECTURE.md](stopnshop-ui/ARCHITECTURE.md) |
| `ShopNStopDB/` | SQL Server SSDT project | [ShopNStopDB/ARCHITECTURE.md](ShopNStopDB/ARCHITECTURE.md) |
| `docs/` | Cross-cutting docs (CI/CD, api reference, guides) | — |

> **Before touching any sub-project, read its ARCHITECTURE.md first.**

---

## Dev Commands (Bash)
```bash
# API — run from repo root
cd api && dotnet run
# API runs on http://localhost:5000

# UI — run from repo root
cd stopnshop-ui && npm run dev
# UI runs on http://localhost:3000, proxies /api → localhost:5000

# UI build
cd stopnshop-ui && npm run build

# API publish
cd api && dotnet publish -c Release
```

---

## API Project: StopNShop.API

### Stack & Infrastructure
- **Framework:** ASP.NET Core 8 Web API
- **Architecture:** Repository → Service → Controller (strict 3-layer, no shortcuts)
- **Data access:** Dapper only. No EF Core. No raw SQL in C# — all queries are stored procedure calls.
- **Auth:** JWT Bearer. Role claims: `Admin`, `Buyer`, `Seller`. Separate login URLs per role, shared JWT infrastructure.
- **Serialization:** camelCase JSON (`AddJsonOptions` with `JsonNamingPolicy.CamelCase`)
- **Logging:** Serilog
- **Docs:** Swagger/OpenAPI with XML comments + JWT bearer security scheme
- **DB connection:** SQL Server via `IDbConnection` (injected as scoped, opened per request)

### Folder Structure (generate exactly this)
```
StopNShop.API/
  Controllers/
    AuthController.cs
    ProfileController.cs
    CatalogController.cs
    SellerController.cs
    CommerceController.cs
    EngagementController.cs
    AdminController.cs
    CmsController.cs
    PricingController.cs
    NotificationsController.cs
  Services/
    Interfaces/
      IAuthService.cs  IProfileService.cs  ICatalogService.cs ... (one per domain)
    AuthService.cs  ProfileService.cs  CatalogService.cs ...
  Repositories/
    Interfaces/
      IAuthRepository.cs  IProfileRepository.cs  ICatalogRepository.cs ...
    AuthRepository.cs  ProfileRepository.cs  CatalogRepository.cs ...
  Models/
    Requests/       ← inbound DTOs (validated with DataAnnotations or FluentValidation)
    Responses/      ← outbound DTOs
    Enums/          ← RoleType.cs, OrderStatus.cs, ApprovalStatus.cs, etc.
  Middleware/
    ExceptionMiddleware.cs    ← catches unhandled exceptions, returns ProblemDetails
    RequestLoggingMiddleware.cs
  Helpers/
    JwtHelper.cs
    PaginationHelper.cs
    SlugHelper.cs
    ResponseWrapper.cs        ← ApiResponse<T> { bool Success, T Data, string Message }
  Program.cs
  appsettings.json
```

---

## Global Standards (apply to every file generated)

### ApiResponse Wrapper
All endpoints return this shape:
```json
{ "success": true, "message": "OK", "data": { ... } }
{ "success": false, "message": "Invalid OTP", "data": null }
```

### Pagination
Any list endpoint accepts `?page=1&pageSize=20` and returns:
```json
{ "success": true, "data": { "items": [...], "totalCount": 120, "page": 1, "pageSize": 20 } }
```

### Repository Pattern
```csharp
public async Task<T> GetByIdAsync(int id)
{
    using var conn = _db.CreateConnection();
    return await conn.QueryFirstOrDefaultAsync<T>(
        "usp_Catalog_Product_GetById",
        new { ProductId = id },
        commandType: CommandType.StoredProcedure);
}
```

### Controller Pattern
```csharp
[HttpGet("{id}")]
[Authorize(Roles = "Buyer,Seller")]
[ProducesResponseType(typeof(ApiResponse<ProductResponse>), 200)]
public async Task<IActionResult> GetProduct(int id)
{
    var result = await _catalogService.GetProductByIdAsync(id);
    if (result is null) return NotFound(ApiResponse<object>.Fail("Product not found"));
    return Ok(ApiResponse<ProductResponse>.Ok(result));
}
```

### JWT Claims Helper
```csharp
var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
var role   = User.FindFirstValue(ClaimTypes.Role)!;
```

### Error Handling
`ExceptionMiddleware` catches all unhandled exceptions and returns:
```json
{ "success": false, "message": "An unexpected error occurred", "data": null }
```
Log the full exception via Serilog. Never expose stack traces to the client.

### SP Parameter Naming
Match DB column names exactly. If the SP expects `@ProductId`, pass `new { ProductId = id }`. Do not guess parameter names.

---

## Role-Based Authorization Reference

| Route prefix | Required role |
|---|---|
| `/api/auth/*` | Anonymous |
| `/api/profile/*` | Buyer or Seller (any authenticated) |
| `/api/products/*` (GET) | Anonymous |
| `/api/seller/*` | Seller only |
| `/api/admin/*` | Admin only |
| `/api/cart/*`, `/api/wishlist/*`, `/api/orders/*` | Buyer only |
| `/api/cms/*` (GET) | Anonymous |
| `/api/admin/cms/*` | Admin only |
| `/api/track/*` | Anonymous (fire and forget — always return 200) |
| `/api/notifications/*` | Buyer or Seller |

---

## Stored Procedure Parameter Reference

> **Critical:** Use exactly these parameter names when calling each SP.

### Auth Domain
| SP | Parameters |
|---|---|
| `usp_Auth_User_Register` | `@Email, @Mobile, @PasswordHash, @RoleId, @FirstName, @LastName` |
| `usp_Auth_User_Login` | `@Email, @PasswordHash, @RoleId` → returns `UserId, RoleId, IsApproved, IsEmailVerified, IsMobileVerified` |
| `usp_Auth_OTP_Send` | `@UserId, @OtpType` (1=Email, 2=Mobile), `@OtpCode, @ExpiresAt` |
| `usp_Auth_OTP_Verify` | `@UserId, @OtpCode, @OtpType` → returns `IsValid BIT` |
| `usp_Auth_User_ForgotPassword` | `@Email` → returns `UserId, Email` |
| `usp_Auth_User_ResetPassword` | `@UserId, @NewPasswordHash` |
| `usp_Auth_RefreshToken_Create` | `@UserId, @Token, @ExpiresAt, @DeviceInfo, @IpAddress` |
| `usp_Auth_RefreshToken_Validate` | `@Token` → returns `UserId, IsRevoked` |
| `usp_Auth_User_GetProfile` | `@UserId` |
| `usp_Auth_User_UpdateProfile` | `@UserId, @FirstName, @LastName, @ProfileImageUrl` |
| `usp_Auth_Address_Add` | `@UserId, @Label, @AddressLine1, @AddressLine2, @City, @State, @PinCode, @Country, @IsDefault` |
| `usp_Auth_Address_GetByUser` | `@UserId` |
| `usp_Auth_Address_Update` | `@AddressId, @UserId, @Label, @AddressLine1, @AddressLine2, @City, @State, @PinCode, @Country` |
| `usp_Auth_Address_Delete` | `@AddressId, @UserId` |
| `usp_Auth_Address_SetDefault` | `@AddressId, @UserId` |

### Catalog Domain
| SP | Parameters |
|---|---|
| `usp_Catalog_Brand_GetAll` | `@Page, @PageSize, @IsFeatured` (nullable BIT) |
| `usp_Catalog_Brand_GetById` | `@BrandId` |
| `usp_Catalog_Brand_Create` | `@BrandName, @SlugUrl, @LogoUrl, @BannerUrl, @Description, @TagLine, @IsFeatured, @SortOrder, @MetaTitle, @MetaDescription, @MetaKeywords, @CreatedBy` |
| `usp_Catalog_Brand_Update` | `@BrandId, @BrandName, @SlugUrl, @LogoUrl, @BannerUrl, @Description, @TagLine, @IsFeatured, @SortOrder, @UpdatedBy` |
| `usp_Catalog_Brand_Delete` | `@BrandId, @UpdatedBy` |
| `usp_Catalog_Brand_GetFeatured` | `@Count` (default 8) |
| `usp_Catalog_Category_Get` | `@GenderTypeId` (nullable) |
| `usp_Catalog_SubCategory_Get` | `@CategoryId` |
| `usp_Catalog_Product_GetById` | `@ProductId` |
| `usp_Catalog_Product_Search` | `@SearchTerm, @CategoryId, @SubCategoryId, @BrandId, @GenderTypeId, @MinPrice, @MaxPrice, @SortBy` (price_asc/price_desc/rating/newest), `@Page, @PageSize` |
| `usp_Catalog_Product_ListByBrand` | `@BrandId, @Page, @PageSize` |
| `usp_Catalog_Product_ListByCategory` | `@CategoryId, @SubCategoryId, @Page, @PageSize` |
| `usp_Catalog_Product_GetFeatured` | `@Count` |
| `usp_Catalog_Product_Create` | `@SellerId, @BrandId, @CategoryId, @SubCategoryId, @ProductName, @SlugUrl, @ShortDescription, @LongDescription, @MRP, @SellingPrice, @CostPrice, @GstRate, @Sku, @GenderTypeId, @Tags, @MetaTitle, @MetaDescription, @MetaKeywords, @CreatedBy` |
| `usp_Catalog_Product_Update` | all above + `@ProductId, @UpdatedBy` |
| `usp_Catalog_ProductVariant_Upsert` | `@ProductId, @Color, @ColorHexCode, @Size, @Material, @Pattern, @FitType, @VariantSku, @AdditionalPrice, @StockQuantity, @LowStockThreshold, @Weight, @BarCode` |
| `usp_Catalog_ProductVariant_Get` | `@ProductId` |
| `usp_Catalog_ProductImage_Add` | `@ProductId, @VariantId, @ImageUrl, @AltText, @SortOrder, @IsPrimary` |
| `usp_Catalog_ProductImage_Delete` | `@ImageId, @ProductId` |

### Commerce Domain
| SP | Parameters |
|---|---|
| `usp_Commerce_Cart_GetByUser` | `@UserId` |
| `usp_Commerce_Cart_AddItem` | `@UserId, @ProductId, @VariantId, @Quantity` |
| `usp_Commerce_Cart_UpdateQty` | `@CartId, @UserId, @Quantity` |
| `usp_Commerce_Cart_RemoveItem` | `@CartId, @UserId` |
| `usp_Commerce_Cart_Clear` | `@UserId` |
| `usp_Commerce_Wishlist_GetByUser` | `@UserId` |
| `usp_Commerce_Wishlist_Add` | `@UserId, @ProductId` |
| `usp_Commerce_Wishlist_Remove` | `@UserId, @ProductId` |
| `usp_Commerce_Coupon_Validate` | `@CouponCode, @UserId, @OrderSubTotal` → returns `IsValid, DiscountAmount, Message` |
| `usp_Commerce_Order_Place` | `@UserId, @ShippingAddressId, @PaymentMode, @CouponId, @SubTotal, @DiscountAmount, @CouponDiscount, @TaxAmount, @ShippingCharge, @TotalAmount` + order items as TVP or JSON |
| `usp_Commerce_Order_GetByUser` | `@UserId, @Page, @PageSize` |
| `usp_Commerce_Order_GetById` | `@OrderId, @UserId` |
| `usp_Commerce_Order_Cancel` | `@OrderId, @UserId, @CancellationReason` |

### Seller Domain
| SP | Parameters |
|---|---|
| `usp_Seller_Register` | `@UserId, @BusinessName, @GstNumber, @PanNumber, @BusinessAddressId, @BankAccountNumber, @BankIfscCode, @BankName` |
| `usp_Seller_GetProfile` | `@UserId` |
| `usp_Seller_UpdateProfile` | `@SellerId, @BusinessName, @BankAccountNumber, @BankIfscCode, @BankName, @UpdatedBy` |
| `usp_Seller_Product_GetAll` | `@SellerId, @ApprovalStatus` (nullable), `@Page, @PageSize` |
| `usp_Seller_Order_GetAll` | `@SellerId, @OrderStatus` (nullable), `@Page, @PageSize` |
| `usp_Seller_Order_UpdateStatus` | `@OrderItemId, @SellerId, @OrderStatus` |
| `usp_Seller_Dashboard_GetAnalytics` | `@SellerId, @FromDate, @ToDate` |
| `usp_Seller_Analytics_Aggregate` | `@AnalyticsDate` |

### Admin Domain
| SP | Parameters |
|---|---|
| `usp_Admin_Seller_Approve` | `@SellerId, @AdminUserId` |
| `usp_Admin_Seller_Reject` | `@SellerId, @AdminUserId, @RejectionReason` |
| `usp_Admin_Seller_Suspend` | `@SellerId, @AdminUserId` |
| `usp_Admin_Product_Approve` | `@ProductId, @AdminUserId` |
| `usp_Admin_Product_Reject` | `@ProductId, @AdminUserId, @RejectionReason` |
| `usp_Admin_User_GetAll` | `@RoleId` (nullable), `@Page, @PageSize` |
| `usp_Admin_Order_GetAll` | `@OrderStatus` (nullable), `@Page, @PageSize` |
| `usp_Admin_Dashboard_Stats` | (no params) → returns aggregated counts |

### Engagement Domain
| SP | Parameters |
|---|---|
| `usp_Engagement_Review_Add` | `@ProductId, @UserId, @OrderItemId, @Rating, @Title, @Body` |
| `usp_Engagement_Review_GetByProduct` | `@ProductId, @Rating` (nullable filter), `@Page, @PageSize` |
| `usp_Engagement_Review_Approve` | `@ReviewId, @AdminUserId` |
| `usp_Engagement_Review_MarkHelpful` | `@ReviewId, @UserId` |
| `usp_Engagement_ProductViewLog_Add` | `@ProductId, @UserId` (nullable), `@SessionId, @IpAddress, @DeviceType` |
| `usp_Engagement_SearchLog_Add` | `@UserId` (nullable), `@SearchTerm, @ResultCount, @ClickedProductId` (nullable) |
| `usp_Engagement_RecentlyViewed_Add` | `@UserId, @ProductId` |
| `usp_Engagement_RecentlyViewed_GetByUser` | `@UserId, @Count` (default 10) |

### CMS Domain
| SP | Parameters |
|---|---|
| `usp_CMS_Banner_GetActive` | `@BannerType` (nullable) |
| `usp_CMS_Banner_Upsert` | `@BannerId` (nullable = insert), `@Title, @SubTitle, @ImageUrl, @MobileImageUrl, @LinkUrl, @BannerType, @EntityId, @SortOrder, @StartDate, @EndDate, @UpdatedBy` |
| `usp_CMS_HomeSection_GetAll` | (no params) |
| `usp_CMS_HomeSection_Upsert` | `@SectionId` (nullable), `@SectionName, @SectionType, @Title, @SubTitle, @SortOrder, @ItemsToShow, @FilterJson, @UpdatedBy` |
| `usp_CMS_FooterContent_GetAll` | (no params) |

### Pricing Domain
| SP | Parameters |
|---|---|
| `usp_Pricing_Offer_GetActive` | `@ApplicableOn` (nullable), `@EntityId` (nullable) |
| `usp_Pricing_Offer_Create` | `@OfferName, @OfferType, @DiscountValue, @MinOrderValue, @MaxDiscountCap, @StartDate, @EndDate, @ApplicableOn, @EntityId, @UsageLimitTotal, @UsageLimitPerUser, @CreatedBy` |

### Notifications Domain
| SP | Parameters |
|---|---|
| `usp_Notifications_Send` | `@UserId, @Title, @Body, @NotificationType, @EntityType, @EntityId, @Channel` |
| `usp_Notifications_GetByUser` | `@UserId, @IsRead` (nullable), `@Page, @PageSize` |
| `usp_Notifications_MarkRead` | `@NotificationId, @UserId` |

---

## Implementation Phases

| Phase | Scope |
|---|---|
| **Phase 1** | Auth & Identity — `Program.cs`, `appsettings.json`, helpers, middleware, enums, Auth + Profile repos/services/controllers, all Auth & Profile DTOs |
| **Phase 2** | Catalog — brands, categories, products, variants, images |
| **Phase 3** | Seller — onboarding & dashboard |
| **Phase 4** | Commerce — cart, wishlist, orders, coupons |
| **Phase 5** | Engagement — reviews, tracking, recently viewed |
| **Phase 6** | Admin panel |
| **Phase 7** | CMS, pricing, notifications |

### Phase 1 — Files to Generate
- `Program.cs` — full DI registration, middleware pipeline, JWT config, Swagger, Serilog, Dapper connection factory
- `appsettings.json` — connection string, JWT settings, Serilog sinks
- `Helpers/ResponseWrapper.cs` — `ApiResponse<T>`
- `Helpers/JwtHelper.cs` — generate and validate JWT; include `UserId`, `Email`, `Role`, `SellerId` claims
- `Middleware/ExceptionMiddleware.cs`
- `Models/Enums/` — `RoleType.cs`, `OrderStatus.cs`, `ApprovalStatus.cs`, `OtpType.cs`, `BannerType.cs`, `OfferType.cs`, `NotificationType.cs`, `PaymentMode.cs`, `PaymentStatus.cs`
- `Repositories/Interfaces/IAuthRepository.cs` + `Repositories/AuthRepository.cs`
- `Services/Interfaces/IAuthService.cs` + `Services/AuthService.cs`
- `Controllers/AuthController.cs`
- `Repositories/Interfaces/IProfileRepository.cs` + `Repositories/ProfileRepository.cs`
- `Services/Interfaces/IProfileService.cs` + `Services/ProfileService.cs`
- `Controllers/ProfileController.cs`
- All request/response DTOs for auth and profile

---

## Global Architecture Rules
- **Controller → Service → Repository** — no logic shortcuts between layers.
- **Zero inline SQL** — all DB access through stored procedures via Dapper.
- **ApiResponse\<T\>** generic wrapper on every endpoint.
- **Async/Await everywhere**, Dependency Injection, Repository Pattern, FluentValidation.
- **JWT Bearer** auth: `Admin`, `Buyer`, `Seller` roles. Claims: `ClaimTypes.NameIdentifier` = userId, `ClaimTypes.Role`.
- Image uploads go to `api/wwwroot/uploads/products/` and are served statically.

---

## Known Gaps (as of 2026-05-12)
- No test files beyond `stopnshop-ui/src/test/setup.ts` — vitest configured but no test cases written.
- Seller dashboard chart is a placeholder (no real chart library integrated yet).
- `READY_TO_PUSH.md` and `WHAT_TO_PUSH.md` in root are scratch files — can be deleted.

## Evaluation Criteria (priority order)
1. Functional Completeness — customer flow + seller flow must both work end-to-end
2. Code Quality — layered arch, no shortcuts, clean naming
3. UI/UX — Premium aesthetic (warm cream Claude.ai surfaces + #c41230 red action colour from Shoppers-Stop palette), TailwindCSS + design tokens, design system in `stopnshop-ui/docs/DESIGN_SYSTEM.md` (v2 hybrid). Plan in `docs/UI_OVERHAUL_PLAN.md`.
4. Database & APIs — stored procs, standardized responses
5. Git Discipline & CI/CD — `.github/workflows/` present
6. AI Utilization — `docs/ai-prompts/` log

---

## Repo Structure
```
StopNShop/
├── CLAUDE.md                    ← you are here
├── api/                         ← ASP.NET Core 8 API
│   ├── CLAUDE.md
│   ├── ARCHITECTURE.md
│   ├── rules/
│   ├── skills/
│   └── ...
├── stopnshop-ui/                ← React frontend
│   ├── CLAUDE.md
│   ├── ARCHITECTURE.md
│   ├── rules/
│   ├── skills/
│   └── ...
├── ShopNStopDB/                 ← SQL Server SSDT
│   ├── CLAUDE.md
│   ├── ARCHITECTURE.md
│   ├── rules/
│   ├── skills/
│   └── ...
└── docs/                        ← cross-cutting docs
    ├── ai-prompts/
    ├── api/
    └── cicd/
```
