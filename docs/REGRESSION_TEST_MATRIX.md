# Regression Test Matrix — Stop-N-Shop

## Purpose
Comprehensive regression testing matrix to ensure NO existing functionality is broken by Phase 2 changes.

---

## Authentication Module

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| User Registration | Valid all fields | Account created, auto-login | ⬜ | Test: AuthControllerTests.Register_WithValidRequest_ReturnsAuthToken |
| User Registration | Missing field | BadRequest 400 | ⬜ | Test: Covered by validation |
| User Registration | Duplicate email | Conflict 409 | ⬜ | Test: AuthControllerTests.Register_WithDuplicateEmail_ReturnsConflict |
| User Registration | Short password (<8) | BadRequest 400 | ⬜ | Test: AuthControllerTests.Register_WithShortPassword_ReturnsBadRequest |
| Buyer Login | Valid email/password | Returns JWT token | ⬜ | Test: AuthControllerTests.Login_WithValidCredentials_ReturnsToken |
| Buyer Login | Invalid password | Unauthorized 401 | ⬜ | Test: AuthControllerTests.Login_WithInvalidPassword_ReturnsUnauthorized |
| Email OTP | Send OTP to registered mobile | Returns OTP code | ⬜ | Existing endpoint |
| Email OTP | Verify OTP | Returns JWT token | ⬜ | Existing endpoint |
| Forgot Password | Valid email | Returns userId if exists | ⬜ | Existing endpoint |
| Reset Password | Valid userId + new password | Password updated | ⬜ | Existing endpoint |
| Get Profile | Authenticated user | Returns full profile | ⬜ | Test: AuthControllerTests.GetProfile_ReturnsUserProfile |
| Get Profile | Non-existent user | NotFound 404 | ⬜ | Test: AuthControllerTests.GetProfile_WithNonExistentUser_ReturnsNotFound |
| Update Profile | Valid first/last name | Profile updated | ⬜ | Test: AuthControllerTests.UpdateProfile_WithValidRequest_ReturnsUpdatedProfile |
| **NEW: First Login Flag** | **User registers** | **IsFirstLogin = true** | ⬜ | **New field added to Users table** |
| **NEW: First Login Flag** | **Call mark endpoint** | **IsFirstLogin = false** | ⬜ | **New endpoint: POST /mark-first-login-complete** |

---

## Product Catalog Module

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| Get Products | Browse catalog | Returns paginated list | ⬜ | Existing endpoint |
| Get Product | View by ID | Returns full details | ⬜ | Existing endpoint |
| Search Products | By keyword | Returns matching products | ⬜ | Existing endpoint |
| Search Products | By category | Returns filtered results | ⬜ | Existing endpoint |
| Search Products | By brand | Returns brand products | ⬜ | Existing endpoint |
| Search Products | By price range | Returns filtered results | ⬜ | Existing endpoint |
| Get Brand | View brand details | Returns brand info | ⬜ | Existing endpoint |
| Get Categories | List all categories | Returns category tree | ⬜ | Existing endpoint |

---

## Cart Module

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| **NEW: Payment Methods** | **Only COD enabled** | **UPI/CARD/NETBANKING disabled** | ⬜ | Test: CartPage.test.tsx |
| **NEW: Payment Tooltip** | **Hover disabled method** | **Shows "Feature currently unavailable"** | ⬜ | Test: CartPage.test.tsx |
| Get Cart | View current cart | Returns items + summary | ⬜ | Existing endpoint |
| Add to Cart | Add valid product | Item added, qty updated | ⬜ | Existing endpoint |
| Add to Cart | Invalid quantity | BadRequest 400 | ⬜ | Existing endpoint |
| Update Cart Item | Change quantity | Item qty updated | ⬜ | Existing endpoint |
| Update Cart Item | Zero quantity | Item removed from cart | ⬜ | Existing endpoint |
| Remove Item | Delete from cart | Item removed | ⬜ | Existing endpoint |
| Clear Cart | Empty all items | Cart becomes empty | ⬜ | Existing endpoint |
| Cart Summary | View pricing | Shows MRP, discount, final amount | ⬜ | Existing endpoint |

---

## Orders Module (Buyer)

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| Place Order | Valid address + COD | Order created, ID returned | ⬜ | Test: OrdersControllerTests.PlaceOrder_WithValidRequest_ReturnsOrderId |
| Place Order | Invalid address | BadRequest 400 | ⬜ | Validation error |
| Place Order | Empty cart | BadRequest 400 | ⬜ | Cannot place empty order |
| Get Orders | Buyer view list | Returns paginated orders | ⬜ | Test: OrdersControllerTests.GetOrders_ReturnsOrderList |
| Get Order Detail | View by ID | Returns full order | ⬜ | Test: OrdersControllerTests.GetOrder_WithValidId_ReturnsOrderDetail |
| Get Order Detail | Other buyer's order | NotFound 404 | ⬜ | Authorization check |
| **NEW: Cancel Order** | **Pending order** | **Order status → Cancelled** | ⬜ | Test: OrdersControllerTests.CancelOrder_WithValidOrder_ReturnsCancelledOrder |
| **NEW: Cancel Order** | **Confirmed order** | **Order status → Cancelled** | ⬜ | Allowed if seller hasn't started processing |
| **NEW: Cancel Order** | **Processing/Shipped** | **BadRequest 400** | ⬜ | Test: OrdersControllerTests.CancelOrder_WithShippedOrder_ReturnsBadRequest |
| **NEW: Cancel Email** | **Order cancelled** | **Email sent to buyer** | ⬜ | Fire-and-forget pattern |
| Order Tracking | View timeline | Shows all status changes | ⬜ | Existing endpoint |

---

## Seller Orders Module

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| Get Seller Orders | View order list | Returns paginated orders | ⬜ | Test: SellerOrderControllerTests.GetOrders_ReturnsSellerOrders |
| Get Seller Orders | Filter by status | Returns filtered orders | ⬜ | Test: SellerOrderControllerTests.GetOrders_WithStatusFilter_ReturnsPendingOrders |
| Get Order Detail | View seller's order | Returns full detail | ⬜ | Test: SellerOrderControllerTests.GetOrderDetail_WithValidOrder_ReturnsDetail |
| Get Order Detail | Other seller's order | NotFound 404 | ⬜ | Authorization check |
| **NEW: Update Status** | **Pending→Confirmed** | **Status updated, email sent** | ⬜ | Test: SellerOrderControllerTests.UpdateOrderStatusNew_WithValidStatus_UpdatesOrder |
| **NEW: Update Status** | **Forward progression** | **1→2→3→4→5 allowed** | ⬜ | State machine enforced |
| **NEW: Update Status** | **Backward movement** | **BadRequest 400** | ⬜ | Test: SellerOrderControllerTests.UpdateOrderStatusNew_WithInvalidProgression_ReturnsBadRequest |
| **NEW: Update Status** | **Invalid status** | **BadRequest 400** | ⬜ | Validation error |
| **NEW: Status Email** | **Confirmed status** | **Email with green checkmark** | ⬜ | HTML template with status-specific design |
| **NEW: Status Email** | **Processing status** | **Email with package icon** | ⬜ | HTML template with status-specific design |
| **NEW: Status Email** | **Shipped status** | **Email with truck icon + tracking** | ⬜ | HTML template with estimated delivery |
| **NEW: Status Email** | **Delivered status** | **Email with delivery timestamp** | ⬜ | HTML template with confirmation |
| **NEW: Cancel Order** | **Pending/Confirmed** | **Order cancelled** | ⬜ | Seller can cancel before processing |
| **NEW: Cancel Order** | **Processing/Shipped** | **BadRequest 400** | ⬜ | Cannot cancel if shipped |

---

## Wishlist Module

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| Get Wishlist | View saved items | Returns wishlist items | ⬜ | Existing endpoint |
| Add to Wishlist | Add product | Item added to wishlist | ⬜ | Existing endpoint |
| Remove from Wishlist | Delete item | Item removed | ⬜ | Existing endpoint |
| Move to Cart | Add to cart | Item moved from wishlist to cart | ⬜ | Existing endpoint |

---

## Address Module

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| Get Addresses | View all | Returns user's addresses | ⬜ | Existing endpoint |
| Add Address | New address | Address added, can set default | ⬜ | Existing endpoint |
| Update Address | Edit existing | Address updated | ⬜ | Existing endpoint |
| Delete Address | Remove address | Address deleted | ⬜ | Existing endpoint |
| Set Default | Mark as default | Only one default at a time | ⬜ | Existing endpoint |

---

## Seller Management Module

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| Seller Register | New seller | Account created, pending approval | ⬜ | Existing endpoint |
| Seller Profile | View details | Returns seller info | ⬜ | Existing endpoint |
| Seller Products | List products | Returns seller's products | ⬜ | Existing endpoint |
| Create Product | Add new product | Product created, pending approval | ⬜ | Existing endpoint |
| Update Product | Edit product | Product updated | ⬜ | Existing endpoint |
| Product Variants | Manage variants | Add/update colors, sizes, stock | ⬜ | Existing endpoint |
| **NEW: Dashboard** | **View analytics** | **Shows orders, revenue, trends** | ⬜ | Seller dashboard enhanced |

---

## Admin Module

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| Approve Seller | Admin action | Seller approved, can sell | ⬜ | Existing endpoint |
| Reject Seller | Admin action | Seller rejected, notified | ⬜ | Existing endpoint |
| Approve Product | Admin action | Product approved, visible | ⬜ | Existing endpoint |
| Reject Product | Admin action | Product rejected, seller notified | ⬜ | Existing endpoint |
| View All Users | Admin dashboard | Returns paginated users | ⬜ | Existing endpoint |
| Dashboard Stats | Admin view | Shows total orders, users, revenue | ⬜ | Existing endpoint |

---

## Email Notifications

| Feature | Scenario | Expected Result | Status | Notes |
|---------|----------|-----------------|--------|-------|
| Welcome Email | User registers | Email sent with account details | ⬜ | Existing |
| Order Confirmation | Order placed | Email sent with order details | ⬜ | Existing |
| **NEW: Status Change** | **Order confirmed** | **Email sent to buyer** | ⬜ | New: Confirmed template |
| **NEW: Status Change** | **Order processing** | **Email sent to buyer** | ⬜ | New: Processing template |
| **NEW: Status Change** | **Order shipped** | **Email sent with tracking** | ⬜ | New: Shipped template |
| **NEW: Status Change** | **Order delivered** | **Email sent with timestamp** | ⬜ | New: Delivered template |
| **NEW: Cancellation** | **Order cancelled** | **Email sent to buyer** | ⬜ | New: Cancellation template |
| Password Reset | Forgot password | Email with reset link | ⬜ | Existing |

---

## Frontend UI Components

| Component | Scenario | Expected Result | Status | Notes |
|-----------|----------|-----------------|--------|-------|
| **NEW: Cart Page** | **Payment methods** | **Only COD radio checked** | ⬜ | Test: CartPage.test.tsx |
| **NEW: Cart Page** | **Disabled buttons** | **UPI/CARD/NETBANKING disabled** | ⬜ | Test: CartPage.test.tsx |
| **NEW: Tooltip** | **Hover disabled** | **Shows informatory message** | ⬜ | Test: CartPage.test.tsx |
| **NEW: Stepper** | **Active step** | **Green text + border** | ⬜ | Test: Stepper.test.tsx |
| **NEW: Stepper** | **Completed steps** | **Clickable to navigate back** | ⬜ | Test: Stepper.test.tsx |
| **NEW: Stepper** | **Pending steps** | **Not clickable (disabled)** | ⬜ | Test: Stepper.test.tsx |
| Order List | View orders | Displays all orders with summary | ⬜ | Existing component |
| Order Detail | View order | Shows items, address, tracking | ⬜ | Existing component |
| **NEW: Seller Orders** | **Status dropdown** | **Shows all valid next statuses** | ⬜ | Test: SellerOrdersPage.test.tsx |
| **NEW: Cancel Modal** | **Cancel reason** | **Textarea for reason input** | ⬜ | Test: SellerOrdersPage.test.tsx |
| Checkout Stepper | Navigation | Allows moving between steps | ⬜ | Existing component |

---

## Database Layer

| Table | Change | Impact | Status | Notes |
|-------|--------|--------|--------|-------|
| Users | Added IsFirstLogin (BIT) | Default 1, tracks first login | ⬜ | Non-breaking, backwards compatible |
| Orders | No schema changes | Existing status enum extended | ⬜ | Status 6=Cancelled, 7=Returned now used |
| OrderItems | No changes | Still track items | ⬜ | No impact |
| OrderStatusHistory | New tracking | Records all status changes | ⬜ | Supports audit trail |

---

## Test Execution Tracking

### Phase 1: Unit Tests (38 tests)
- [ ] Run: `dotnet test` in api folder
- [ ] Expected: All 38 pass
- [ ] Time: ~30-45 seconds

### Phase 2: Frontend Tests (32 tests)
- [ ] Run: `npm test` in stopnshop-ui folder
- [ ] Expected: All 32 pass
- [ ] Time: ~20-30 seconds

### Phase 3: Integration Tests (5 tests)
- [ ] API running: `dotnet run` in api folder
- [ ] Run: `dotnet test --filter "Category=Integration"`
- [ ] Expected: All 5 pass (or skip if API not running)
- [ ] Time: ~60-90 seconds

### Phase 4: Manual Testing (20 minutes)
- [ ] Buyer flow: Register → Cart → Checkout → Order → Cancel
- [ ] Seller flow: Login → View orders → Update status → Email received
- [ ] Admin flow: Approve products/sellers
- [ ] Auth flow: OTP, password reset, profile update

---

## Rollback Criteria

**STOP and rollback if ANY of the following occur:**
1. ❌ More than 5 test failures in core functionality
2. ❌ Authentication/authorization broken
3. ❌ Order placement fails
4. ❌ Database migrations cannot be undone
5. ❌ Email system crashes server

**PROCEED with caution if:**
⚠️ 1-2 test failures in new features (may be test environment issues)
⚠️ Edge case failures not affecting main flow

---

## Sign-Off

| Role | Name | Date | Status |
|------|------|------|--------|
| Developer | - | - | ⬜ |
| QA Lead | - | - | ⬜ |
| Tech Lead | - | - | ⬜ |

---

## Notes
- Run full regression test suite before each release
- Update this matrix with results after each test run
- Keep test execution logs in test-results-* directories
- Review failures and create issues for bugs found
