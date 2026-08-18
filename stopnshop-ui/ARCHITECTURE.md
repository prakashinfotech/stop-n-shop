# Frontend Architecture — StopNShop UI

## Stack
- **Framework:** React 18 + Vite + TypeScript
- **Styling:** TailwindCSS (design tokens in `docs/DESIGN_SYSTEM.md`)
- **Data fetching:** React Query v5 (`@tanstack/react-query`)
- **HTTP client:** Axios via `src/api/axiosInstance.ts` (proxy → `http://localhost:5000`)
- **Routing:** React Router v6 (`src/router/AppRouter.tsx`)
- **Port:** `http://localhost:3000` (Vite dev server)
- **Proxy:** `/api` → `http://localhost:5000` (configured in `vite.config.ts`)

## Directory Map
```
src/
├── api/               ← Axios API modules (one file per domain)
├── components/        ← Shared UI components (layout, ui, auth, cart, forms)
├── context/           ← React contexts (AuthContext.tsx)
├── features/          ← Page-level feature modules (co-located page + logic)
├── hooks/             ← Custom hooks (useCart, useWishlist, useOtpTimer, usePincode)
├── router/            ← AppRouter.tsx — single source of truth for all routes
├── types/             ← TypeScript type definitions
└── test/              ← Vitest setup (setup.ts only — no test cases yet)
```

## API Modules (src/api/)
| File | Domain |
|---|---|
| `axiosInstance.ts` | Base Axios instance, auth header injection, 401 handler |
| `authApi.ts` | Customer login, OTP, register, profile |
| `sellerApi.ts` | Seller auth, products, inventory, orders, dashboard |
| `productsApi.ts` | Public product list/detail |
| `catalogueApi.ts` | Categories, brands, filters |
| `cartApi.ts` | Cart CRUD |
| `ordersApi.ts` | Customer orders |
| `wishlistApi.ts` | Wishlist |
| `addressesApi.ts` | Delivery addresses |
| `brandsApi.ts` | Brand listing |
| `notificationsApi.ts` | Notifications bell |
| `couponsApi.ts` | Coupon apply |
| `adminApi.ts` | Admin panel operations |

## Route Map (AppRouter.tsx)
### Customer routes (public)
| Path | Component |
|---|---|
| `/` | HomePage |
| `/login` | LoginPage |
| `/signup` | SignupPage |
| `/category/:slug` | CategoryPage |
| `/products` | ProductListPage |
| `/products/:id` | ProductDetailPage |

### Customer routes (CustomerRoute guard — role=Customer)
| Path | Component |
|---|---|
| `/wishlist` | WishlistPage |
| `/cart` | CartPage |
| `/orders` | OrdersListPage |
| `/orders/:id` | OrderDetailPage |
| `/profile` | ProfilePage |
| `/addresses` | AddressesPage |
| `/notifications` | NotificationPage |

### Seller routes
| Path | Component | Guard |
|---|---|---|
| `/seller/login` | SellerLoginPage | public |
| `/seller/signup` | SellerSignupPage | public |
| `/seller/onboarding` | SellerOnboardingPage | public |
| `/seller/dashboard` | SellerDashboardPage | SellerRoute |
| `/seller/products` | SellerProductsPage | SellerRoute |
| `/seller/products/add` | SellerAddProductPage | SellerRoute |
| `/seller/products/edit/:id` | SellerEditProductPage | SellerRoute |
| `/seller/orders` | SellerOrdersPage | SellerRoute |
| `/seller/profile` | SellerProfilePage | SellerRoute |

### Admin routes (AdminRoute guard — role=Admin)
| Path | Component |
|---|---|
| `/admin/dashboard` | AdminDashboardPage |
| `/admin/sellers` | AdminSellersPage |
| `/admin/products` | AdminProductsPage |
| `/admin/users` | AdminUsersPage |
| `/admin/orders` | AdminOrdersPage |
| `/admin/cms` | AdminCMSPage |
| `/admin/reviews` | AdminReviewsPage |

## Auth System
- **AuthContext** (`src/context/AuthContext.tsx`) — single source of truth
- Persisted to `localStorage` (token + user object)
- `user.role` = `"Customer"` | `"Seller"` | `"Admin"`
- `useAuthContext()` hook used by route guards and header
- OTP login flow: send OTP → verify → receive JWT
- Password login flow: email + password → JWT

## Route Guards
```tsx
<CustomerRoute>   // requires isAuthenticated && role === 'Customer'
<SellerRoute>     // requires isAuthenticated && role === 'Seller'
<AdminRoute>      // requires isAuthenticated && role === 'Admin'
```
Unauthenticated redirects to `/login` (customer) or `/seller/login` (seller).

## Shared Components (src/components/)
| Component | Purpose |
|---|---|
| `layout/Header.tsx` | Main customer header with nav, auth, cart, wishlist |
| `layout/PremiumHeader.tsx` | Alternate premium header variant |
| `layout/Footer.tsx` | Site footer |
| `layout/MegaMenu.tsx` | Category mega-menu |
| `layout/SellerLayout.tsx` | Seller portal shell |
| `layout/SellerSidebar.tsx` | Seller sidebar nav |
| `layout/SellerHeader.tsx` | Seller top bar |
| `layout/NotificationBell.tsx` | Bell icon with unread count |
| `cart/CartDrawer.tsx` | Slide-out cart panel |
| `auth/AuthModal.tsx` | Login/OTP modal overlay |
| `ui/Spinner.tsx` | Loading indicator |
| `ui/Toast.tsx` | Toast notifications |
| `ui/Modal.tsx` | Generic modal |
| `ui/Button.tsx` | Branded button |
| `ErrorBoundary.tsx` | React error boundary wrapper |

## Design System
Brand color: `#c41230` (StopNShop Red). Gold accent: `#d4a017`.
Full design system: [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)
Branding guide: [BRANDING_GUIDE.md](BRANDING_GUIDE.md)

## Known Gaps
- No test cases (only `src/test/setup.ts` — vitest configured but empty)
- Seller dashboard chart is a placeholder (no chart library yet — needs Recharts or similar)
- Admin pages exist as route stubs — functionality varies
