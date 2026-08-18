# UI Overhaul Plan — Claude.ai-Inspired Hybrid

**Status:** Planned. Phase 0 not yet started.
**Branch:** `feat/ui-theme-system` (continue here) or split into `feat/ui-overhaul-phase-N` per phase.
**Owner decision (2026-05-18):** Hybrid palette — keep `#c41230` red as the *action* color (buttons, links, status), adopt Claude.ai cream surfaces / serif typography / generous whitespace for everything else. Plan runs phase-by-phase; each phase is one PR.

---

## Design direction

**Inspiration:** [claude.ai](https://claude.ai) — warm cream surfaces, serif headlines, soft rounded cards, generous breathing room, restrained motion.

**Kept from current design (per CLAUDE.md evaluation criteria #3):**
- `#c41230` red for primary actions (buttons, links, active states, badges)
- `#d4a017` gold as secondary accent (price highlights, premium tags)
- StopNShop wordmark and brand identity

**New from Claude.ai feel:**
- Surface background `#faf9f5` (warm cream) replacing flat `#ffffff` / `#f9fafb`
- Serif display font (Playfair Display, already loaded) used **more boldly** for page titles
- Larger default radius (`rounded-2xl` baseline, `rounded-3xl` for hero cards)
- Wider spacing scale (cards have more inner padding, sections more vertical breathing room)
- Refined neutral grays with a warm undertone (stone-ish, not pure gray)
- Subtle elevated shadows (soft, low-spread)
- No heavy borders — separation by surface tone difference, not 1px lines

**Dark mode:** Already wired via `ThemeProvider`. Each phase must preserve parity — every token has a dark counterpart.

---

## Token changes (Phase 0 reference)

Update [stopnshop-ui/src/styles/tokens.css](../stopnshop-ui/src/styles/tokens.css):

```css
:root {
  /* Surfaces — warmer */
  --color-bg: #faf9f5;                /* was #ffffff */
  --color-surface: #f5f1e8;           /* was #f9fafb */
  --color-surface-elevated: #ffffff;
  --color-surface-sunken: #efeadd;    /* NEW — for input fields, sunken panels */

  /* Text — warmer neutrals */
  --color-text: #1c1917;              /* warmer than #1f2937 */
  --color-text-muted: #57534e;
  --color-text-subtle: #a8a29e;

  /* Borders — softer */
  --color-border: #e7e5e0;
  --color-border-strong: #d6d3cc;

  /* Brand — UNCHANGED (red stays for actions) */
  --color-accent: #c41230;
  --color-accent-hover: #a10e27;
  --color-accent-soft: #fde8e8;
  --color-gold: #d4a017;

  /* Radius — larger defaults */
  --radius-sm: 0.5rem;    /* 8px */
  --radius-md: 0.75rem;   /* 12px */
  --radius-lg: 1rem;      /* 16px — was probably 0.75 */
  --radius-xl: 1.25rem;   /* 20px */
  --radius-2xl: 1.5rem;   /* 24px — NEW default for cards */
  --radius-3xl: 2rem;     /* 32px — hero cards */

  /* Shadows — soft + low */
  --shadow-sm: 0 1px 2px rgba(28, 25, 23, 0.04);
  --shadow-md: 0 4px 12px rgba(28, 25, 23, 0.06);
  --shadow-lg: 0 12px 32px rgba(28, 25, 23, 0.08);
}

.dark {
  --color-bg: #1c1917;
  --color-surface: #292524;
  --color-surface-elevated: #322e2c;
  --color-surface-sunken: #1a1715;
  --color-text: #f5f1e8;
  --color-text-muted: #a8a29e;
  --color-text-subtle: #78716c;
  --color-border: #44403c;
  --color-border-strong: #57534e;
  /* Brand stays the same — accent visibility maintained on dark */
}
```

Update [tailwind.config.ts](../stopnshop-ui/tailwind.config.ts) to expose new tokens (`surface-sunken`, `rounded-3xl`) so existing utility classes still work.

---

## Phasing

Each phase = one PR. Do not start phase N+1 before phase N is merged and visually verified in Docker.

### Phase 0 — Tokens & Tailwind config
**Files:** [tokens.css](../stopnshop-ui/src/styles/tokens.css), [tailwind.config.ts](../stopnshop-ui/tailwind.config.ts), [index.css](../stopnshop-ui/src/index.css)
**Acceptance:** App still renders identically to current (no component changes). Open every page, confirm no broken contrast, dark mode still works. Tokens are now ready for use.

### Phase 1 — Primitive components
**Files under [stopnshop-ui/src/components/ui/](../stopnshop-ui/src/components/ui/):**
- `Button.tsx` — variants: primary (red), secondary (cream), ghost, danger, gold; sizes sm/md/lg
- `Card.tsx` — default `rounded-2xl` with `surface-elevated` bg and `shadow-md`
- `Input.tsx` / `Textarea.tsx` / `Select.tsx` — `surface-sunken` bg, no harsh borders
- `Badge.tsx` — semantic variants (pending/confirmed/shipped/delivered/cancelled)
- `Modal.tsx` — softer backdrop, larger radius, more padding
- `EmptyState.tsx` — illustrated empty states (replace one-liner "No orders yet")
- `Skeleton.tsx` — loading placeholders for tables/cards (replace bare `<Spinner>`)
- `Table.tsx` — strip current bordered look, use surface-tone alternation

**Acceptance:** Components compile, vitest passes, used on at least one page each as smoke test.

### Phase 2 — Layouts / shells
**Files:**
- [SellerLayout.tsx](../stopnshop-ui/src/components/layout/SellerLayout.tsx) + [SellerSidebar.tsx](../stopnshop-ui/src/components/layout/SellerSidebar.tsx) + [SellerHeader.tsx](../stopnshop-ui/src/components/layout/SellerHeader.tsx)
- [AdminLayout.tsx](../stopnshop-ui/src/components/admin/AdminLayout.tsx)
- [MainLayout.tsx](../stopnshop-ui/src/components/layout/MainLayout.tsx) + [Header.tsx](../stopnshop-ui/src/components/layout/Header.tsx) + [Footer.tsx](../stopnshop-ui/src/components/layout/Footer.tsx)
- [AuthLayout.tsx](../stopnshop-ui/src/components/layout/AuthLayout.tsx)

**Changes:** Cream backgrounds. Sidebars become subtle (no harsh white-on-gray split). Headers get more vertical padding. Footer simplifies.

**Acceptance:** Every authenticated area visually consistent. Public storefront still looks branded but warmer.

### Phase 3 — Seller pages (8)
Files under [stopnshop-ui/src/features/seller/](../stopnshop-ui/src/features/seller/):
- SellerDashboardPage (replace placeholder chart area)
- SellerProductsPage, SellerAddProductPage, SellerEditProductPage
- SellerOrdersPage (already fixed for data; needs visual pass)
- SellerSettlementsPage, SellerSettlementDetailPage
- SellerBankAccountsPage, SellerWarehousesPage
- SellerProfilePage

**Acceptance:** Replace all hard-coded `bg-white`, `border-gray-100`, `rounded-xl` with the new primitives. Each page tested with real data in Docker.

### Phase 4 — Admin pages (10)
Files under [stopnshop-ui/src/features/admin/](../stopnshop-ui/src/features/admin/): Dashboard, Sellers, Products, Users, Orders, CMS, Coupons, Reviews, Audit + the existing [admin primitives](../stopnshop-ui/src/components/admin/) (`KpiCard`, `FilterBar`, `ConfirmDialog`).

**Acceptance:** Same checklist as Phase 3. KpiCard should look like a Claude.ai stat card (large number, serif label, subtle delta indicator).

### Phase 5 — Buyer account (8)
- [ProfilePage](../stopnshop-ui/src/features/account/ProfilePage.tsx)
- [AddressesPage](../stopnshop-ui/src/features/account/AddressesPage.tsx)
- [OrdersListPage](../stopnshop-ui/src/features/orders/OrdersListPage.tsx), [OrderDetailPage](../stopnshop-ui/src/features/orders/OrderDetailPage.tsx)
- [WalletPage](../stopnshop-ui/src/features/wallet/WalletPage.tsx)
- [NotificationPage](../stopnshop-ui/src/features/notifications/NotificationPage.tsx)
- [WishlistPage](../stopnshop-ui/src/features/wishlist/WishlistPage.tsx)
- [CartPage](../stopnshop-ui/src/features/cart/CartPage.tsx)

### Phase 6 — Public + Auth (6)
- [HomePage](../stopnshop-ui/src/features/home/HomePage.tsx) — hero gets full Claude.ai treatment (cream bg, serif headline, generous spacing)
- [CategoryPage](../stopnshop-ui/src/features/category/CategoryPage.tsx)
- [ProductListPage](../stopnshop-ui/src/features/products/ProductListPage.tsx) — filter sidebar simplified
- [ProductDetailPage](../stopnshop-ui/src/features/products/ProductDetailPage.tsx) — image gallery + buy box restyled
- [LoginPage](../stopnshop-ui/src/features/auth/LoginPage.tsx), [SignupPage](../stopnshop-ui/src/features/auth/SignupPage.tsx), [SellerLoginPage](../stopnshop-ui/src/features/seller/SellerLoginPage.tsx), [SellerSignupPage](../stopnshop-ui/src/features/seller/SellerSignupPage.tsx), [SellerOnboardingPage](../stopnshop-ui/src/features/seller/SellerOnboardingPage.tsx)

**Note:** Public pages are most visible to evaluators — give these the most attention.

### Phase 7 — Cleanup & docs
- Grep for orphan `bg-white`, `bg-gray-50`, `border-gray-100` — anywhere primitives weren't used
- Audit dark mode parity on every page (toggle theme, walk through)
- Update [DESIGN_SYSTEM.md](../stopnshop-ui/docs/DESIGN_SYSTEM.md) with new tokens, primitives, do/don't examples
- Update [CLAUDE.md UI section](../CLAUDE.md) to reflect hybrid palette decision
- Remove ProductDetailPage-* / ProductCard-* legacy CSS if any
- Confirm `npm run build` bundle size hasn't ballooned

---

## How to resume in a future session

Tell Claude:
> /loop is not needed — run **Phase N** of [docs/UI_OVERHAUL_PLAN.md](docs/UI_OVERHAUL_PLAN.md).

Or invoke each phase as its own command, e.g.:
> Execute Phase 0 of UI_OVERHAUL_PLAN.md, commit, push, open PR.

Each phase entry above is self-contained: file list + acceptance criteria. Claude can read this plan + the current state and proceed without re-deriving the design direction.

---

## Open questions to revisit later

1. **Charting library** — Phase 3 calls for replacing the SellerDashboard placeholder. Pick Recharts (already in bundle via Recharts AreaChart at 346KB) or migrate to a lighter alternative?
2. **Illustrations for EmptyState** — use lucide icons (free, in bundle) or commission/source flat illustrations?
3. **Animation library** — Claude.ai uses subtle motion (fades, slides). Adopt Framer Motion or stick with CSS transitions?
4. **Mobile breakpoint pass** — the plan above assumes desktop-first. A separate Phase 8 may be needed for mobile-specific tweaks (sidebars → drawers, table → cards).

Decide these inline as each phase comes up, or call out before Phase 0.
