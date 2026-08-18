# StopNShop — Complete Operational Framework

**Established:** 2026-05-16 (Phase 0)
**Commit:** b1cc500
**Status:** Ready for Phase 1 implementation

---

## THE FRAMEWORK AT A GLANCE

```
ANY FEATURE REQUEST
        ↓
SKILL: identify-feature-scope
    (map all affected screens, endpoints, SPs)
        ↓
RULE F: Feature Branch Workflow
    (git fetch main → create feature/* branch)
        ↓
MAKE CHANGES (using specific skills)
    ├─ SKILL: add-sp (if new DB needed)
    ├─ SKILL: add-endpoint (if new API needed)
    ├─ SKILL: add-screen (if new UI needed)
    └─ SKILL: fix-bug (if fixing issue)
        ↓
SKILL: run-tests (for each change)
        ↓
SKILL: commit-with-tests (3-layer format)
        ↓
UPDATE SCREEN_MAP.md
        ↓
CREATE PULL REQUEST
```

---

## GOLDEN RULES

### Rule A: Bug Fix Protocol
**Before touching any file, ask 5 questions:**
1. Which screen/page is broken? (exact route)
2. What is the exact symptom? (error, wrong data, UI broken)
3. What action triggered it? (button click, form submit, page load)
4. Which role? (Customer/Seller/Admin/all)
5. When did it last work? (after which commit)

**Do NOT read files until all 5 are answered** (unless user says "I have no idea")

### Rule B: Modification Protocol
1. User says: "Change X on [ScreenName]"
2. I look up `docs/SCREEN_MAP.md` for that screen
3. I read ONLY the files listed (UI + API + SP)
4. Make the change
5. Test old payload + new payload
6. Commit with 3-layer format

**Zero exploratory reads. No unrelated files.**

### Rule C: Regression Protection
Before ANY change:
- Identify existing working flow
- Record exact request/response payload
- Make the change
- Verify old payload still returns same response
- Verify new payload works correctly
- **THEN commit**

**An existing working feature MUST NOT break. Ever.**

### Rule D: File Reading Authorization
| Scenario | Can Read |
|---|---|
| Bug fix with all 5 answers | Only files in SCREEN_MAP for that screen |
| New feature on known screen | Files in SCREEN_MAP + new files being created |
| Architecture-level change | Only with explicit user authorization |
| "I have no idea" from user | Explore SCREEN_MAP first, then targeted reads only |
| Code review | Only files user explicitly lists |

### Rule E: Commit Gate
Commit ONLY when:
- ✅ Positive flow tested (happy path works)
- ✅ Negative flow tested (errors handled)
- ✅ Regression tested (old payload unchanged)
- ✅ No scratch files in `git status --short`
- ✅ All three layers in commit message

### Rule F: Feature Branch Workflow
```bash
# Step 1: Get latest main
git fetch origin main
git checkout main
git pull origin main

# Step 2: Create feature branch
git checkout -b feature/feature-name
# Examples:
# - feature/add-loyalty-system
# - bugfix/cart-total-not-updating
# - enhancement/improve-search

# Step 3: Identify scope (SKILL: identify-feature-scope)
# Document all affected screens, endpoints, SPs

# Step 4: Implement (using specific skills)
# Each commit follows 3-layer format

# Step 5: Push & Create PR
git push origin feature/feature-name
```

---

## REFERENCE: SCREEN_MAP

**49 Screens fully mapped to endpoints and SPs:**

| Category | Count | Screens |
|---|---|---|
| Public | 10 | HomePage, SearchPage, LoginPage, SignupPage, ProductListPage, ProductDetailPage, CategoryPage, BrandPage, ForgotPasswordPage, OffersPage |
| Customer | 13 | AccountDashboard, ProfilePage, AddressesPage, OrdersListPage, OrderDetailPage, CartPage, WishlistPage, LoyaltyPage, ReturnsListPage, ReturnDetailPage, NotificationPage, WalletPage, NotFoundPage |
| Seller | 12 | SellerOnboardingWizard, SellerDashboardPage, SellerProductsPage, SellerAddProductPage, SellerEditProductPage, SellerInventoryPage, SellerOrdersPage, SellerOrderDetailPage, SellerAnalyticsPage, SellerPayoutsPage, SellerProfilePage, SellerLoginPage, SellerSignupPage |
| Admin | 15 | AdminDashboard, AdminUsersPage, AdminSellersPage, AdminSellerDetailPage, AdminProductsPage, AdminProductDetailPage, AdminOrdersPage, AdminOrderDetailPage, AdminReturnsPage, AdminPromotionsPage, AdminFinancePage, AdminCMSPage, AdminAuditLogsPage, AdminSettingsPage, AdminAnalyticsPage |

**For each screen, SCREEN_MAP documents:**
- Route & guard
- UI file path
- API files (Controller/Service/Repository)
- All endpoints (method, route, parameters)
- All SPs (name, parameters)
- React Query keys
- Validations

---

## 8 REPEATABLE SKILLS

| Skill | Use When |
|---|---|
| **identify-feature-scope** | Any new feature → map all affected screens/endpoints/SPs |
| **fix-bug** | Bug reported → 10-step protocol with regression baseline |
| **add-screen** | New page needed → 7-step full 3-layer implementation |
| **add-endpoint** | New API endpoint needed → 12-step with validator + test |
| **add-sp** | New stored procedure needed → 9-step with SSDT rules |
| **run-tests** | After any change → positive + negative + regression testing |
| **commit-with-tests** | Before committing → gate that requires all tests pass |
| **update-screen-map** | Endpoints/SPs change → keep SCREEN_MAP in sync |

---

## 3-LAYER COMMIT MESSAGE FORMAT

```
type: brief description (50 chars max)

- Changed UI: [which files, what changed]
- Changed API: [which endpoints, what changed]
- Changed DB: [which SPs/tables, what changed]

Reason: [why this change was needed]

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
```

**Example:**
```
feat: add loyalty points earning to order confirmation

- Changed UI: OrderDetailPage.tsx shows "You earned X points" badge, LoyaltyPage.tsx refetches transactions
- Changed API: CartOrderService.PlaceOrderAsync calls LoyaltyService.EarnPoints after order insert
- Changed DB: created usp_Loyalty_Points_Earn to calculate points based on order amount and tier

Reason: Enable customers to see loyalty points earned immediately upon order placement

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
```

---

## COMPLETE WORKFLOW EXAMPLE: Add Loyalty Points Feature

### Step 1: User says "I want customers to earn loyalty points on orders"

### Step 2: I run SKILL: identify-feature-scope
```
ANALYSIS:

Affected Screens:
- CartPage (/cart) — show "You'll earn X points" during checkout
- OrderDetailPage (/orders/:id) — show "You earned X points" after order
- LoyaltyPage (/loyalty) — show new transaction in history
- AdminDashboardPage (/admin) — KPI: total points distributed

New Endpoints:
- POST /api/loyalty/earn (implicit via order placement)

New SPs:
- usp_Loyalty_Points_Earn(@UserId, @OrderId, @OrderAmount, @TierMultiplier)

New Tables:
- None (use existing LoyaltyAccounts, LoyaltyTransactions)

Complexity: MEDIUM (4 screens, 1 SP, 0 new endpoints, 0 new tables)

Ready? [Y/N]
```

### Step 3: User approves, I run RULE F
```bash
git fetch origin main
git checkout main
git pull origin main
git checkout -b feature/loyalty-points-earning
```

### Step 4: I implement using specific skills
- SKILL: add-sp → Create `usp_Loyalty_Points_Earn`
- SKILL: modify-service → Update `CartOrderService.PlaceOrderAsync`
- SKILL: modify-ui → Update `CartPage.tsx`, `OrderDetailPage.tsx`, `LoyaltyPage.tsx`
- SKILL: update-screen-map → Document changes

### Step 5: I test with SKILL: run-tests
```
CartPage:
✅ Positive: Display "You'll earn 250 points" for ₹2500 order
✅ Negative: Missing order amount → validation error
✅ Regression: Old checkout flow without points still works

OrderDetailPage:
✅ Positive: Display "You earned 250 points" badge
✅ Negative: User not authenticated → 401
✅ Regression: Order details still display correctly

LoyaltyPage:
✅ Positive: New transaction "Earned 250 points" appears in history
✅ Regression: Other transactions still display
```

### Step 6: I commit with SKILL: commit-with-tests
```bash
git commit -m "feat: add loyalty points earning on order placement

- Changed UI: CartPage.tsx displays estimated points during checkout, OrderDetailPage.tsx shows earned points badge, LoyaltyPage.tsx auto-refreshes to show new earning transaction
- Changed API: CartOrderService.PlaceOrderAsync calls LoyaltyService.EarnPoints after successful order insert, points calculated based on order amount × customer tier multiplier
- Changed DB: created usp_Loyalty_Points_Earn SP that inserts transaction record and updates LoyaltyAccounts balance

Reason: Complete loyalty loop by enabling customers to see points earned immediately upon order confirmation, increasing engagement and repeat purchase motivation

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>"
```

### Step 7: I update SCREEN_MAP
Update entries for CartPage, OrderDetailPage, LoyaltyPage with new endpoints and RQ keys

### Step 8: PR ready to merge to main

---

## KEY METRICS

✅ **Zero missed endpoints** — SCREEN_MAP is comprehensive, identify-feature-scope ensures completeness
✅ **Zero regressions** — Regression testing mandatory before every commit
✅ **Clear accountability** — 3-layer commits document exactly what changed where
✅ **Repeatable processes** — 8 skills for all common scenarios
✅ **Fast iteration** — Feature branching allows parallel work
✅ **High quality** — Tests as gate, not optional

---

## NEXT: PHASE 1 — FOUNDATION (Design System & AI Agent)

When you're ready:
```bash
git checkout feature/phase-1-foundation
# Implement design system, theme toggle, Zustand store, Framer Motion, AI Agent Drawer, Command Palette
# 3 hours, all using established skills
```

**Status:** ✅ Framework established, ready to build
