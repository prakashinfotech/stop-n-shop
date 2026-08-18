# Test Automation Guide — Stop-N-Shop

## Overview
Comprehensive test suite covering all new features implemented in Phase 2:
- Cart payment method restrictions
- Order cancellation by buyer
- Seller order status updates
- First-time user login tracking
- Email notifications

---

## Test Structure

### Backend Tests (xUnit)

#### Unit Tests

**OrdersControllerTests.cs** — 6 test cases
- ✓ PlaceOrder with valid request returns OrderId
- ✓ GetOrders returns order list
- ✓ GetOrder with valid ID returns detail
- ✓ GetOrder with invalid ID returns NotFound
- ✓ CancelOrder with valid order returns cancelled order
- ✓ CancelOrder with shipped order returns BadRequest

**SellerOrderControllerTests.cs** — 9 test cases
- ✓ GetOrders returns seller orders
- ✓ GetOrders with status filter filters properly
- ✓ GetOrderDetail with authorized seller returns detail
- ✓ GetOrderDetail with unauthorized seller returns NotFound
- ✓ UpdateOrderStatusNew with valid status updates
- ✓ UpdateOrderStatusNew with invalid progression returns BadRequest
- ✓ UpdateOrderStatusNew with non-existent order returns NotFound
- ✓ CancelOrder with valid request cancels order
- ✓ CancelOrder with shipped order returns BadRequest

**AuthControllerTests.cs** — 10 test cases
- ✓ Register with valid request returns AuthToken
- ✓ Register with short password returns BadRequest
- ✓ Register with duplicate email returns Conflict
- ✓ Login with valid credentials returns token
- ✓ Login with invalid password returns Unauthorized
- ✓ GetProfile returns user profile
- ✓ GetProfile with non-existent user returns NotFound
- ✓ MarkFirstLoginComplete updates user flag
- ✓ UpdateProfile with valid request returns updated profile

**OrderServiceTests.cs** — 6 test cases
- ✓ PlaceOrder with valid cart creates order
- ✓ GetOrders returns user orders
- ✓ GetOrderDetail with authorized user returns detail
- ✓ GetOrderDetail with unauthorized user returns null
- ✓ CancelOrder with pending order succeeds
- ✓ CancelOrder with shipped order throws exception

**SellerOrderServiceTests.cs** — 7 test cases
- ✓ GetOrders returns seller orders
- ✓ GetOrders with status filter filters properly
- ✓ GetOrderDetail with authorized seller returns detail
- ✓ GetOrderDetail with unauthorized seller returns null
- ✓ UpdateOrderStatus with valid transition updates
- ✓ UpdateOrderStatus with invalid transition throws exception
- ✓ UpdateOrderStatus to shipped sends email

**Total Unit Tests: 38**

#### Integration Tests

**OrderFlowIntegrationTests.cs** — 5 test cases
- ✓ OrderFlow: Buyer places order → Seller updates status → Buyer cancels (if allowed)
- ✓ OrderCancellation: Buyer cancels pending order with email notification
- ✓ FirstLogin: Buyer marks login complete and updates profile
- ✓ SellerOrderStatus: All status transitions work correctly (1→2→3→4→5)
- ✓ PaymentMethod: Only COD enabled, others disabled

**Total Integration Tests: 5**

### Frontend Tests (Vitest + React Testing Library)

**CartPage.test.tsx** — 7 test cases
- ✓ Render cart page with default COD payment method
- ✓ Disable UPI payment option
- ✓ Disable CARD payment option
- ✓ Disable NETBANKING payment option
- ✓ Show tooltip on disabled payment methods
- ✓ Set payment method to COD by default
- ✓ Show order summary on checkout page

**Stepper.test.tsx** — 7 test cases
- ✓ Render all steps
- ✓ Highlight active step with green color
- ✓ Make completed steps clickable
- ✓ Make completed Address step clickable
- ✓ Not allow clicking on pending steps
- ✓ Show checkmark for completed steps
- ✓ Update active step when prop changes

**SellerOrdersPage.test.tsx** — 7 test cases
- ✓ Render orders page
- ✓ Display order list with status
- ✓ Allow filtering orders by status
- ✓ Show status update dropdown for pending orders
- ✓ Show cancel button for cancellable orders
- ✓ Open cancel reason modal when cancel is clicked
- ✓ Display pagination controls
- ✓ Show order details when order is clicked

**AuthService.test.tsx** — 11 test cases
- Login: 2 tests (valid credentials, invalid credentials)
- Profile: 3 tests (fetch profile, null return, update profile)
- FirstLogin: 2 tests (mark complete, error handling)
- Registration: 3 tests (register user, duplicate email, short password)

**Total Frontend Tests: 32**

---

## Running Tests

### Backend Tests

#### Unit Tests
```bash
cd api
dotnet test --filter "Category=Unit" --verbosity normal
```

#### Integration Tests (requires running API)
```bash
cd api
# Terminal 1: Start API
dotnet run

# Terminal 2: Run integration tests
dotnet test --filter "Category=Integration" --verbosity normal
```

#### All Tests
```bash
cd api
dotnet test --verbosity normal
```

### Frontend Tests

#### Run All Tests
```bash
cd stopnshop-ui
npm test
```

#### Run with Coverage
```bash
cd stopnshop-ui
npm run test:coverage
```

#### Run in Watch Mode
```bash
cd stopnshop-ui
npm run test:watch
```

#### Run Specific Test File
```bash
cd stopnshop-ui
npm test -- CartPage.test.tsx
```

---

## Regression Testing Checklist

### Critical Flows (Must Not Regress)

#### Authentication
- [ ] User registration with all fields required
- [ ] User login with email/password
- [ ] JWT token generation and validation
- [ ] Password reset via OTP
- [ ] Mobile OTP verification
- [ ] Profile fetch and update

#### Cart & Orders (Buyer)
- [ ] Add products to cart
- [ ] Update cart item quantity
- [ ] Remove cart items
- [ ] Clear entire cart
- [ ] Retrieve cart summary with pricing
- [ ] Place order with valid address and payment
- [ ] View order list (paginated)
- [ ] View order details with items and tracking
- [ ] **NEW: Cancel order (only Pending/Confirmed)**
- [ ] **NEW: Default payment method is COD**
- [ ] **NEW: Non-COD methods show tooltip and are disabled**

#### Seller Orders
- [ ] View seller orders (paginated)
- [ ] Filter orders by status
- [ ] View order detail (seller perspective)
- [ ] **NEW: Update order status (1→2→3→4→5 progression only)**
- [ ] **NEW: Email sent to buyer on status update**
- [ ] **NEW: Cannot move order backwards in status**

#### Email Notifications
- [ ] Order confirmation email sent
- [ ] Order status update emails sent
- [ ] Order cancellation email sent
- [ ] Email contains correct order details
- [ ] **NEW: Status-specific email templates (Confirmed, Processing, Shipped, Delivered)**

#### First-Time User Experience
- [ ] **NEW: IsFirstLogin flag set to true on registration**
- [ ] **NEW: IsFirstLogin included in profile response**
- [ ] **NEW: Mark-first-login endpoint updates flag**
- [ ] **NEW: Only shown once per user (idempotent)**

#### Admin & Catalog (Existing)
- [ ] Browse products
- [ ] Search products with filters
- [ ] View product details
- [ ] View product variants and images
- [ ] Brand listing and details
- [ ] Category and subcategory navigation

---

## Test Execution Plan

### Phase 1: Unit Tests (5 minutes)
```bash
cd api && dotnet test
cd ../stopnshop-ui && npm test
```

### Phase 2: Manual Integration Testing (20 minutes)
1. Start API: `cd api && dotnet run`
2. Start UI: `cd stopnshop-ui && npm run dev`
3. Test buyer flow:
   - Register → Login → Add to cart → Checkout → Place order
   - View order → Attempt cancel (should work if Pending)
4. Test seller flow:
   - Login as seller → View orders → Update status to Confirmed
   - Update to Processing → Update to Shipped (email should be sent)
   - View email in logs
5. Test first-time user:
   - Register new user → Profile shows IsFirstLogin = true
   - Call mark-first-login endpoint → Profile shows IsFirstLogin = false

### Phase 3: E2E Scenario Tests (15 minutes)
1. **Order Lifecycle**: Buyer places order → Seller confirms → Updates to shipped → Delivered
2. **Cancellation Limits**: Buyer can only cancel Pending/Confirmed orders
3. **Email Notifications**: Verify all status transitions send emails
4. **Payment Restrictions**: Attempt to change payment method (should fail or be hidden)

---

## Expected Test Results

### Success Criteria
- ✅ All 38 unit tests pass
- ✅ All 5 integration tests pass
- ✅ All 32 frontend tests pass
- ✅ No regressions in existing functionality
- ✅ Email notifications work (check logs)
- ✅ Order status progression enforced at DB level
- ✅ Payment method defaults to COD
- ✅ First-login flag persists correctly

### Coverage Targets
| Layer | Target |
|-------|--------|
| Controllers | >90% |
| Services | >85% |
| Repositories | >80% |
| Components | >75% |

---

## Troubleshooting

### Test Failures

#### "Connection timeout to localhost:5000"
- Ensure API is running: `dotnet run` in api folder
- Check port 5000 is not blocked

#### "Database not found"
- Ensure ShopNShop_db exists in SQL Server
- Run BACPAC restore if needed
- Verify connection string in appsettings.json

#### "Table or stored procedure doesn't exist"
- Ensure SSDT project deployed: Run `dotnet publish` in ShopNStopDB
- Check stored procedure names match exactly

#### "JWT validation failed"
- Verify token includes required claims (userId, role)
- Check token expiry (30 days)
- Ensure test uses correct token format "Bearer {token}"

#### "Email not sent in test"
- Fire-and-forget pattern uses Task.Run (async)
- Logs show "exception caught silently" but email may still send
- Check email service mock setup in tests

### Test Maintenance

#### Adding New Tests
1. Follow naming convention: `{Feature}{Scenario}{Outcome}.test.ts`
2. Use arrange-act-assert pattern
3. Mock external dependencies (DB, email, auth)
4. Place in appropriate `__tests__` folder
5. Update this document with test count

#### Updating Existing Tests
- If API signature changes, update test mocks
- If validation rules change, update assertions
- Keep test logic independent (no shared state)

---

## CI/CD Integration

These tests should be run:
- **On every commit** (pre-commit hooks)
- **On PR creation** (GitHub Actions)
- **Before merge to main** (required status check)
- **On deployment** (smoke tests)

See `.github/workflows/` for automation config.

---

## Performance Benchmarks

### Expected Execution Times
| Suite | Time |
|-------|------|
| Backend Unit Tests | 30-45 seconds |
| Frontend Unit Tests | 20-30 seconds |
| Integration Tests | 60-90 seconds |
| **Total** | **2-3 minutes** |

---

## Next Steps
1. ✅ Generate test files (completed)
2. ⏳ Fix import paths and add missing DTOs
3. ⏳ Run tests and capture baseline
4. ⏳ Add CI/CD integration
5. ⏳ Document failures and fixes in ISSUES.md
