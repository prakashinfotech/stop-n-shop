# StopNShop — Unified Branding & Portal Implementation Guide

## Overview

This document explains the unified brand system spanning both customer and seller portals of StopNShop. Both portals feel like integrated parts of the same premium platform, with consistent design language while maintaining separate navigation contexts.

---

## Brand Architecture

### Single Logo, Multiple Contexts

**Logo appears in:**
- ✅ Browser tab (favicon.svg)
- ✅ Header (all pages)
- ✅ Loading screens
- ✅ Email communications (future)
- ✅ Mobile app icon (future)

**Design:** Gradient red square with "S" monogram + wordmark
- **Mark size:** 32px (mobile) → 56px (desktop)
- **Format:** SVG for scalability
- **Files:** 
  - `public/logo.svg` — full logo (200×56px)
  - `public/favicon.svg` — favicon mark (32×32px)

---

## Portal Structure

### Buyer Portal (`/`)

```
StopNShop Header
├── Logo (left)
├── Search bar (center)
└── User menu (right)

Content Area
├── Homepage with hero, categories, featured products
├── Product listing / detail pages
├── Cart & checkout
└── Orders & account

Footer
└── Links, newsletter, contact
```

**Feel:** Open, inviting, product-focused  
**Navigation:** Horizontal (mega-menu categories)  
**Color accent:** Brand red on CTAs

### Seller Portal (`/seller/`)

```
PremiumHeader
├── Logo (left)
└── Seller name + avatar (right)

SellerSidebar (left)
├── Dashboard (KPIs)
├── Products (manage)
├── Orders (fulfill)
└── Profile (store info)

Main Content (right)
└── Current section content

Footer (optional)
```

**Feel:** Professional, organized, business-focused  
**Navigation:** Vertical sidebar (persistent)  
**Color accent:** Brand red on active nav items

### Unified Authentication

**Customer Login:** `/login`  
**Seller Login:** `/seller/login`

Both pages:
- Same header with logo
- Same form styling (PremiumFormInput + PremiumButton)
- Same card design (white, rounded, subtle shadow)
- Same typography (Playfair Display heading, Inter body)
- Cross-links ("Seller?" ↔ "Customer?")

---

## Design Tokens

### Colors

**Primary Brand:**
```css
brand-500:  #c41230  /* Main CTA, accents */
brand-600:  #a10e27  /* Hover state */
brand-700:  #831122  /* Active/pressed */
brand-800:  #6b111e  /* Dark variant */
```

**Secondary Accent:**
```css
gold-400:   #d4a017  /* Premium indicators, badges */
gold-500:   #b8860b  /* Hover on gold */
```

**Neutral Palette:**
```css
white:      #ffffff  /* Backgrounds, cards */
gray-50:    #f9fafb  /* Subtle backgrounds */
gray-100:   #f3f4f6  /* Dividers, borders */
gray-200:   #e5e7eb  /* Form borders */
gray-600:   #4b5563  /* Secondary text */
gray-900:   #1f2937  /* Primary text, headings */
black:      #000000  /* High contrast */
```

**Semantic:**
```css
success:    #10b981  /* Confirmations, checkmarks */
warning:    #f59e0b  /* Low stock, alerts */
error:      #ef4444  /* Errors, rejections */
```

### Typography

**Display Font:** Playfair Display
- Used for: H1, H2, H3, page titles, premium callouts
- Weights: 400, 600, 700
- Color: gray-900 (dark)

**Body Font:** Inter
- Used for: body text, labels, buttons, UI
- Weights: 400, 500, 600, 700
- Color: gray-600 (secondary), gray-900 (primary)

**Type Scale:**
```
H1: 48px / 700 weight     → Page title
H2: 36px / 600 weight     → Section heading
H3: 28px / 600 weight     → Card title
Body Large:  18px / 400   → Lead paragraph
Body:        16px / 400   → Main text
Small:       14px / 400   → Secondary text
Label:       12px / 600   → Form labels
Caption:     12px / 400   → Help text
```

### Spacing

**8px base unit**
```
xs:   4px    (micro)
sm:   8px    (component padding)
md:   16px   (section padding)
lg:   24px   (layout spacing)
xl:   32px   (large gaps)
2xl:  48px   (section separation)
```

### Buttons

**Primary (CTA):**
```
Background:  gradient-brand (red to dark red)
Text:        white
Padding:     12px 24px
Border:      none
Radius:      8px
Font Weight: 600
Hover:       shadow-lg, translate up 2px
Icon Gap:    8px
Loading:     spinner visible, disabled
```

**Secondary:**
```
Background:  transparent
Border:      2px brand-500
Text:        brand-600
Padding:     12px 24px
Radius:      8px
Hover:       bg-brand-50
```

**Ghost:**
```
Background:  transparent
Border:      none
Text:        brand-600
Hover:       underline
```

### Form Inputs

```
Background:    white
Border:        1px gray-300
Padding:       12px 16px
Font Size:     16px
Font Family:   Inter
Radius:        8px
Focus:         ring-2 ring-offset-0, ring-brand-200, border-brand-500
Error:         border-red-300, ring-red-200
Disabled:      bg-gray-50, opacity-50
Label:         12px, 600 weight, gray-900
Help Text:     12px, 400 weight, gray-500
```

### Cards

```
Background:    white
Border:        1px gray-100
Padding:       20px
Radius:        12px
Shadow:        0 1px 3px rgba(0,0,0,0.1)
Hover:         shadow-lg, -translate-y-1
Transition:    all 200ms ease-out
```

---

## Component Library

### Shared Components

**PremiumHeader** (`components/layout/PremiumHeader.tsx`)
- Logo on left (clickable → home)
- Right content slot (user menu, notifications, etc.)
- Height: 64px
- Border-bottom: 1px gray-100
- Sticky: top-0 z-40

**PremiumFormInput** (`components/forms/PremiumFormInput.tsx`)
- Label, input field, error/hint text
- Props: label, error, hint, disabled
- Automatic focus ring styling
- Error color: red-300/red-200

**PremiumButton** (`components/forms/PremiumButton.tsx`)
- Variants: primary (default), secondary, ghost
- Sizes: sm (small), md (medium), lg (large)
- Loading state: spinner, disabled
- Smooth transitions, focus ring

**SellerSidebar** (`components/layout/SellerSidebar.tsx`)
- Persistent left sidebar (256px wide)
- Nav items with active state (red highlight)
- Seller info at top
- Logout button at bottom
- Icons from Lucide React (20px)

**SellerLayout** (`components/layout/SellerLayout.tsx`)
- Wrapper combining PremiumHeader + SellerSidebar + content
- Header shows seller name & avatar
- Sidebar fixed, main area scrolls
- Responsive: sidebar hidden on mobile (future phase)

**AuthLayout** (`components/layout/AuthLayout.tsx`)
- Centered card design
- Logo in header
- White card (rounded-2xl, border, shadow)
- Variant prop: buyer | seller (affects title/subtitle)
- Cross-links to other portal

---

## Responsive Design

### Breakpoints

| Screen | Breakpoint | Grid | Sidebar |
|---|---|---|---|
| Mobile | <768px | 1 col | Hidden |
| Tablet | 768-1023px | 2 col | Overlay |
| Desktop | ≥1024px | 3-5 col | Fixed 256px |

### Mobile-First Approach

- Start with 1-column layout
- Add responsive utilities: `sm:`, `md:`, `lg:`, `xl:`
- Container: max-w-6xl mx-auto
- Padding: 16px mobile → 32px desktop

---

## Pages Implemented

### Customer Portal

- ✅ **Login** (`/login`) — PremiumFormInput + AuthLayout
- ✅ **Signup** (`/signup`) — Multi-field form, Zod validation
- ✅ **Homepage** (`/`) — Hero, categories, featured products
- ✅ **Products** (`/products`) — Listing with filters
- ✅ **Product Detail** (`/products/:id`) — Full product view
- ✅ **Cart** (`/cart`) — Private route
- ✅ **Orders** (`/orders`) — Order history
- ✅ **Wishlist** (`/wishlist`) — Private route

### Seller Portal

- ✅ **Login** (`/seller/login`) — SellerLoginPage with demo credentials
- 🔄 **Signup** (`/seller/signup`) — SellerSignupPage (template prepared)
- ✅ **Dashboard** (`/seller/dashboard`) — KPI cards, quick actions
- 🔄 **Products** (`/seller/products`) — List/edit/delete
- 🔄 **Add Product** (`/seller/products/add`) — Form with image upload
- 🔄 **Orders** (`/seller/orders`) — Order list, detail view
- 🔄 **Profile** (`/seller/profile`) — Store info, banner, logo, contact

✅ = Implemented  
🔄 = Structure ready, template prepared

---

## API Integration

### API Module Structure

**`src/api/sellerApi.ts`** — All seller endpoints

```typescript
export const sellerApi = {
  auth: { login(), signup(), getProfile(), updateProfile() },
  products: { getAll(), getById(), create(), update(), delete(), uploadImages() },
  inventory: { getAll(), getLowStock() },
  orders: { getAll(), getById() },
  dashboard: { getStats() },
};
```

### Custom Hooks

**`useSellerAuth`** — Login/signup logic
- Calls `sellerApi.auth.login/signup()`
- Stores token in localStorage
- Updates AuthContext
- Returns login/signup/logout functions

---

## Authentication Flow

### Seller Login

1. User enters email + password on `/seller/login`
2. Click "Sign In"
3. POST `/api/seller/auth/login` → returns JWT token + seller profile
4. Token stored in `localStorage.sns_seller_token`
5. AuthContext updated with seller profile
6. Redirect to `/seller/dashboard`
7. Future requests include `Authorization: Bearer {token}` header

### Role-Based Access

```typescript
// In AuthContext, token.role = "Seller"
// PrivateRoute checks: isAuthenticated
// SellerLayout renders: only if logged in + role verification
```

---

## Design System Checklist

- [x] Color palette (brand red + gold + neutrals)
- [x] Typography system (Playfair Display + Inter)
- [x] Spacing system (8px base unit)
- [x] Button styles (primary, secondary, ghost)
- [x] Form input styles (with error/focus states)
- [x] Card design (white, border, subtle shadow)
- [x] Header component (reusable across portals)
- [x] Sidebar component (seller-specific)
- [x] Auth layout (centered card, logo)
- [x] Logo & favicon (SVG, scalable)
- [x] Responsive breakpoints (mobile-first)
- [x] Animation/transitions (smooth, 150-300ms)
- [x] Accessibility (WCAG 2.1 AA contrast, focus rings)

---

## Future Enhancements

### Phase 2 (Seller Pages)
- [ ] Seller signup page (multi-step form)
- [ ] Seller products page (table with filters)
- [ ] Add/edit product page (form + image uploader)
- [ ] Orders page (table, status filters)
- [ ] Profile page (store info, settings)

### Phase 3 (Features)
- [ ] Dark mode support
- [ ] Mobile navigation (hamburger menu)
- [ ] Notifications dropdown
- [ ] Real-time updates (WebSocket)
- [ ] Charts/analytics (Dashboard)

### Phase 4 (Admin Portal)
- [ ] Admin login
- [ ] Seller approval workflow
- [ ] Product approval
- [ ] Order management
- [ ] Analytics dashboard

---

## File Structure

```
stopnshop-ui/src/
├── components/
│   ├── layout/
│   │   ├── PremiumHeader.tsx          ← Shared header
│   │   ├── SellerSidebar.tsx          ← Seller nav
│   │   ├── SellerLayout.tsx           ← Seller wrapper
│   │   ├── AuthLayout.tsx             ← Auth pages wrapper
│   │   ├── Header.tsx                 ← Customer header
│   │   └── Footer.tsx                 ← Footer
│   └── forms/
│       ├── PremiumFormInput.tsx       ← Text input
│       ├── PremiumButton.tsx          ← Button styles
│       └── ... (other form components)
│
├── features/
│   ├── seller/
│   │   ├── SellerLoginPage.tsx        ← Login form
│   │   ├── SellerDashboardPage.tsx    ← Dashboard with KPIs
│   │   ├── useSellerAuth.ts           ← Auth hook
│   │   └── ... (other seller pages)
│   ├── auth/
│   │   ├── LoginPage.tsx              ← Customer login
│   │   └── SignupPage.tsx             ← Customer signup
│   └── ... (other customer pages)
│
├── api/
│   ├── axiosInstance.ts               ← HTTP client
│   ├── sellerApi.ts                   ← Seller endpoints
│   └── ... (other API modules)
│
├── router/
│   └── AppRouter.tsx                  ← Routes (updated)
│
├── context/
│   └── AuthContext.tsx                ← Auth state
│
└── tailwind.config.ts                 ← Design tokens
    (brand colors, fonts, spacing)

public/
├── logo.svg                           ← Full logo
└── favicon.svg                        ← Tab icon
```

---

## Test Seller Account

```
Email:    testvendor@example.com
Password: Test123!@
Status:   Approved & Active
```

Use these credentials to:
1. Log in to `/seller/login`
2. View dashboard at `/seller/dashboard`
3. Test KPI cards loading
4. Navigate via sidebar

---

## Brand Assets

- ✅ **Logo**: `public/logo.svg` (200×56px)
- ✅ **Favicon**: `public/favicon.svg` (32×32px)
- ✅ **Colors**: Defined in `tailwind.config.ts`
- ✅ **Fonts**: Inter (body) + Playfair Display (headings) via Google Fonts
- 🔄 **Icons**: Lucide React (20-24px, inherit color)
- 🔄 **Images**: Stock photography (Unsplash, product photos)

---

## Getting Started

### 1. Start React Dev Server

```bash
cd stopnshop-ui
npm run dev
```

### 2. View Customer Portal

- http://localhost:5173/ (homepage)
- http://localhost:5173/login (customer login)

### 3. View Seller Portal

- http://localhost:5173/seller/login (seller login)
- http://localhost:5173/seller/dashboard (dashboard, **requires login**)

### 4. Use Test Credentials

Email: `testvendor@example.com`  
Password: `Test123!@`

### 5. Inspect Design System

- Open DevTools
- Check computed styles (Tailwind classes)
- Verify colors, fonts, spacing
- Test responsive behavior (responsive design mode)

---

## Support

For design questions or updates:
1. Check `docs/DESIGN_SYSTEM.md` (comprehensive reference)
2. Refer to `tailwind.config.ts` (token definitions)
3. Review existing pages (pattern matching)
4. Update components as needed

---

## Brand Promise

> **StopNShop** is a premium, modern, trustworthy fashion commerce platform where customers love to shop and sellers love to sell.

Every design decision reflects this promise through:
- ✨ **Premium feel** — Elegant, refined, sophisticated
- 🚀 **Modern aesthetic** — Clean, minimal, startup-grade
- 🤝 **Trust & confidence** — Professional, organized, reliable
- 🎨 **Consistent branding** — One logo, one palette, one voice
- 📱 **Scalable design** — Works across devices and contexts
