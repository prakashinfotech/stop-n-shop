# StopNShop — Actor Flows

Sequential journey per role, derived from the live codebase (controllers in [api/Controllers/](../api/Controllers/), pages in [stopnshop-ui/src/features/](../stopnshop-ui/src/features/), routes in [AppRouter.tsx](../stopnshop-ui/src/router/AppRouter.tsx)). Each step cites **UI route → API endpoint → Stored Procedure / Controller**.

---

## 1. Admin Flow

The Admin is the platform operator. Single shared JWT auth with `Role=Admin` claim. All admin pages are guarded by `AdminRoute` in [AppRouter.tsx:143](../stopnshop-ui/src/router/AppRouter.tsx#L143).

### A. Authentication
1. **Login** — Admin opens `/user/login` (shared login page) → submits credentials → `POST /api/auth/admin/login` ([AuthController.cs](../api/Controllers/AuthController.cs)) → `usp_Auth_User_Login` validates against `RoleId=Admin` → JWT issued with `Role=Admin` claim → redirected to `/admin/dashboard`.
2. **Profile fetch on mount** — `GET /api/auth/me` rehydrates session via `AuthContext`.

### B. Dashboard & Overview
3. **Open dashboard** — `/admin/dashboard` → [AdminDashboardPage.tsx](../stopnshop-ui/src/features/admin/AdminDashboardPage.tsx) → `GET /api/admin/dashboard` → `usp_Admin_Dashboard_Stats` → returns aggregated counts (total users, sellers, products, orders, revenue, pending approvals).
4. **View audit log** — `/admin/audit` → `GET /api/admin/audit` → server-side action history.

### C. Seller Lifecycle Control
5. **List sellers** — `/admin/sellers` → [AdminSellersPage.tsx](../stopnshop-ui/src/features/admin/AdminSellersPage.tsx) → `GET /api/admin/sellers` with filter by `ApprovalStatus`.
6. **View seller performance score** — `GET /api/admin/sellers/{id}/score`.
7. **Approve seller** — `PATCH /api/admin/sellers/{id}/approve` → `usp_Admin_Seller_Approve` → seller can now list products.
8. **Reject seller** — `PATCH /api/admin/sellers/{id}/reject` with reason → `usp_Admin_Seller_Reject`.
9. **Suspend seller** — `PATCH /api/admin/sellers/{id}/suspend` → `usp_Admin_Seller_Suspend` → blocks their login/listing actions.

### D. Product Moderation (gate for going live)
10. **View moderation queue** — `/admin/products/moderation` → `GET /api/admin/products/moderation-queue` → returns products in `Pending` state.
11. **List all products with filters** — `/admin/products` → `GET /api/admin/products?status=...`.
12. **Approve a product** — `PATCH /api/admin/products/{id}/approve` → `usp_Admin_Product_Approve` → product becomes visible in storefront catalog.
13. **Reject a product** — `PATCH /api/admin/products/{id}/reject` with reason → `usp_Admin_Product_Reject` → seller notified.
14. **Bulk approve** — `PUT /api/admin/products/approve-all`.

### E. Inventory Oversight
15. **View low-stock / inventory across sellers** — `/admin/inventory` → `GET /api/inventory` aggregated view.

### F. Category & Menu Control (home page navigation)
16. **Open category tree** — `/admin/categories` → [AdminCategoriesPage.tsx](../stopnshop-ui/src/features/admin/AdminCategoriesPage.tsx) → `GET /api/admin/categories/tree`.
17. **Create category** — `POST /api/admin/categories` (sets menu placement, gender type, sort order).
18. **Toggle category active/inactive** — `PATCH /api/admin/categories/{id}/toggle` → controls whether it appears in header mega-menu (`GET /api/menu`).
19. **Reorder categories** — `PATCH /api/admin/categories/reorder`.
20. **Delete category** — `DELETE /api/admin/categories/{id}`.
21. **Create subcategory** — `POST /api/admin/categories/subcategories`.
22. **Toggle / reorder / delete subcategory** — `PATCH .../subcategories/{id}/toggle`, `PATCH .../subcategories/reorder`, `DELETE .../subcategories/{id}`.
23. **Set product form schema per subcategory** — `PATCH /api/admin/categories/subcategories/{id}/form-rules` → defines which fields (color/size/material) appear in seller's product wizard for this subcategory.

### G. CMS — Home Page Banners & Sections
24. **Open CMS** — `/admin/cms` → [AdminCMSPage.tsx](../stopnshop-ui/src/features/admin/AdminCMSPage.tsx) → `GET /api/admin/cms/banners`.
25. **Upload banner image** — `POST /api/admin/cms/banners/upload-image` (multipart).
26. **Create/update banner** — `POST /api/admin/cms/banners` → `usp_CMS_Banner_Upsert` (title, image, link URL, banner type, schedule start/end dates, sort order).
27. **Delete banner** — `DELETE /api/admin/cms/banners/{id}`.
28. **Banner link validation** — frontend uses [validateBannerLink.ts](../stopnshop-ui/src/features/admin/validateBannerLink.ts) before save.
29. *(Home sections — managed via the same CMS page driving `usp_CMS_HomeSection_*`.)*

### H. Coupon & Offer Control
30. **List coupons** — `/admin/coupons` → `GET /api/admin/coupons`.
31. **Create coupon** — `POST /api/admin/coupons` (code, discount type, min order value, usage limits, start/end dates).
32. **Edit coupon** — `PUT /api/admin/coupons/{id}`.
33. **Toggle active/inactive** — `PATCH /api/admin/coupons/{id}/toggle`.
34. **Delete coupon** — `DELETE /api/admin/coupons/{id}`.

### I. User Management
35. **List all users** — `/admin/users` → `GET /api/admin/users?roleId=` → `usp_Admin_User_GetAll`.
36. **Suspend a user** — `PATCH /api/admin/users/{id}/suspend`.
37. **Reactivate a user** — `PATCH /api/admin/users/{id}/activate`.
38. **Delete a user** — `DELETE /api/admin/users/{id}`.

### J. Order Oversight & Refunds
39. **List all orders across sellers** — `/admin/orders` → `GET /api/admin/orders?status=` → `usp_Admin_Order_GetAll`.
40. **Force-cancel an order** — `PATCH /api/admin/orders/{id}/force-cancel`.
41. **Issue refund** — `PATCH /api/admin/orders/{id}/refund` → credits buyer wallet.

### K. Review Moderation
42. **List pending reviews** — `/admin/reviews` → `GET /api/admin/reviews`.
43. **Approve review** — `PATCH /api/admin/reviews/{id}/approve` → `usp_Engagement_Review_Approve` → review becomes visible on PDP.

### L. Complaints
44. **View complaint queue** — `/admin/complaints` → `GET /api/admin/complaints`.
45. **Update complaint status** — `PATCH /api/admin/complaints/{id}`.

### M. Logout
46. Clear JWT in `AuthContext` → redirect to `/user/login`.

---

## 2. Seller Flow

Sellers register through a separate signup, undergo onboarding, await admin approval, then operate their storefront. Guarded by `SellerRoute` ([AppRouter.tsx:132](../stopnshop-ui/src/router/AppRouter.tsx#L132)).

### A. Registration & Authentication
1. **Open signup** — `/seller/register` → [SellerSignupPage.tsx](../stopnshop-ui/src/features/seller/SellerSignupPage.tsx) → submits email/mobile/password/business name → `POST /api/seller/auth/signup` → `usp_Auth_User_Register` with `RoleId=Seller`.
2. **Send OTP** — `POST /api/auth/otp/send` (email & mobile) → `usp_Auth_OTP_Send`.
3. **Verify OTP** — `POST /api/auth/otp/verify` → `usp_Auth_OTP_Verify`.
4. **Login** — `/seller/login` → [SellerLoginPage.tsx](../stopnshop-ui/src/features/seller/SellerLoginPage.tsx) → `POST /api/seller/auth/login` → `usp_Auth_User_Login` with `RoleId=Seller` → JWT issued.
5. **Forgot password flow** — `POST /api/auth/forgot-password` → OTP → `POST /api/auth/reset-password`.

### B. Onboarding (multi-stage — must complete before admin can approve)
6. **Land on onboarding wizard** — `/seller/onboarding` → [SellerOnboardingPage.tsx](../stopnshop-ui/src/features/seller/SellerOnboardingPage.tsx).
7. **Stage 1 — Business profile** — submit business name, GST, PAN → `POST /api/seller/onboarding/stage` → `usp_Seller_Register`.
8. **Stage 2 — Upload KYC documents** — `POST /api/seller/documents` (GST cert, PAN card, address proof).
9. **Stage 3 — Bank account** — `POST /api/seller/bank-accounts` → stored for payouts. Mark primary via `PUT /api/seller/bank-accounts/{id}/primary`.
10. **Stage 4 — Warehouse / pickup address** — `/seller/warehouses` → [SellerWarehousesPage.tsx](../stopnshop-ui/src/features/seller/SellerWarehousesPage.tsx) → `POST /api/seller/warehouses` (label, address lines, city, pin, contact).
11. **Stage 5 — Accept seller agreement** — `POST /api/seller/agreement/accept` → seller agreement record saved. `GET /api/seller/agreement/latest` returns current version.
12. **Wait for admin approval** — onboarding submitted; until admin runs step A.7 above, seller dashboard shows pending state and product creation is blocked.

### C. Dashboard (post-approval)
13. **Open dashboard** — `/seller/dashboard` → [SellerDashboardPage.tsx](../stopnshop-ui/src/features/seller/SellerDashboardPage.tsx) → `GET /api/seller/dashboard` → `usp_Seller_Dashboard_GetAnalytics` (orders today, revenue, pending shipments, low stock).
14. **View performance score** — `GET /api/seller/performance-score`. Recompute: `POST /api/seller/performance-score/recompute`.

### D. Profile & Settings
15. **View / edit profile** — `/seller/profile` → [SellerProfilePage.tsx](../stopnshop-ui/src/features/seller/SellerProfilePage.tsx) → `GET /api/seller/profile` → `usp_Seller_GetProfile`.
16. **Manage bank accounts** — `/seller/bank-accounts` → list/add/primary.
17. **Manage warehouses** — `/seller/warehouses` → add additional pickup addresses.

### E. Product Catalog Management
18. **List my products** — `/seller/products` → [SellerProductsPage.tsx](../stopnshop-ui/src/features/seller/SellerProductsPage.tsx) → `GET /api/seller/products` → `usp_Seller_Product_GetAll`.
19. **Open "Add product" wizard** — `/seller/products/new` → [SellerAddProductPage.tsx](../stopnshop-ui/src/features/seller/SellerAddProductPage.tsx) → [ProductWizard.tsx](../stopnshop-ui/src/features/seller/ProductWizard.tsx).
20. **Pick subcategory** — wizard fetches `GET /api/catalog/subcategories/{id}/form-schema` so the form shows only the fields admin enabled for that subcategory.
21. **Upload product images** — `POST /api/seller/products/images/upload`.
22. **Configure variants matrix** — [VariantMatrixEditor.tsx](../stopnshop-ui/src/features/seller/VariantMatrixEditor.tsx) — color × size combinations with per-variant stock & price.
23. **Submit product** — `POST /api/seller/products` → `usp_Catalog_Product_Create` + `usp_Catalog_ProductVariant_Upsert` + `usp_Catalog_ProductImage_Add` → status = `Pending` (needs admin approval before visible to buyers).
24. **Edit a product** — `/seller/products/{id}/edit` → [SellerEditProductPage.tsx](../stopnshop-ui/src/features/seller/SellerEditProductPage.tsx) → `PUT /api/seller/products/{id}` → `usp_Catalog_Product_Update`.
25. **Delete a product** — `DELETE /api/seller/products/{id}`.

### F. Inventory Management
26. **View stock per variant** — `/seller/inventory` → [SellerInventoryPage.tsx](../stopnshop-ui/src/features/seller/SellerInventoryPage.tsx) → `GET /api/seller/inventory`.
27. **Low-stock alerts** — `GET /api/seller/inventory/low-stock`.
28. **Update stock quantity** — `PATCH /api/seller/products/{id}/inventory`.

### G. Order Fulfillment
29. **Open order queue** — `/seller/orders/queue` → [SellerOrderQueuePage.tsx](../stopnshop-ui/src/features/seller/SellerOrderQueuePage.tsx) → `GET /api/seller/orders?status=New`.
30. **List all my orders** — `/seller/orders` → [SellerOrdersPage.tsx](../stopnshop-ui/src/features/seller/SellerOrdersPage.tsx) → `GET /api/seller/orders` → `usp_Seller_Order_GetAll`.
31. **View order detail** — `GET /api/seller/orders/{orderId}`.
32. **Update order status** — `PATCH /api/seller/orders/{id}/status` (Confirmed → Packed → Shipped → Delivered) → `usp_Seller_Order_UpdateStatus`.
33. **Print shipping label** — `/seller/orders/items/{itemId}/print` → [PrintLabelPage.tsx](../stopnshop-ui/src/features/seller/print/PrintLabelPage.tsx).
34. **Cancel an item** — `POST /api/seller/orders/{orderId}/cancel`.

### H. Settlements & Payouts
35. **View settlement list** — `/seller/settlements` → [SellerSettlementsPage.tsx](../stopnshop-ui/src/features/seller/SellerSettlementsPage.tsx) → `GET /api/seller/settlements`.
36. **View settlement detail** — `/seller/settlements/{id}` → `GET /api/seller/settlements/{settlementId}` (breakdown: gross sales, commission, GST, net payout).
37. **Trigger settlement calculation** — `POST /api/seller/settlements/calculate`.

### I. Logout
38. Clears JWT, returns to `/seller/login`.

---

## 3. Buyer Flow

Buyers (a.k.a. Customers) shop the storefront. Guarded by `CustomerRoute` ([AppRouter.tsx:83](../stopnshop-ui/src/router/AppRouter.tsx#L83)).

### A. Registration & Authentication
1. **Open signup** — `/user/signup` → [SignupPage.tsx](../stopnshop-ui/src/features/auth/SignupPage.tsx) → `POST /api/auth/buyer/register` → `usp_Auth_User_Register` with `RoleId=Buyer`.
2. **Send OTP** — `POST /api/auth/otp/send`.
3. **Verify OTP** — `POST /api/auth/otp/verify` → marks `IsEmailVerified` / `IsMobileVerified`.
4. **Login** — `/user/login` → `POST /api/auth/buyer/login` → JWT issued.
5. **First-login welcome bonus** — [WelcomeBonusModal.tsx](../stopnshop-ui/src/components/ui/WelcomeBonusModal.tsx) → `POST /api/wallet/welcome-bonus` credits wallet → `POST /api/auth/mark-first-login-complete`.
6. **Forgot password** — `POST /api/auth/forgot-password` → OTP → `POST /api/auth/forgot-password/verify-otp` → `POST /api/auth/reset-password`.

### B. Profile & Address Book
7. **View profile** — `/user/profile` → [ProfilePage.tsx](../stopnshop-ui/src/features/account/ProfilePage.tsx) → `GET /api/auth/profile` → `usp_Auth_User_GetProfile`.
8. **Update profile** — `PUT /api/auth/profile` → `usp_Auth_User_UpdateProfile`.
9. **Open address book** — `/user/addresses` → [AddressesPage.tsx](../stopnshop-ui/src/features/account/AddressesPage.tsx) → `GET /api/addresses` → `usp_Auth_Address_GetByUser`.
10. **Add address** — `POST /api/addresses` → `usp_Auth_Address_Add`.
11. **Set default address** — `PUT /api/addresses/{id}/default` → `usp_Auth_Address_SetDefault`.

### C. Browsing
12. **Home page** — `/home` → [HomePage.tsx](../stopnshop-ui/src/features/home/HomePage.tsx) fetches:
    - `GET /api/banners` + `GET /api/banners/stack` → carousel & promo strips
    - `GET /api/menu` → mega-menu categories
    - `GET /api/products/trending`, `GET /api/products/recommended`, `GET /api/products/offers/master`
    - `GET /api/subcategories/featured` → trending categories tiles
    - `GET /api/engagement/recent-searches` → personalized
13. **Browse a category** — `/home/category/{slug}` → [CategoryPage.tsx](../stopnshop-ui/src/features/category/CategoryPage.tsx) → `GET /api/categories/{id}/subcategories` + `GET /api/products?categoryId=` → `usp_Catalog_Product_ListByCategory`.
14. **Browse all products with filters** — `/home/products?brandId=&minPrice=&maxPrice=&sortBy=` → [ProductListPage.tsx](../stopnshop-ui/src/features/products/ProductListPage.tsx) → `GET /api/products` → `usp_Catalog_Product_Search`.
15. **Search** — header search bar → `GET /api/products?searchTerm=` → logs via `usp_Engagement_SearchLog_Add`.

### D. Product Detail Page (PDP)
16. **Open PDP** — `/home/product/{id}` → [ProductDetailPage.tsx](../stopnshop-ui/src/features/products/ProductDetailPage.tsx) → `GET /api/products/{id}` → `usp_Catalog_Product_GetById` (includes variants, images, brand, ratings).
17. **Pincode serviceability check** — `GET /api/pincode/{pin}`.
18. **View similar products** — `GET /api/products/{id}/similar`.
19. **View reviews** — `GET /api/products/{id}/reviews` → `usp_Engagement_Review_GetByProduct`.
20. **Track product view** — fire-and-forget → `usp_Engagement_ProductViewLog_Add` + `usp_Engagement_RecentlyViewed_Add`.

### E. Wishlist
21. **Add to wishlist** — `POST /api/wishlist/{productId}` → `usp_Commerce_Wishlist_Add`.
22. **View wishlist** — `/user/wishlist` → `GET /api/wishlist` → `usp_Commerce_Wishlist_GetByUser`.
23. **Remove from wishlist** — `POST /api/wishlist/{productId}` toggles (same endpoint).

### F. Cart
24. **Add to cart** — from PDP or product card → `POST /api/cart` → `usp_Commerce_Cart_AddItem` → opens cart drawer ([CartDrawer.tsx](../stopnshop-ui/src/components/cart/CartDrawer.tsx)).
25. **Open cart page** — `/user/cart` → [CartPage.tsx](../stopnshop-ui/src/features/cart/CartPage.tsx) → `GET /api/cart` → `usp_Commerce_Cart_GetByUser`.
26. **Update quantity** — `PUT /api/cart/{cartId}` → `usp_Commerce_Cart_UpdateQty`.
27. **Remove cart item** — `DELETE /api/cart/{cartId}` → `usp_Commerce_Cart_RemoveItem`.

### G. Checkout & Payment
28. **Apply coupon** — `POST /api/coupons/validate` → `usp_Commerce_Coupon_Validate` returns discount or rejection.
29. **View available coupons** — `GET /api/coupons/available`.
30. **Choose shipping address** — from address book (step 9–11).
31. **Create Razorpay order** — `POST /api/payments/razorpay/create-order`.
32. **Place order** — `POST /api/orders` → `usp_Commerce_Order_Place` with cart items, subtotal, discount, tax, shipping, payment mode → order record + per-seller order items created.

### H. Orders & Tracking
33. **List my orders** — `/user/orders` → [OrdersListPage.tsx](../stopnshop-ui/src/features/orders/OrdersListPage.tsx) → `GET /api/orders` → `usp_Commerce_Order_GetByUser`.
34. **View order detail / track** — `/user/orders/{id}` → [OrderDetailPage.tsx](../stopnshop-ui/src/features/orders/OrderDetailPage.tsx) → `GET /api/orders/{id}` → `usp_Commerce_Order_GetById` (status timeline driven by seller's status updates).
35. **Cancel order** — `DELETE /api/orders/{id}` → `usp_Commerce_Order_Cancel`.

### I. Wallet & Refunds
36. **Open wallet** — `/user/wallet` → `GET /api/wallet` → balance + transaction history (welcome bonus credits, refund credits from admin-issued refunds, debits when used at checkout).
37. **Dismiss welcome bonus modal** — `POST /api/wallet/welcome-bonus/dismiss`.

### J. Reviews
38. **Write review** — from order detail (only after delivery) → `POST /api/products/{productId}/reviews` → `usp_Engagement_Review_Add` → status `Pending` until admin step A.43 approves.

### K. Notifications
39. **Open notifications** — `/user/notifications` → [NotificationPage.tsx](../stopnshop-ui/src/features/notifications/NotificationPage.tsx) → `GET /api/notifications` → `usp_Notifications_GetByUser`.
40. **Mark one as read** — `PATCH /api/notifications/{id}/read`.
41. **Mark all read** — `PATCH /api/notifications/read-all`.

### L. Complaints
42. **Raise a complaint** — `POST /api/complaints` (against an order/seller).
43. **View my complaints** — `GET /api/complaints/mine`.

### M. Recently Viewed
44. Sidebar/home shows recently-viewed list from `usp_Engagement_RecentlyViewed_GetByUser` (auto-populated by step D.20).

### N. Logout
45. Clears JWT → returns to `/home`.

---

## 4. Guest Flow (unauthenticated visitor)

No JWT. Limited to read-only public endpoints. No `[Authorize]` on the catalog endpoints; protected mutations bounce to `/user/login`.

### A. Browsing (full storefront access)
1. **Land on home** — `/home` → same data as Buyer step C.12, but `recent-searches` & personalized recommendations return generic / empty.
2. **Header mega-menu** — `GET /api/menu` → admin-controlled categories.
3. **View banners & home sections** — `GET /api/banners`, `GET /api/banners/stack`.
4. **Browse category** — `/home/category/{slug}`, same endpoints as Buyer C.13.
5. **Browse / filter product list** — `/home/products` with brand, category, price-range, sort filters.
6. **View brands** — `GET /api/products/offers/master` etc.
7. **Open PDP** — `/home/product/{id}` works fully — variants, images, reviews, similar products, pincode check all available.
8. **Search** — works; search log captured anonymously (UserId=null).

### B. What Guests CANNOT do (each triggers redirect to `/user/login` via `CustomerRoute`)
9. Add to cart / view cart (`/user/cart`).
10. Add to wishlist / view wishlist (`/user/wishlist`).
11. Place an order (`/user/orders` is gated).
12. View order history or track an order.
13. Write a review.
14. Manage profile or addresses.
15. View wallet, notifications, complaints.
16. Apply a coupon.
17. Access any seller or admin route.

### C. Conversion path
18. Hitting any gated page passes a `returnUrl` query → after login the buyer is redirected back. So a guest can fill a wishlist mentally on PDP, click "Add to cart" → bounced to login → after signup/login lands directly back on the product.

---

## Cross-Role Notes

- **Single auth source** — all three roles share `/api/auth/otp/*`, `/api/auth/forgot-password`, `/api/auth/reset-password`, `/api/auth/profile`. Login endpoints differ (`/buyer/login`, `/seller/login`, `/admin/login`) and gate by `RoleId`.
- **Wrong-role bounce** — built into the router ([AppRouter.tsx:116](../stopnshop-ui/src/router/AppRouter.tsx#L116)) — a Buyer hitting `/admin/*` or a Seller hitting `/user/cart` gets a toast and is redirected to their home dashboard.
- **Admin can preview storefront** — `BuyerOrAdminRoute` ([AppRouter.tsx:100](../stopnshop-ui/src/router/AppRouter.tsx#L100)) lets Admin open `/user/cart` read-only.

End of actor flows.
