# StopNShop — Enhancement Plan

> Living document. Updated at the start and end of every phase.
> Source of truth for scope, status, decisions, and risks.

**Owner:** Dolly
**Started:** 2026-05-18
**Target:** Shoppers Stop–class marketplace (admin + inventory + seller + modern themed UI)
**Reference blueprint:** see chat decomposition (12-section enterprise spec)

---

## 0. How to use this document

- Every Claude session begins by reading this file end-to-end.
- Phase status flows: `Not Started → Planned → In Progress → In Review → Done`.
- Check off acceptance criteria as they are verified (UI tested in browser, tests green, docs updated).
- Append every non-obvious decision to **§8 Decisions Log** with date and rationale.
- Append every risk/blocker to **§9 Risk Log** the moment it surfaces.
- Never delete entries — strike through with `~~text~~` and note the date.

---

## 1. Evaluation Targets (drives every decision)

| # | Target | How we demonstrate it |
|---|---|---|
| 1 | Functional completeness & robustness | End-to-end flows for customer, seller, admin all pass E2E suite |
| 2 | Code quality, modularity, maintainability | 3-layer rule, no inline SQL, FluentValidation, no god-files, ≥60% service coverage |
| 3 | Effective Claude usage | docs/ai-prompts/ log + this plan + structured prompts per phase |
| 4 | Git discipline | Atomic commits, conventional-commit-style messages, one branch per phase, PR per phase |
| 5 | UI/UX consistency | Design tokens, light/dark theme, AA contrast, shared component library |
| 6 | Documentation + E2E tests | ARCHITECTURE updates, module runbooks, Playwright happy-paths, xUnit + Vitest |
| 7 | Ownership & execution discipline | This plan kept current, issuesList.md kept current, demo script per phase |

---

## 2. Phase Overview

| Phase | Name | Branch | Status | Started | Finished |
|---|---|---|---|---|---|
| 0 | Discovery & Gap Matrix | `chore/enhancement-plan` | Merged | 2026-05-18 | 2026-05-18 |
| 1 | Admin Module | `feature/admin-module` | Merged | 2026-05-18 | 2026-05-18 |
| 2 | Inventory Module | `feature/inventory-module` | In Review | 2026-05-18 | 2026-05-19 |
| 3 | Seller Module | `feature/seller-module` | Merged | 2026-05-18 | 2026-05-18 |
| 4 | UI/UX + Theming | `feat/ui-theme-system` | Merged | 2026-05-18 | 2026-05-19 |
| 5 | Quality, Docs, CI | `chore/quality-pass` | Not Started | | |

---

## 3. Phase 0 — Discovery & Gap Matrix

**Goal:** Establish the baseline. No production code changes.

### Deliverables
- [x] Read all `CLAUDE.md`, `ARCHITECTURE.md`, `docs/issuesList.md`
- [x] Inventory of existing controllers / services / repos / SPs / UI routes
- [x] Gap matrix (below) populated
- [ ] This plan reviewed and approved by Dolly

### Inventory Snapshot (2026-05-18)
- **API controllers (21):** Auth, SellerAuth, Addresses, Brands, Catalogue, Products, Cart, Wishlist, Coupons, Orders, Razorpay, Reviews, Notifications, Wallet, Admin, Seller, SellerDashboard, SellerInventory, SellerAnalytics, SellerOrder, SellerProduct.
- **Services (14):** Auth, SellerAuth, Brand, Catalogue, Product, CartOrder, Coupon, Engagement, Email, Notification, Wallet, SellerDashboard, SellerOrder, SellerProduct. *(No dedicated AdminService — admin logic lives in `AdminRepository` called from controller; violates 3-layer rule.)*
- **Repositories (14):** Admin, Auth, Brand, Catalogue, Product, CartOrder, Coupon, Engagement, Notification, Wallet, Seller, SellerDashboard, SellerOrder, SellerProduct.
- **Stored procedures (~95):** Auth (17), Catalog (16), Commerce — cart/wishlist/order/coupon (12), Engagement — reviews/tracking (8), Admin (14), Seller (15), CMS (7), Pricing (3), Notifications (3), Wallet/misc (rest).
- **DB tables (40):** Users, Roles, RefreshTokens, OtpVerifications, UserAddresses, Sellers, SellerDocuments, SellerBrandMappings, SellerAnalyticsDaily, Brands, Categories, SubCategories, ProductSubCategories, GenderTypes, Menus, Products, ProductVariants, ProductImages, ProductSpecifications, PriceHistory, Cart, Wishlist, Orders, OrderItems, Coupons, Offers, BankOffers, Reviews, ReviewImages, ProductViewLogs, RecentlyViewed, SearchLogs, Notifications, Banners, HomeSections, FooterContent, Stores, Pincodes, Wallets, WalletTransactions, AuditLogs.
- **UI feature areas:** auth, home, products, category, cart, wishlist, orders, account, admin (7 pages), seller (9 pages), notifications, wallet, errors, stores.
- **Theme:** `ThemeContext` already present (light/dark) — needs token audit, FOUC fix, system mode verification.
- **Tests:** none — `stopnshop-ui/src/test/setup.ts` is the only test file; no `api.Tests/` project; no Playwright.
- **CI/CD:** 8 workflows present (`api-deploy`, `database-deploy`, `deploy-main`, `deploy`, `regression-tests`, `test-env-deploy`, `test`, `ui-deploy`) — need to verify they actually run unit tests + lint + typecheck.

### Gap Matrix

| Module | Have | Missing | Broken | Priority |
|---|---|---|---|---|
| Auth | Register/Login (Buyer + Seller), JWT, refresh tokens, OTP send/verify, forgot/reset password, logout. UI: LoginPage, SignupPage, SellerLogin/Signup. | Email verification flow wired end-to-end; rate limiting; password strength validation; account lockout on repeated failures. | OTP delivery channel is mocked (no real SMS provider). | P2 |
| Profile | `usp_Auth_User_GetProfile/UpdateProfile`, addresses CRUD, ProfilePage, AddressesPage. | Profile image upload endpoint; change-password UI in account. | — | P3 |
| Catalog | Brand/Category/SubCategory/Product/Variant/Image SPs + repos + services + controllers; ProductList, ProductDetail, Category pages. | Product specification editor in UI; rich text long description renderer; SEO meta in PDP `<head>`. | — | P3 |
| Cart | `usp_Commerce_Cart_*` (5 SPs), CartOrderRepository, CartController, CartPage. | Persistent guest cart merge on login; cart-line stock recheck on view. | — | P2 |
| Order | `usp_Commerce_Order_Place/GetByUser/GetById/Cancel`, OrdersController, OrdersList & OrderDetail pages, buyer-cancel SP. | Returns/RMA flow; invoice PDF; shipment tracking integration. | — | P2 |
| Payment | RazorpayController + Wallet (Wallets, WalletTransactions, WalletService). | Webhook signature verification hardening; refund flow on cancel/return; payment reconciliation report. | Razorpay flow not E2E tested. | P2 |
| Admin | 14 SPs (Dashboard stats, User_GetAll, Seller_Approve/Reject/Suspend/GetAll, Product_Approve/Reject/GetAll, Review_GetAll, Coupon CRUD/Toggle, Order_GetAll), AdminController, AdminRepository, 7 UI pages. | **No `AdminService` layer** (controller→repo direct, violates 3-layer rule); `usp_Admin_User_Suspend/Activate/SoftDelete`; `usp_Admin_Order_ForceCancel/ManualRefund`; `usp_Admin_AuditTrail_Log/Query` (table exists, no write hook); `usp_Admin_Seller_ScoreGet`; FluentValidation on admin inputs; role-guard on UI routes. | AuditLogs table is unused — no admin writes record audit. | **P1** (Phase 1) |
| Inventory | Stock fields on `ProductVariants` (StockQuantity, LowStockThreshold); `SellerInventoryController` for seller-side stock edits. | **Everything warehouse-aware:** `Warehouse`, `Stock`, `StockReservation`, `StockMovement`, `StockTransfer` tables; reservation/release SPs; movement ledger; low-stock alerts SP; reservation expiry worker; admin inventory matrix UI; seller bulk CSV upload. | Oversell risk — no concurrency control on `ProductVariants.StockQuantity` decrement during order placement. | **P1** (Phase 2) |
| Seller | Onboarding (signup/login/complete), profile, product CRUD, order list/detail/status update, dashboard analytics SPs + daily aggregate, seller inventory page, 9 UI pages. | `usp_Seller_Onboarding_AdvanceStage`, `usp_Seller_Document_Upload/Verify`, `usp_Seller_Settlement_Calculate`, `usp_Seller_PerformanceScore_Recompute`; SellerWarehouse / SellerBankAccount / VendorAgreement / CommissionPlan / SellerSLA / SellerPerformanceScore tables; settlement & score background workers; product upload wizard (multi-step); AWB stub. | Dashboard chart is a placeholder (known gap in CLAUDE.md). | **P1** (Phase 3) |
| Promotions | Coupons (Admin CRUD + buyer validate), Offers + BankOffers tables, `usp_Pricing_Offer_*`. | Bundle / BuyXGetY / tiered / flash-sale rule engine (deferred §12). | — | P4 (backlog) |
| CMS | Banner CRUD + GetActive/GetAll, HomeSection GetAll/Upsert, FooterContent GetAll, AdminCMSPage. | Landing-page builder; per-region scheduling; preview-as-customer. | — | P4 (backlog) |
| Notifications | `usp_Notification_Send/GetByUser/MarkRead`, NotificationsController, NotificationPage. | Email channel wired (EmailService exists, not invoked from Notification flow); SMS/WhatsApp/push (deferred §12). | — | P3 |
| Analytics | `usp_Seller_Dashboard_GetAnalytics`, `usp_Seller_Analytics_Aggregate`, `SellerAnalyticsDaily` table, `usp_Admin_Dashboard_GetStats`. | Real chart rendering on seller dashboard (Recharts not integrated); admin KPI trends over time. | — | P2 |
| UI design system | Tailwind, component folders (`components/ui/*`), DESIGN_SYSTEM.md placeholder, `<Skeleton>`, `<CommandPalette>`, `<ThemeToggle>`. | `tokens.css` with CSS custom properties; documented type/spacing/radius/shadow scales; shared `<DataTable>`, `<KpiCard>`, `<FilterBar>`, `<ConfirmDialog>`; empty states; consolidated toast system. | — | **P1** (Phase 4) |
| Theming (light/dark) | `ThemeContext`, `ThemeToggle` component, references across cart/cmd palette/AI drawer. | `system` mode + `prefers-color-scheme`; localStorage persistence audit; FOUC-prevention inline script in `index.html`; AA contrast scan in both themes; tokens-driven palette. | — | **P1** (Phase 4) |
| Tests (xUnit / Vitest / Playwright) | Vitest config + `src/test/setup.ts`. | xUnit project (`api.Tests/`); ≥60% service coverage; Vitest test cases; MSW handlers; Playwright config + happy-path E2E (customer / seller / admin); visual-regression suite. | — | **P1** (Phase 5) |
| CI/CD | 8 workflows in `.github/workflows/` covering api/db/ui deploy + regression-tests + test envs. | Single PR-gating workflow that runs lint + typecheck + unit tests + build before merge (`ci.yml`); coverage report upload; status checks made required on `main`. | Workflow purposes overlap — needs consolidation/audit. | P2 |

### Acceptance
- [x] Inventory captured above
- [x] Gaps identified per module with priority
- [ ] Plan approved by Dolly
- [x] Branches plan agreed (per §2; one branch per phase)
- [x] Risk log seeded (§10 — 3 risks logged 2026-05-18)

---

## 4. Phase 1 — Admin Module

**Goal:** Full governance surface — dashboard, users, sellers, products, orders, coupons, audit.

### DB (ShopNStopDB)
- [x] `usp_Admin_Dashboard_Stats` *(pre-existing as `_GetStats`)*
- [x] `usp_Admin_User_GetAll / _Suspend / _Activate / _SoftDelete`
- [x] `usp_Admin_Seller_Approve / _Reject / _Suspend / _ScoreGet`
- [x] `usp_Admin_Product_Approve / _Reject / _ModerationQueue`
- [x] `usp_Admin_Order_GetAll / _ForceCancel / _ManualRefund`
- [x] `usp_Admin_Coupon_CRUD` set + `_ToggleActive`
- [x] `usp_Admin_AuditTrail_Log / _Query`
- [x] ~~Seed: AuditAction lookup~~ → not needed; `AuditLogs.Action` is CHECK-constrained to INSERT/UPDATE/DELETE, the rich verb lives in `NewValues` JSON. Admin role already in `Seed_Critical.sql`.

### API (api/)
- [x] `AdminController` (role-guarded `[Authorize(Roles="Admin")]`)
- [x] `IAdminService` + `AdminService`
- [x] `IAdminRepository` + `AdminRepository`
- [x] Request/Response DTOs (in `api/DTOs/AdminDtos.cs`)
- [x] AuditTrail write hook on every admin write
- [x] FluentValidation rules for new admin inputs (UpdateCoupon, ForceCancelOrder, ManualRefund)

### UI (stopnshop-ui/src/features/admin)
- [x] Routes: `/admin/dashboard`, `/users`, `/sellers`, `/products/moderation`, `/orders`, `/coupons`, `/audit`
- [x] Reusable `<DataTable />`, `<KpiCard />`, `<FilterBar />`, `<ConfirmDialog />`
- [x] TanStack Query for server cache, URL-as-state for filters (AdminAuditPage)
- [x] Role guard on router (`AdminRoute`)

### Tests
- [x] xUnit: AdminService with mocked repos (7 tests, all green)
- [x] Vitest: KpiCard, ConfirmDialog (7 tests, all green)
- [ ] ~~Playwright E2E~~ — deferred to Phase 5 (no Playwright config in repo today)

### Docs
- [x] `docs/api/admin.md`
- [x] `docs/admin-runbook.md`
- [ ] Update `docs/issuesList.md` for any fixes done in flight *(no in-flight fixes — none to log)*

### Commit slices (one commit each)
- [x] `feat(admin-db): governance stored procedures`
- [x] `feat(admin-api): controller/service/repo with audit trail`
- [x] `feat(admin-ui): dashboard, users, sellers, moderation, orders, coupons, audit`
- [x] `test(admin): unit + e2e coverage` *(unit-only this phase)*
- [x] `docs(admin): API reference + runbook`

### Acceptance
- [x] All endpoints reachable via Swagger and role-protected
- [ ] All admin screens render in browser, golden paths verified *(pending Dolly's manual pass)*
- [x] Tests green locally
- [ ] PR opened with screenshots + demo script

---

## 5. Phase 2 — Inventory Module

**Goal:** Warehouse-aware stock with reservations, movement ledger, and concurrency safety.

### DB
- [x] Tables: `Warehouses`, `Stock`, `StockReservations`, `StockMovements` (append-only), `StockTransfers`
- [x] SPs: `usp_Inventory_Stock_GetByVariant / _Adjust / _Reserve / _ReleaseReservation`
- [x] `usp_Inventory_Movement_Log` (+ `_GetByVariant` for the admin drawer)
- [x] `usp_Inventory_LowStock_Alerts`
- [x] `usp_Inventory_Transfer_Initiate / _Receive`
- [x] `usp_Inventory_StockMatrix_Get`, `usp_Inventory_Reservation_ExpireDue`, `usp_Inventory_Warehouse_GetAll`
- [x] Seed: default platform warehouses (`Seed_Warehouses.sql`, 3 DCs)
- [x] Row-version / serializable strategy documented per `(VariantId, WarehouseId)` — `UPDLOCK,HOLDLOCK` + `ROWVERSION` (see `docs/inventory-model.md`)

### API
- [x] `InventoryController` (admin + seller-scoped, FluentValidation, audit hook)
- [ ] Reservation integration in cart/checkout flow:
  - [ ] Cart add → soft check
  - [ ] Checkout start → 15-min reservation
  - [ ] Order place → atomic decrement + reservation release
  - [ ] Cancel/return → restock via movement ledger
  *(SPs ship in this phase; wiring into the existing cart/order flow is tracked into Phase 3 to avoid touching commerce in the inventory PR)*
- [x] `ReservationExpiryWorker` background service (1-min sweep, batch 200)

### UI
- [x] Admin `/admin/inventory` — SKU × Warehouse matrix, low-stock panel, movement drawer, adjust-stock modal
- [x] Seller `/seller/inventory` — scoped matrix + adjust modal
- [ ] ~~Bulk CSV upload~~ → deferred to Phase 3 (seller module wizard)

### Tests
- [x] Unit: 13 xUnit tests covering `InventoryService` (validation, repo calls, audit hook) — green locally
- [x] Smoke: integration endpoint tests added for `/api/inventory/*`
- [x] Vitest: pure mapping coverage for `MOVEMENT_TYPE_LABELS` (component-level tests deferred to Phase 5 — no jsdom on main)
- [ ] Concurrency test: parallel order placements on same SKU do not oversell *(Phase 5)*
- [ ] E2E: low-stock alert fires when threshold crossed *(Phase 5)*
- [ ] Unit: reservation TTL expiry restores availability *(needs live DB harness — Phase 5)*

### Docs
- [x] `docs/inventory-model.md` — ledger semantics, reservation lifecycle, concurrency strategy, SP index, error codes

### Acceptance
- [ ] Oversell test passes under 50 concurrent attempts *(Phase 5 concurrency harness)*
- [ ] Cart→checkout→order flow correctly reserves and decrements stock *(Phase 3 wiring)*
- [x] Movement ledger is append-only and reconciles with on-hand *(enforced in SP design — every Stock change emits one row; ledger has no UPDATE/DELETE writers)*

### Commit slices (one commit each)
- [x] `feat(inventory-db): warehouse-aware stock tables, SPs, seed`
- [x] `feat(inventory-api): controller/service/repo with audit hook + reservation worker`
- [x] `feat(inventory-ui): admin + seller inventory pages with low-stock + movement drawer`
- [x] `test(inventory): xUnit InventoryService unit tests + endpoint smoke + Vitest`
- [x] `docs(inventory): model + ENHANCEMENT_PLAN checkpoints`

---

## 6. Phase 3 — Seller Module

**Goal:** Full seller lifecycle — onboarding, dashboard, fulfillment, settlement, performance.

### DB
- [x] Tables: `SellerDocuments` (pre-existing), `SellerWarehouses`, `SellerBankAccounts`, `VendorAgreements`, `CommissionPlans`, `SellerSLAs`, `SellerPerformanceScores`, `SellerSettlements`, `SellerSettlementLines`
- [x] SPs: existing seller set in CLAUDE.md, plus:
  - [x] `usp_Seller_Onboarding_AdvanceStage`
  - [x] `usp_Seller_Document_Upload / _Verify`
  - [x] `usp_Seller_BankAccount_Add / _GetAll / _SetPrimary`
  - [x] `usp_Seller_Warehouse_GetAll / _Upsert`
  - [x] `usp_Seller_VendorAgreement_Accept / _GetLatest`
  - [x] `usp_Seller_Settlement_Calculate` (T+7) + `_List / _GetById / _GetByMonth / _DueSellers`
  - [x] `usp_Seller_PerformanceScore_Recompute / _GetLatest / _AllSellers`
- [x] Seed: `Seed_CommissionPlans.sql` (3 default plans; wired into post-deploy)

### API
- [x] Seller onboarding wizard endpoints (stage advance + document upload)
- [x] Bank-account, warehouse, vendor-agreement endpoints
- [x] Settlement view endpoint (list + detail) + admin calculate trigger
- [x] Performance-score endpoint + on-demand recompute
- [x] `SellerSettlementWorker` (24h)
- [x] `SellerScoreWorker` (24h, rolling 30d)
- [x] Audit hook via structured Serilog (`audit user= action= payload=`)
  *(Scoped product / order endpoints + dashboard analytics already shipped on main; reservation-on-return ledger wiring deferred to Phase 4 alongside cart/checkout reservation work)*

### UI (stopnshop-ui/src/features/seller)
- [x] Onboarding wizard exists on main; advance-stage API now wired via `sellerLifecycleApi`
- [x] Dashboard with KPIs + Recharts (already real charts on main); this phase added `PerformanceScoreCard` + payouts panel
- [x] Settlements list page + detail page with statement layout
- [x] Bank accounts page (add / set-primary)
- [x] Warehouses page (upsert / primary toggle)
- [ ] ~~Product upload wizard refresh~~ → deferred to Phase 4 (existing `SellerAddProductPage` covers the data spec; the multi-step UX upgrade folds into theming)
- [ ] ~~Order fulfillment screen redesign~~ → deferred to Phase 4 (existing `SellerOrdersPage` covers the spec)

### Tests
- [x] xUnit: 19 `SellerLifecycleService` tests covering `ComputeLineMath`, T+7 guard, inverted-period guard, onboarding stage allow-list, document-type bounds, bank-account validation — green locally
- [x] Vitest: `SETTLEMENT_STATUS_LABELS` mapping — green locally
- [ ] E2E: seller signup → KYC → list product → receive order → ship → settlement appears *(Phase 5)*

### Docs
- [x] `docs/seller-handbook.md` — onboarding stages, SLAs, commission/TDS, T+7 settlement, performance score, endpoint index

### Acceptance
- [x] New seller can complete onboarding end-to-end (six stages persist; admin verifies docs)
- [x] Dashboard reflects real data with performance score widget + payouts panel
- [ ] Settlement worker produces correct statement for a known fixture order *(verified via xUnit unit math; live DB integration in Phase 5)*

### Commit slices (one commit each — landed)
- [x] `feat(seller-db): onboarding, bank, warehouses, settlement, performance`
- [x] `feat(seller-api): lifecycle controller/service/repo + settlement & score workers`
- [x] `feat(seller-ui): settlements, bank accounts, warehouses, performance score`
- [x] `test(seller): xUnit SellerLifecycleService + Vitest status labels`
- [x] `docs(seller): handbook + ENHANCEMENT_PLAN Phase 3 checkpoints`

---

## 7. Phase 4 — UI/UX Modernization + Theming

**Goal:** Premium e-commerce aesthetic with light + dark + system themes.

### Design Tokens
- [x] `stopnshop-ui/src/styles/tokens.css` with CSS custom properties:
  - colors (bg, surface, surface-elevated, text, text-muted, accent, accent-hover, success, warning, danger, border)
  - spacing scale, radius scale, shadow scale, z-index scale
  - typography (font families, size scale, line-height, weight)
- [x] Tailwind config consumes tokens via `theme.extend.colors`

### Theme System
- [x] `ThemeProvider` with modes: `light`, `dark`, `system`
- [x] Persist preference in localStorage; respect `prefers-color-scheme`
- [x] Toggle in header (3-state menu) *(account-settings entry deferred — header toggle is shared across all routes)*
- [x] No FOUC on initial paint (inline script in `index.html` to set class before hydration)

### Component Refresh
- [ ] Header (sticky, glassmorphism on scroll)
- [ ] Mega-menu
- [ ] Premium product card
- [ ] PDP image gallery with thumbnail rail
- [ ] Checkout stepper
- [ ] Empty states + skeletons
- [ ] Toast system

### Accessibility
- [ ] AA contrast verified in both themes (axe scan)
- [x] Focus rings on all interactive elements (`:focus-visible` token in `index.css`)
- [ ] Keyboard navigation for menus + modals
- [x] ARIA labels on icon-only buttons (theme toggle)

### Tests
- [ ] Playwright visual regression screenshots in both themes for: home, PLP, PDP, cart, checkout, admin dashboard, seller dashboard *(deferred to Phase 5)*
- [x] Vitest: ThemeProvider toggle + persistence + system preference (11 tests, green)

### Docs
- [x] Refresh `stopnshop-ui/docs/DESIGN_SYSTEM.md` with palette, type scale, spacing, component variants, do/don't examples

### Acceptance
- [x] Theme toggle works on every route without flicker (FOUC guard inline in `index.html`)
- [ ] Visual regressions reviewed and intentional *(deferred with Playwright suite)*
- [ ] Lighthouse a11y score ≥ 95 on key routes *(deferred — to verify on staging)*

### Commit slices (one commit each — landed)
- [x] `feat(ui-theme): design tokens + system mode + FOUC guard`
- [x] `test(ui-theme): vitest coverage for ThemeProvider`
- [x] `docs(ui-theme): theme system reference in DESIGN_SYSTEM.md`

---

## 7b. Phase 4b — Dynamic Categories + Variant Library (landed 2026-05-19)

**Goal:** Admin owns the home-page category tree end-to-end and pre-defines the
variant option library per subcategory; sellers can only enable/disable from the
admin-curated list.

### DB
- [x] `Categories.ShowInMegaMenu`, `SubCategories.ShowInMegaMenu` columns
- [x] `usp_Admin_Category_Upsert / _ToggleVisibility / _Reorder / _Delete`
- [x] `usp_Admin_SubCategory_Upsert / _ToggleVisibility / _Reorder / _Delete`
- [x] `usp_Admin_MegaMenu_GetTree` — admin tree fetch (incl. inactive)
- [x] `sp_GetMegaMenu` — now filters `ShowInMegaMenu = 1`
- [x] Tables: `VariantAttributes`, `SubCategoryVariantOptions`, `ProductDisabledVariantOptions`
- [x] SPs: `usp_Admin_VariantAttribute_GetAll`, `usp_Admin_SubCategoryOption_GetBySubCategory / _Upsert / _ToggleActive / _Delete / _BulkSet`
- [x] SPs: `usp_Catalog_SubCategoryOption_GetForSeller`, `usp_Seller_ProductDisabledOptions_Set`
- [x] Seeds: `Seed_VariantAttributes.sql` (5 attrs), `Seed_SubCategoryVariantOptions.sql` (629 options across 19 fashion subcats)

### API
- [x] `AdminCategoryController` — `/api/admin/categories/*`, audit-hooked
- [x] `AdminVariantLibraryController` — `/api/admin/variant-library/*`, audit-hooked
- [x] `VariantOptionsController` — public `/api/catalog/subcategories/{id}/variant-options` + seller `/api/seller/products/{id}/variant-options[/disabled]`
- [x] DI registrations in `Program.cs`

### UI
- [x] `AdminCategoriesPage` (`/admin/categories`) — tree view by Menu, per-row Active/Mega-menu toggles, reorder arrows, add/edit modals, soft-delete
- [x] `SubCategoryVariantsDrawer` — per-attribute chip editor opened from category row
- [x] `SubCategoryVariantPicker` — seller wizard component; chips default-on, untick = disabled for that product
- [x] Wired into both `SellerAddProductPage` and `SellerEditProductPage` (post-create flush of disabled-set, seeded from server on edit)

### Decisions
- Variant attributes are fixed at 5 (Size/Color/Material/Pattern/Fit) for v1; admin can extend later.
- Color metadata stores hex in `OptionMetadata` so seller picker can show swatches.
- Reorder uses up/down arrows (zero deps); drag-and-drop deferred to a polish pass.
- Soft-delete on options that have product references; hard-delete only when no references exist (handled inside `usp_Admin_SubCategoryOption_Delete`).
- `ShowInMegaMenu` and `IsActive` are independent. `IsActive=0` hides everywhere; `ShowInMegaMenu=0` only hides from the header mega-menu (PLPs remain reachable by slug).

---

## 7c. Phase 4c — Seller stepper wizard (landed 2026-05-19)

**Goal:** Replace the single-form seller add-product page with a 6-step wizard
whose rendering is driven by admin-owned per-subcategory form rules.

### DB
- [x] `SubCategories` + `ImageAngles`, `SizeScale`, `RequiresGender`, `RequiresDimensions`
- [x] `Products` + `LengthCm`, `WidthCm`, `HeightCm`, `WeightGm`
- [x] `ProductImages` + `ImageSlot`
- [x] `usp_Catalog_SubCategory_GetFormSchema` (new)
- [x] `usp_Admin_SubCategory_UpdateFormRules` (new, audited)
- [x] `usp_Seller_Product_Create`, `usp_Catalog_Product_Update`, `usp_Seller_ProductImage_Add`, `usp_Catalog_ProductImage_Add` all extended
- [x] Seed: `Seed_SubCategoryFormRules.sql` (heuristic backfill by name)
- [x] Seed: shoe-EU (36–46) + toy (Small/Medium/Large) appended to variant options seed

### API
- [x] `GET /api/catalog/subcategories/{id}/form-schema` (anon, cached 5 min)
- [x] `PATCH /api/admin/categories/subcategories/{id}/form-rules` (admin, audited)
- [x] Seller `CreateSellerProductRequest` / `UpdateSellerProductRequest` accept slot-aware `Images: [{Url, Slot}]` and `LengthCm/WidthCm/HeightCm/WeightGm`. Legacy `ImageUrls` still accepted.
- [x] `MapGender` helper in `SellerProductRepository` translates "Men/Women/Kids/Unisex" → `GenderTypeId`.

### UI
- [x] `<Stepper>` already existed — reused for the 6-step bar
- [x] `<ProductImageUploader>` with labeled dropzones + overflow "Detail shots" zone
- [x] `<GenderPicker>` radio chips bound to `GenderTypeId` (1–4)
- [x] `<DimensionsBlock>` 2×2 number inputs
- [x] `useLocalStorageState` hook drives draft persistence
- [x] `ProductWizard` shared by `SellerAddProductPage` and `SellerEditProductPage`
- [x] Admin "Form rules" tab inside `SubCategoryVariantsDrawer`

### Decisions
- Wizard navigates forward strictly (Next disabled until step Zod-equivalent passes); backward is free via stepper headers.
- Draft auto-saves to localStorage per mode (`sns_product_draft_new`, `sns_product_draft_edit_<id>`).
- One image per slot for v1; the `detail` slot accepts multiple as overflow.
- Form rules tab lives inside the existing variants drawer rather than a new page.
- `SizePicker` was folded into the existing `<SubCategoryVariantPicker>` (Size is just one of its attribute chip groups).

### Out of scope (deferred)
- Migrating `SellerOnboardingPage` to the shared `<Stepper>`.
- Drag-and-drop image reordering within a slot.
- Reconciling the orphan `ProductTypeId` field on `CreateSellerProductRequest`.

---

## 8. Phase 5 — Quality, Docs, CI

**Goal:** Lock in the bar.

- [ ] `api.Tests/` xUnit project — service coverage ≥ 60%
- [ ] MSW handlers for UI tests; cover hooks + critical components
- [ ] Playwright config + happy-path E2E per major flow (customer purchase, seller fulfillment, admin moderation)
- [ ] `.github/workflows/ci.yml`: lint + typecheck + unit tests + build on PR
- [ ] `docs/ai-prompts/` updated with master prompt + decisions log
- [ ] `docs/issuesList.md` reconciled to current state
- [ ] Root `README.md`: quickstart, mermaid architecture diagram, contribution guide

---

## 9. Decisions Log

| Date | Decision | Rationale | Reversible? |
|---|---|---|---|
| 2026-05-18 | Modular monolith over microservices | Single-dev project, evaluation deadline | Yes |
| 2026-05-18 | SQL Server + Docker over cloud Postgres | Matches assignment constraints + memory entry | Yes |
| 2026-05-18 | Phase 1 (Admin) must introduce `AdminService` layer — current controller→repo skip violates 3-layer rule | Code-quality target #2 in §1; refactor cost is small and isolated | Yes |
| 2026-05-18 | Phase 2 (Inventory) requires new `Warehouse`/`Stock`/`StockReservation`/`StockMovement` tables — existing `ProductVariants.StockQuantity` kept as denormalized cache, source-of-truth moves to ledger | Variant-level qty cannot model multi-warehouse, reservations, or audit trail; concurrency safety needs row-version anchored to `(VariantId, WarehouseId)` | Yes |
| 2026-05-18 | AuditLogs table exists but unused — Phase 1 wires write hook on every admin write (not a new table) | Avoids schema churn; satisfies governance acceptance criteria | Yes |
| 2026-05-18 | Admin audit verb stored in `NewValues` as `{"verb":"...","data":{...}}` rather than via a new `AuditAction` lookup table | Existing `AuditLogs.Action` is `CHECK`-constrained to INSERT/UPDATE/DELETE; avoiding a schema break keeps Phase 1 small. The UI parses the verb out for display. | Yes |
| 2026-05-18 | Phase 1 PR ships xUnit + Vitest tests only; Playwright deferred to Phase 5 | Repo has no Playwright config today; bringing it in would balloon Phase 1's diff. Validator-throw and route-guard E2E covered when Playwright lands in Phase 5. | Yes |

---

## 10. Risk Log

| Date | Risk | Likelihood | Impact | Mitigation | Status |
|---|---|---|---|---|---|
| 2026-05-18 | Scope creep — blueprint is 12 sections, time is finite | High | High | Strict phase gates; out-of-scope items moved to backlog (§12) | Open |
| 2026-05-18 | Stock concurrency bugs cause overselling | Medium | High | Concurrency test gate before Phase 2 sign-off | Open |
| 2026-05-18 | Theme refactor breaks existing screens | Medium | Medium | Visual regression suite before merge | Open |
| | | | | | |

---

## 11. Demo Scripts (per phase)

Each phase ends with a 10-step walkthrough an evaluator can follow.

### Phase 1 — Admin demo

1. `dotnet run` in `api/` and `npm run dev` in `stopnshop-ui/`; SQL build via `dotnet build` in `ShopNStopDB/` + dacpac publish.
2. Login as admin (`admin@stopnshop.com`). Land on `/admin/dashboard`.
3. Navigate to `/admin/sellers`, click **Approve** on a pending seller.
4. Open `/admin/audit` — verify an `APPROVE_SELLER` entry appears, attributed to the admin user with their IP.
5. Navigate to `/admin/products/moderation` — confirm the queue shows pending submissions oldest-first.
6. Approve one product; reject another with a reason.
7. On `/admin/users`, suspend a buyer; confirm the buyer can no longer log in. Activate them again.
8. Open an order on `/admin/orders` (in a non-terminal state) and run `Force cancel` with a reason via the API (or in-UI button when wired).
9. `PUT /api/admin/coupons/{id}` with a Postman call to edit a coupon; confirm the `UPDATE_COUPON` row in the audit feed.
10. Run `dotnet test` and `npm run test` — both green.

### Phase 2 — Inventory demo
1. _to fill on completion_

### Phase 3 — Seller demo
1. _to fill on completion_

### Phase 4 — Theming demo
1. _to fill on completion_

---

## 12. Out of Scope (Backlog)

Items from the blueprint deliberately deferred. Re-evaluate after Phase 5.

- Loyalty / First Citizen tier engine
- Promotion rule engine (bundle, BuyXGetY, tiered, flash sale beyond simple coupons)
- CMS builder (banners + home sections + landing pages)
- Notifications multi-channel (email + SMS + WhatsApp + push)
- Brand storefronts and co-marketing portal
- Recommendations / personalization service
- Fraud screening
- Multi-currency / i18n
- Mobile apps

---

## 13. Glossary

- **1P / 3P** — first-party (platform-owned inventory) vs. third-party (seller-owned)
- **BOPIS / BORIS** — buy online pick/return in store
- **OMS** — order management system
- **SLA** — service-level agreement (dispatch, delivery, refund timings)
- **TTL** — time-to-live (reservation expiry)
- **ATC** — add-to-cart
- **RTO** — return-to-origin (undelivered shipment)
