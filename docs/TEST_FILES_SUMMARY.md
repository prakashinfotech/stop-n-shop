# Test Files Summary — Stop-N-Shop

Generated test automation suite for Phase 2 (Cart, Orders, Seller Management, First-Time User).

---

## Test Files Created

### Backend Tests (C# / xUnit)

#### Controllers Tests
```
api/Tests/Controllers/
├── OrdersControllerTests.cs         [6 tests]
├── SellerOrderControllerTests.cs    [9 tests]
└── AuthControllerTests.cs           [10 tests]
```

**Total: 25 controller tests**

#### Services Tests
```
api/Tests/Services/
├── OrderServiceTests.cs             [6 tests]
└── SellerOrderServiceTests.cs       [7 tests]
```

**Total: 13 service tests**

#### Integration Tests
```
api/Tests/Integration/
└── OrderFlowIntegrationTests.cs     [5 tests]
```

**Total: 5 integration tests**

### Frontend Tests (TypeScript / Vitest)

#### Feature Components
```
stopnshop-ui/src/features/
├── cart/__tests__/
│   └── CartPage.test.tsx             [7 tests]
├── seller/__tests__/
│   └── SellerOrdersPage.test.tsx     [8 tests]
└── auth/__tests__/
    └── AuthService.test.tsx          [11 tests]
```

#### UI Components
```
stopnshop-ui/src/components/ui/__tests__/
└── Stepper.test.tsx                  [7 tests]
```

**Total: 33 frontend tests**

---

## Complete Test Count Summary

| Layer | Category | Count |
|-------|----------|-------|
| Backend | Controllers | 25 |
| Backend | Services | 13 |
| Backend | Integration | 5 |
| Frontend | Components | 33 |
| **TOTAL** | **ALL** | **76** |

---

## Quick Start

### 1. Run All Tests
```bash
# Linux/Mac
./run_tests.sh all

# Windows
.\run_tests.ps1 -TestType all
```

### 2. Run Backend Tests Only
```bash
# Linux/Mac
./run_tests.sh backend

# Windows
.\run_tests.ps1 -TestType backend

# Or directly
cd api && dotnet test
```

### 3. Run Frontend Tests Only
```bash
# Linux/Mac
./run_tests.sh frontend

# Windows
.\run_tests.ps1 -TestType frontend

# Or directly
cd stopnshop-ui && npm test
```

### 4. Run with Coverage
```bash
# Linux/Mac
./run_tests.sh frontend --coverage

# Windows
.\run_tests.ps1 -TestType frontend -Coverage
```

---

## Test Descriptions

### Backend Tests (C#)

#### OrdersControllerTests.cs
Tests the buyer order operations controller.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| PlaceOrder_WithValidRequest_ReturnsOrderId | Place order with valid data | Order creation endpoint |
| GetOrders_ReturnsOrderList | Retrieve buyer's orders | Order listing for buyer |
| GetOrder_WithValidId_ReturnsOrderDetail | Get specific order | Order detail retrieval |
| GetOrder_WithInvalidId_ReturnsNotFound | Invalid order ID | 404 handling |
| CancelOrder_WithValidOrder_ReturnsCancelledOrder | **NEW** Cancel pending order | Order cancellation logic |
| CancelOrder_WithShippedOrder_ReturnsBadRequest | **NEW** Prevent cancel of shipped | Business rule enforcement |

#### SellerOrderControllerTests.cs
Tests the seller order management controller.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| GetOrders_ReturnsSellerOrders | View seller's orders | Order retrieval for seller |
| GetOrders_WithStatusFilter_ReturnsPendingOrders | Filter by status | Status filtering |
| GetOrderDetail_WithValidOrder_ReturnsDetail | Get order details | Seller order detail view |
| GetOrderDetail_WithUnauthorizedOrder_ReturnsNotFound | Unauthorized access | Authorization checks |
| UpdateOrderStatusNew_WithValidStatus_UpdatesOrder | **NEW** Update to confirmed | Status transition logic |
| UpdateOrderStatusNew_WithInvalidProgression_ReturnsBadRequest | **NEW** Prevent backward status | State machine validation |
| UpdateOrderStatusNew_WithNonExistentOrder_ReturnsNotFound | Invalid order ID | Error handling |
| CancelOrder_WithValidRequest_CancelsOrder | **NEW** Cancel order + email | Order cancellation + notification |
| CancelOrder_WithShippedOrder_ReturnsBadRequest | **NEW** Prevent cancel shipped | Business rule enforcement |

#### AuthControllerTests.cs
Tests authentication and profile endpoints.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| Register_WithValidRequest_ReturnsAuthToken | New user registration | Registration flow |
| Register_WithShortPassword_ReturnsBadRequest | Password validation | Password length requirement |
| Register_WithDuplicateEmail_ReturnsConflict | Duplicate email prevention | Email uniqueness |
| Login_WithValidCredentials_ReturnsToken | User login | Authentication logic |
| Login_WithInvalidPassword_ReturnsUnauthorized | Wrong password | Failed auth handling |
| GetProfile_ReturnsUserProfile | Fetch profile | Profile retrieval |
| GetProfile_WithNonExistentUser_ReturnsNotFound | Invalid user ID | User validation |
| MarkFirstLoginComplete_UpdatesUserFlag | **NEW** Mark first login done | IsFirstLogin flag update |
| UpdateProfile_WithValidRequest_ReturnsUpdatedProfile | Update user details | Profile modification |

#### OrderServiceTests.cs
Tests the order service business logic.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| PlaceOrder_WithValidCart_CreatesOrder | Order creation | Service layer logic |
| GetOrders_ReturnsUserOrders | Retrieve orders | Order retrieval |
| GetOrderDetail_WithAuthorizedUser_ReturnsDetail | Get order detail | Detail retrieval |
| GetOrderDetail_WithUnauthorizedUser_ReturnsNull | Unauthorized access | Authorization |
| CancelOrder_WithPendingOrder_Succeeds | **NEW** Cancel order | Cancellation logic |
| CancelOrder_WithShippedOrder_ThrowsException | **NEW** Prevent shipped cancel | Business rule |

#### SellerOrderServiceTests.cs
Tests the seller order service business logic.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| GetOrders_ReturnsSellerOrders | Retrieve seller orders | Service logic |
| GetOrders_WithStatusFilter_FiltersProperly | Filter by status | Filtering logic |
| GetOrderDetail_WithAuthorizedSeller_ReturnsDetail | Get order detail | Authorization |
| GetOrderDetail_WithUnauthorizedSeller_ReturnsNull | Unauthorized seller | Authorization |
| UpdateOrderStatus_WithValidTransition_Updates | **NEW** Update status | Status transition |
| UpdateOrderStatus_WithInvalidTransition_ThrowsException | **NEW** Prevent invalid transition | State machine |
| UpdateOrderStatus_ToShipped_SendsEmail | **NEW** Send email on ship | Email notification |

#### OrderFlowIntegrationTests.cs
End-to-end integration tests across services.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| OrderFlow_BuyerPlacesOrder_SellerUpdatesStatus_BuyerCancels | **NEW** Complete order flow | Full order lifecycle |
| OrderCancellation_BuyerCancelsPendingOrder_SuccessfulWithEmail | **NEW** Cancel with email | Cancellation + notification |
| FirstLogin_BuyerMarksLoginComplete_UpdatesProfile | **NEW** First login flow | IsFirstLogin feature |
| SellerOrderStatus_AllStatusTransitions_WorkCorrectly | **NEW** Status progression | State machine enforcement |
| PaymentMethod_OnlyCODEnabled_OthersDisabled | **NEW** Payment restrictions | COD-only enforcement |

### Frontend Tests (TypeScript/React)

#### CartPage.test.tsx
Tests the shopping cart checkout page.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| should render cart page with default COD payment method | **NEW** Page render | Initial state |
| should disable UPI payment option | **NEW** UPI disabled | Payment restriction |
| should disable CARD payment option | **NEW** CARD disabled | Payment restriction |
| should disable NETBANKING payment option | **NEW** NETBANKING disabled | Payment restriction |
| should show tooltip on disabled payment methods | **NEW** Tooltip display | User feedback |
| should set payment method to COD by default | **NEW** Default selection | State management |
| should show order summary on checkout page | Existing feature | Layout |

#### Stepper.test.tsx
Tests the checkout stepper navigation component.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| should render all steps | **NEW** Render | Component output |
| should highlight active step with green color | **NEW** Styling | Active state styling |
| should make completed steps clickable | **NEW** Navigation | Backward navigation |
| should make completed Address step clickable | **NEW** Navigation | Step navigation |
| should not allow clicking on pending steps | **NEW** Prevent forward | Step progression rules |
| should show checkmark for completed steps | **NEW** Visual indicator | Completion status |
| should update active step when activeStep prop changes | **NEW** Props update | React updates |

#### SellerOrdersPage.test.tsx
Tests the seller orders management page.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| should render orders page | **NEW** Render | Page display |
| should display order list with status | **NEW** Order list | Data rendering |
| should allow filtering orders by status | **NEW** Filtering | Filter functionality |
| should show status update dropdown for pending orders | **NEW** Status UI | Status controls |
| should show cancel button for cancellable orders | **NEW** Cancel UI | Cancel controls |
| should open cancel reason modal when cancel is clicked | **NEW** Modal | Modal interaction |
| should display pagination controls | Existing | Pagination |
| should show order details when order is clicked | **NEW** Detail view | Navigation |

#### AuthService.test.tsx
Tests authentication API calls and services.

| Test Name | Scenario | Validates |
|-----------|----------|-----------|
| should login user with valid credentials | Login | Auth flow |
| should reject invalid credentials | Login error | Error handling |
| should fetch user profile | Profile | Profile retrieval |
| should return null when user not found | Profile error | Error handling |
| should update user profile | Profile update | Update logic |
| should mark first login as complete | **NEW** First login | IsFirstLogin update |
| should handle error when marking first login | **NEW** Error handling | Error management |
| should register new user | Registration | Registration flow |
| should reject duplicate email | Registration error | Validation |
| should reject short password | Registration error | Validation |

---

## File Locations Reference

### Backend Test File Paths
```
api/Tests/
├── Controllers/
│   ├── OrdersControllerTests.cs
│   ├── SellerOrderControllerTests.cs
│   └── AuthControllerTests.cs
├── Services/
│   ├── OrderServiceTests.cs
│   └── SellerOrderServiceTests.cs
└── Integration/
    └── OrderFlowIntegrationTests.cs
```

### Frontend Test File Paths
```
stopnshop-ui/src/
├── features/
│   ├── cart/__tests__/CartPage.test.tsx
│   ├── seller/__tests__/SellerOrdersPage.test.tsx
│   └── auth/__tests__/AuthService.test.tsx
└── components/ui/__tests__/
    └── Stepper.test.tsx
```

---

## Test Execution Results Log

After running tests, results are saved to `test-results-YYYYMMDD_HHMMSS/` with:
- `backend-unit.log` — Backend unit test output
- `backend-integration.log` — Integration test output
- `frontend-tests.log` — Frontend test output
- `TEST_REPORT.md` — Summary report
- `*.trx` files — TRX format reports (for CI/CD)

---

## Dependencies Required

### Backend
- .NET 8 SDK
- xUnit NuGet packages
- Moq for mocking

### Frontend
- Node.js 18+
- npm or yarn
- Vitest
- @testing-library/react
- @testing-library/user-event

Install with: `npm install` in stopnshop-ui folder

---

## Next Steps

1. ✅ Test files created
2. ⏳ Fix import paths (add missing using statements)
3. ⏳ Ensure all mock DTOs are available
4. ⏳ Run test suite and capture baseline
5. ⏳ Document any failures
6. ⏳ Integrate into CI/CD pipeline

---

## Test Maintenance

- Update tests when API contracts change
- Keep mocks aligned with actual implementations
- Add new tests for bug fixes (regression prevention)
- Remove obsolete tests when features are removed
- Update this document with test count changes
