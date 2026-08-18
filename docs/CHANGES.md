# Stop-N-Shop — Change Log

All implementation changes are recorded here with file path, line range, type, description and revert instruction.

---

### CHANGE-001 — CHANGES.md — 2026-05-13
- **File:** CHANGES.md (project root)
- **Type:** NEW FILE
- **Lines:** 1–end
- **Description:** Created this change tracker
- **Revert:** Delete file

---

### CHANGE-002 — CouponDtos.cs — 2026-05-13
- **File:** api/DTOs/CouponDtos.cs
- **Type:** NEW FILE
- **Lines:** 1–25
- **Description:** DTOs for coupon validation: `CouponValidateRequest` and `CouponValidateResult`
- **Revert:** Delete file api/DTOs/CouponDtos.cs

---

### CHANGE-003 — CouponRepository.cs — 2026-05-13
- **File:** api/Repositories/CouponRepository.cs
- **Type:** NEW FILE
- **Lines:** 1–40
- **Description:** `ICouponRepository` + `CouponRepository` calling `usp_Commerce_Coupon_Validate`
- **Revert:** Delete file api/Repositories/CouponRepository.cs

---

### CHANGE-004 — CouponService.cs — 2026-05-13
- **File:** api/Services/CouponService.cs
- **Type:** NEW FILE
- **Lines:** 1–25
- **Description:** `ICouponService` + `CouponService` delegating to `ICouponRepository`
- **Revert:** Delete file api/Services/CouponService.cs

---

### CHANGE-005 — CouponsController.cs — 2026-05-13
- **File:** api/Controllers/CouponsController.cs
- **Type:** NEW FILE
- **Lines:** 1–45
- **Description:** `POST /api/coupons/validate` — AllowAnonymous (temp for testing)
- **Revert:** Delete file api/Controllers/CouponsController.cs

---

### CHANGE-006 — ProductDtos.cs — 2026-05-13
- **File:** api/DTOs/ProductDtos.cs
- **Type:** MODIFIED — APPENDED
- **Lines appended:** ~132–160
- **Description:** Added `ReviewDto`, `AddReviewRequest`, `ProductReviewsDto` classes
- **Revert:** Delete lines 132–160 from api/DTOs/ProductDtos.cs

---

### CHANGE-007 — EngagementRepository.cs — 2026-05-13
- **File:** api/Repositories/EngagementRepository.cs
- **Type:** NEW FILE
- **Lines:** 1–70
- **Description:** `IEngagementRepository` + `EngagementRepository` calling `usp_Engagement_Review_GetByProduct` and `usp_Engagement_Review_Add`
- **Revert:** Delete file api/Repositories/EngagementRepository.cs

---

### CHANGE-008 — EngagementService.cs — 2026-05-13
- **File:** api/Services/EngagementService.cs
- **Type:** NEW FILE
- **Lines:** 1–50
- **Description:** `IEngagementService` + `EngagementService` — get/add product reviews with pagination
- **Revert:** Delete file api/Services/EngagementService.cs

---

### CHANGE-009 — ReviewsController.cs — 2026-05-13
- **File:** api/Controllers/ReviewsController.cs
- **Type:** NEW FILE
- **Lines:** 1–60
- **Description:** `GET /api/products/{id}/reviews` (anon) + `POST /api/products/{id}/reviews` (AllowAnonymous for temp testing)
- **Revert:** Delete file api/Controllers/ReviewsController.cs

---

### CHANGE-010 — EmailService.cs — 2026-05-13
- **File:** api/Services/EmailService.cs
- **Type:** NEW FILE
- **Lines:** 1–120
- **Description:** `IEmailService` + `EmailService` using Office365 SMTP; HTML order confirmation template
- **Revert:** Delete file api/Services/EmailService.cs

---

### CHANGE-011 — CartOrderService.cs — 2026-05-13
- **File:** api/Services/CartOrderService.cs
- **Type:** MODIFIED
- **Lines modified:** 50–56 (OrderService class)
- **Description:** `OrderService` constructor now injects `IEmailService` and `IAuthRepository`; fires order confirmation email after successful order placement
- **Revert:** Restore OrderService class lines 50–56 to original (constructor with only `IOrderRepository repo`)

---

### CHANGE-012 — Program.cs — 2026-05-13
- **File:** api/Program.cs
- **Type:** MODIFIED
- **Lines modified:** after line 94 and after line 109 (DI registrations)
- **Description:** Added 6 new service/repository registrations: CouponRepository, CouponService, EngagementRepository, EngagementService, EmailService (singleton)
- **Revert:** Remove the 6 added AddScoped/AddSingleton lines from api/Program.cs

---

### CHANGE-013 — appsettings.json — 2026-05-13
- **File:** api/appsettings.json
- **Type:** MODIFIED
- **Lines modified:** added "Smtp" config block
- **Description:** Added SMTP configuration for Office365 (notification@prakashinfotech.com)
- **Revert:** Remove the "Smtp": { ... } block from api/appsettings.json

---

### CHANGE-014 — reviewsApi.ts — 2026-05-13
- **File:** stopnshop-ui/src/api/reviewsApi.ts
- **Type:** NEW FILE
- **Lines:** 1–20
- **Description:** Axios API module for reviews: getProductReviews + addReview
- **Revert:** Delete file stopnshop-ui/src/api/reviewsApi.ts

---

### CHANGE-015 — ProductDetailPage.tsx — 2026-05-13
- **File:** stopnshop-ui/src/features/products/ProductDetailPage.tsx
- **Type:** MODIFIED
- **Lines modified:** 243–261 (static rating replaced), ~510–620 (review section added)
- **Description:** Static "4.2 (128 reviews)" replaced with real data from API; new Customer Reviews section added below "Users also bought"
- **Revert:** Restore static rating block at lines 243–261; remove Customer Reviews section

---

### CHANGE-016 — ProductListPage.tsx — 2026-05-13
- **File:** stopnshop-ui/src/features/products/ProductListPage.tsx
- **Type:** MODIFIED
- **Lines modified:** sort options array (1 line added)
- **Description:** Added `{ value: 'rating', label: 'Most Popular' }` sort option
- **Revert:** Remove the added sort option entry

---

### CHANGE-017 — CartPage.tsx — 2026-05-13
- **File:** stopnshop-ui/src/features/cart/CartPage.tsx
- **Type:** MODIFIED
- **Lines modified:** ~83–93 (placeOrderMutation) + new isProcessing state + overlay JSX
- **Description:** Added animated processing overlay (Framer Motion) during order placement
- **Revert:** Remove `isProcessing` state, overlay JSX, and mutation changes

---

### CHANGE-018 — OrderDetailPage.tsx — 2026-05-13
- **File:** stopnshop-ui/src/features/orders/OrderDetailPage.tsx
- **Type:** MODIFIED
- **Lines modified:** 11–17 (TRACKING_STEPS + icons/labels)
- **Description:** Expanded from 4 to 7 tracking statuses; added STEP_LABELS and new icons
- **Revert:** Restore TRACKING_STEPS to `['PLACED','CONFIRMED','SHIPPED','DELIVERED']` and original STEP_ICONS

---

### CHANGE-019 — LoginPage.tsx — 2026-05-13
- **File:** stopnshop-ui/src/features/auth/LoginPage.tsx
- **Type:** MODIFIED
- **Lines modified:** useForm options, input onChange handlers
- **Description:** Added `mode: 'onChange'` to useForm; clears serverError on any input change
- **Revert:** Remove `mode: 'onChange'` and the serverError-clearing onChange handlers

---

### CHANGE-020 — Wallets.sql — 2026-05-13
- **File:** ShopNStopDB/dbo/Tables/Wallets.sql
- **Type:** NEW FILE
- **Lines:** 1–18
- **Description:** `Wallets` table — one row per user, holds wallet balance; `UQ_Wallets_UserId` enforces single wallet per user
- **Revert:** Drop table `dbo.Wallets` (drop WalletTransactions first)

---

### CHANGE-021 — WalletTransactions.sql — 2026-05-13
- **File:** ShopNStopDB/dbo/Tables/WalletTransactions.sql
- **Type:** NEW FILE
- **Lines:** 1–22
- **Description:** `WalletTransactions` table — credit/debit history; TransactionType 1=Credit 2=Debit; FK to Wallets and Users
- **Revert:** Drop table `dbo.WalletTransactions`

---

### CHANGE-022 — usp_Wallet_GetBalance.sql — 2026-05-13
- **File:** ShopNStopDB/dbo/StoredProcedures/usp_Wallet_GetBalance.sql
- **Type:** NEW FILE
- **Lines:** 1–22
- **Description:** Returns wallet balance for a user; returns 0 if no wallet row exists yet (LEFT JOIN dummy)
- **Revert:** Drop procedure `dbo.usp_Wallet_GetBalance`

---

### CHANGE-023 — usp_Wallet_Credit.sql — 2026-05-13
- **File:** ShopNStopDB/dbo/StoredProcedures/usp_Wallet_Credit.sql
- **Type:** NEW FILE
- **Lines:** 1–50
- **Description:** MERGE upserts wallet row, credits balance, inserts WalletTransactions record; returns NewBalance
- **Revert:** Drop procedure `dbo.usp_Wallet_Credit`

---

### CHANGE-024 — usp_Wallet_GetTransactions.sql — 2026-05-13
- **File:** ShopNStopDB/dbo/StoredProcedures/usp_Wallet_GetTransactions.sql
- **Type:** NEW FILE
- **Lines:** 1–26
- **Description:** Paginated transaction history for a user, ordered by CreatedAt DESC
- **Revert:** Drop procedure `dbo.usp_Wallet_GetTransactions`

---

### CHANGE-025 — usp_Seller_Order_Cancel.sql — 2026-05-13
- **File:** ShopNStopDB/dbo/StoredProcedures/usp_Seller_Order_Cancel.sql
- **Type:** NEW FILE
- **Lines:** 1–80
- **Description:** Seller-side order cancel: verifies seller ownership, cancels order (status 6), restores stock, credits buyer wallet if PaymentMode=2, inserts buyer notification; returns BuyerUserId/OrderNumber/TotalAmount/PaymentMode for email dispatch
- **Revert:** Drop procedure `dbo.usp_Seller_Order_Cancel`

---

### CHANGE-026 — NotificationDtos.cs — 2026-05-13
- **File:** api/DTOs/NotificationDtos.cs
- **Type:** NEW FILE
- **Lines:** 1–22
- **Description:** `NotificationDto` (maps SP columns: NotificationId→id, Body→message) and `NotificationsResultDto` with TotalPages computed property
- **Revert:** Delete file api/DTOs/NotificationDtos.cs

---

### CHANGE-027 — WalletDtos.cs — 2026-05-13
- **File:** api/DTOs/WalletDtos.cs
- **Type:** NEW FILE
- **Lines:** 1–30
- **Description:** `WalletDto`, `WalletTransactionDto`, `WalletPageDto` used by WalletController
- **Revert:** Delete file api/DTOs/WalletDtos.cs

---

### CHANGE-028 — SellerDtos.cs — 2026-05-13
- **File:** api/DTOs/SellerDtos.cs
- **Type:** MODIFIED — APPENDED
- **Lines appended:** after `UpdateOrderStatusRequest` class (~line 324)
- **Description:** Added `SellerCancelOrderRequest` (cancellationReason) and `SellerCancelOrderResult` (BuyerUserId, OrderNumber, TotalAmount, PaymentMode) DTOs
- **Revert:** Delete the two new classes from api/DTOs/SellerDtos.cs

---

### CHANGE-029 — NotificationRepository.cs — 2026-05-13
- **File:** api/Repositories/NotificationRepository.cs
- **Type:** NEW FILE
- **Lines:** 1–85
- **Description:** `INotificationRepository` + `NotificationRepository` calling `usp_Notification_GetByUser`, `usp_Notification_MarkRead`, `usp_Notification_Send`; private `NotificationRow` maps SP columns to DTO
- **Revert:** Delete file api/Repositories/NotificationRepository.cs

---

### CHANGE-030 — NotificationService.cs — 2026-05-13
- **File:** api/Services/NotificationService.cs
- **Type:** NEW FILE
- **Lines:** 1–25
- **Description:** `INotificationService` + `NotificationService` delegating to repo
- **Revert:** Delete file api/Services/NotificationService.cs

---

### CHANGE-031 — NotificationsController.cs — 2026-05-13
- **File:** api/Controllers/NotificationsController.cs
- **Type:** NEW FILE
- **Lines:** 1–55
- **Description:** `GET /api/notifications`, `PATCH /api/notifications/{id}/read`, `PATCH /api/notifications/read-all`; AllowAnonymous (temp); returns empty result if unauthenticated
- **Revert:** Delete file api/Controllers/NotificationsController.cs

---

### CHANGE-032 — WalletRepository.cs — 2026-05-13
- **File:** api/Repositories/WalletRepository.cs
- **Type:** NEW FILE
- **Lines:** 1–65
- **Description:** `IWalletRepository` + `WalletRepository` calling `usp_Wallet_GetBalance` and `usp_Wallet_GetTransactions`
- **Revert:** Delete file api/Repositories/WalletRepository.cs

---

### CHANGE-033 — WalletService.cs — 2026-05-13
- **File:** api/Services/WalletService.cs
- **Type:** NEW FILE
- **Lines:** 1–18
- **Description:** `IWalletService` + `WalletService` delegating to `IWalletRepository`
- **Revert:** Delete file api/Services/WalletService.cs

---

### CHANGE-034 — WalletController.cs — 2026-05-13
- **File:** api/Controllers/WalletController.cs
- **Type:** NEW FILE
- **Lines:** 1–38
- **Description:** `GET /api/wallet?page&pageSize` — returns balance + paginated transactions; AllowAnonymous (temp)
- **Revert:** Delete file api/Controllers/WalletController.cs

---

### CHANGE-035 — SellerOrderRepository.cs — 2026-05-13
- **File:** api/Repositories/SellerOrderRepository.cs
- **Type:** MODIFIED
- **Lines modified:** interface + implementation (added `CancelOrderAsync`)
- **Description:** Added `CancelOrderAsync(orderId, sellerId, reason)` calling `usp_Seller_Order_Cancel`
- **Revert:** Remove `CancelOrderAsync` from interface and implementation

---

### CHANGE-036 — SellerOrderService.cs — 2026-05-13
- **File:** api/Services/SellerOrderService.cs
- **Type:** MODIFIED
- **Lines modified:** interface + implementation (added `CancelOrderAsync`)
- **Description:** Added `CancelOrderAsync` forwarding to repository
- **Revert:** Remove `CancelOrderAsync` from interface and implementation

---

### CHANGE-037 — SellerOrderController.cs — 2026-05-13
- **File:** api/Controllers/SellerOrderController.cs
- **Type:** MODIFIED
- **Lines modified:** constructor (added IEmailService + IAuthService), added `POST {orderId}/cancel` endpoint
- **Description:** New `POST /api/seller/orders/{orderId}/cancel` endpoint — calls SP, fires cancellation email fire-and-forget
- **Revert:** Remove cancel endpoint; restore constructor to single `ISellerOrderService svc` parameter

---

### CHANGE-038 — EmailService.cs — 2026-05-13
- **File:** api/Services/EmailService.cs
- **Type:** MODIFIED
- **Lines modified:** IEmailService interface + added `SendOrderCancellationAsync` + `BuildCancellationHtmlBody`
- **Description:** Added `SendOrderCancellationAsync` — branded red cancellation email; shows wallet refund badge if PaymentMode was Online
- **Revert:** Remove `SendOrderCancellationAsync` from interface and class; delete `BuildCancellationHtmlBody`

---

### CHANGE-039 — Program.cs — 2026-05-13
- **File:** api/Program.cs
- **Type:** MODIFIED
- **Lines modified:** DI registration block (added 4 new lines)
- **Description:** Registered `INotificationRepository`, `IWalletRepository`, `INotificationService`, `IWalletService`
- **Revert:** Remove the 4 added AddScoped lines

---

### CHANGE-040 — walletApi.ts — 2026-05-13
- **File:** stopnshop-ui/src/api/walletApi.ts
- **Type:** NEW FILE
- **Lines:** 1–35
- **Description:** Axios API module for wallet: `getWallet(page, pageSize)` calling `GET /api/wallet`
- **Revert:** Delete file stopnshop-ui/src/api/walletApi.ts

---

### CHANGE-041 — WalletPage.tsx — 2026-05-13
- **File:** stopnshop-ui/src/features/wallet/WalletPage.tsx
- **Type:** NEW FILE
- **Lines:** 1–120
- **Description:** Buyer wallet page — balance card (dark gradient), paginated transaction list with credit (green ↓) / debit (red ↑) indicators
- **Revert:** Delete file + folder stopnshop-ui/src/features/wallet/

---

### CHANGE-042 — AppRouter.tsx — 2026-05-13
- **File:** stopnshop-ui/src/router/AppRouter.tsx
- **Type:** MODIFIED
- **Lines modified:** lazy import block + route declarations
- **Description:** Added lazy `WalletPage` import + `<Route path="/wallet" element={<CustomerRoute><WalletPage/></CustomerRoute>} />`
- **Revert:** Remove WalletPage import and /wallet route

---

### CHANGE-043 — Header.tsx — 2026-05-13
- **File:** stopnshop-ui/src/components/layout/Header.tsx
- **Type:** MODIFIED
- **Lines modified:** import line (added Wallet icon) + desktop dropdown + mobile menu
- **Description:** Added "My Wallet" link to desktop account dropdown and mobile menu sidebar
- **Revert:** Remove Wallet from lucide import; remove DropdownLink and mobile Link for /wallet

---

### CHANGE-044 — sellerApi.ts — 2026-05-13
- **File:** stopnshop-ui/src/api/sellerApi.ts
- **Type:** MODIFIED
- **Lines modified:** orders object (added cancelOrder method)
- **Description:** Added `cancelOrder(orderId, cancellationReason?)` posting to `POST /api/seller/orders/{id}/cancel`
- **Revert:** Remove cancelOrder from orders object

---

### CHANGE-045 — SellerOrdersPage.tsx — 2026-05-13
- **File:** stopnshop-ui/src/features/seller/SellerOrdersPage.tsx
- **Type:** MODIFIED
- **Lines modified:** full rewrite of table + new modal
- **Description:** Added "Actions" column with red "Cancel" button for Pending/Confirmed/Processing orders; confirmation modal with optional reason textarea; fires cancelMutation and shows toast; notifies buyer via backend
- **Revert:** Remove XCircle import, cancelModal/cancelReason state, cancelMutation, Actions column, and modal JSX
