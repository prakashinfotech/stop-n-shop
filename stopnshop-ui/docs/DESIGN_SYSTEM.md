# StopNShop Design System v2.0 — Claude.ai Hybrid

> **v2.0 (2026-05-19):** Surface system migrated to warm cream / stone-warm dark per the UI overhaul plan ([docs/UI_OVERHAUL_PLAN.md](../../docs/UI_OVERHAUL_PLAN.md)). Brand red and gold are **unchanged** — they remain the action colours. What changed is the neutral foundation: cool grays out, warm stone/cream in.

## Brand Identity

### Vision
A **premium fashion/lifestyle commerce platform** with a warm, editorial feel — Claude.ai surface aesthetics paired with the Shoppers-Stop brand palette. Buyer, seller, and admin portals are unified expressions of the same brand.

### Brand Values
- **Premium:** High-quality, curated experience
- **Warm:** Cream surfaces, soft shadows, generous whitespace — not cold corporate
- **Trustworthy:** Enterprise-grade infrastructure
- **Elegant:** Sophisticated, minimal, serif headlines for editorial weight
- **Inclusive:** Buyers, sellers, and admins as valued partners

---

## Color Palette

### Primary Brand Color (action only — unchanged from v1)
- **Name:** StopNShop Red
- **Primary:** `#c41230`
- **Dark:** `#6b111e`
- **Scale:** `#fdf2f2` → `#fde8e8` → ... → `#59121c`

**Usage:** Primary CTAs, links, active nav states, brand badges, accent in headers. Never used as a *surface* — always as a *foreground* or interactive element.

### Secondary Accent
- **Gold:** `#d4a017`
- **Usage:** Premium price highlights, decorative accents on hero cards.

### Surface System (v2 — warm cream)
The whole app sits on a warm cream foundation. Never use raw `bg-white` or `bg-gray-*` in new code — use the tokens.

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg-bg` | `#faf9f5` | `#1c1917` | Page root background |
| `bg-surface` | `#f5f1e8` | `#292524` | Recessed panels, table headers, hover states |
| `bg-surface-elevated` | `#ffffff` | `#322e2c` | Cards, modals, dropdowns |
| `bg-surface-sunken` | `#efeadd` | `#1a1715` | Form fields, input backgrounds, kbd chips |

### Neutral Text & Borders (warm stone family)
| Token | Light | Dark | Use |
|---|---|---|---|
| `text-content` | `#1c1917` | `#f5f1e8` | Primary text, headings |
| `text-content-muted` | `#57534e` | `#a8a29e` | Secondary text, descriptions |
| `text-content-subtle` | `#a8a29e` | `#78716c` | Tertiary text, placeholders, icon-only buttons |
| `border-outline` | `#e7e5e0` | `#44403c` | Default borders |
| `border-outline-strong` | `#d6d3cc` | `#57534e` | Emphasized borders, divider lines |

> **Note:** Tailwind's `gray-*` palette is forbidden in new code. CI/eval audit greps for it. If you need a dark accent (e.g. on a hero card overlay), use the `stone-*` family (warm) — never `gray-*` (cool).

### Semantic Colors
- **Success:** `#10b981` (confirmations)
- **Warning:** `#f59e0b` (alerts)
- **Error:** `#ef4444` (errors)
- **Info:** `#3b82f6` (information)

---

## Typography System

### Font Families

**Primary (Body):** Inter
- Weights: 400 (Regular), 500 (Medium), 600 (Semibold), 700 (Bold)
- Usage: Body text, UI elements, forms
- Scale: 12px → 16px → 18px

**Display (Headings):** Playfair Display
- Weights: 400 (Regular), 600 (Semibold), 700 (Bold)
- Usage: Page titles, section headings, premium callouts
- Scale: 28px → 36px → 48px → 64px

### Type Scale

| Role | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| Heading 1 | 48px | 700 | 56px | Page title |
| Heading 2 | 36px | 600 | 44px | Section title |
| Heading 3 | 28px | 600 | 36px | Card title |
| Body Large | 18px | 400 | 28px | Lead paragraph |
| Body Regular | 16px | 400 | 24px | Main body text |
| Body Small | 14px | 400 | 20px | Secondary text |
| Label | 12px | 600 | 16px | Form labels, badges |
| Caption | 12px | 400 | 16px | Captions, help text |

---

## Spacing System

**8px base unit** (Tailwind defaults)

| Scale | Value | Usage |
|---|---|---|
| xs | 4px | Micro spacing |
| sm | 8px | Component padding |
| md | 16px | Section padding |
| lg | 24px | Layout spacing |
| xl | 32px | Large gaps |
| 2xl | 48px | Section separation |

---

## Component Design Language

### Primitives

All shared UI lives in `src/components/ui/`. Always use the primitive, don't roll your own:

| Primitive | File | Variants |
|---|---|---|
| `<Button>` | [Button.tsx](../src/components/ui/Button.tsx) | `primary` / `secondary` / `outline` / `ghost` / `danger` / `gold` × `sm` / `md` / `lg` |
| `<Card>` + `CardHeader`/`CardTitle`/`CardDescription` | [Card.tsx](../src/components/ui/Card.tsx) | `elevated` / `flat` / `outlined` / `hero` × `none`/`sm`/`md`/`lg` padding |
| `<Input>` / `<Textarea>` / `<Select>` | [Input.tsx](../src/components/ui/Input.tsx) | label/hint/error props, ref-forwarded |
| `<Badge>` + `orderStatusVariant()` | [Badge.tsx](../src/components/ui/Badge.tsx) | semantic + 7 order-lifecycle variants |
| `<Modal>` | [Modal.tsx](../src/components/ui/Modal.tsx) | title/description/maxWidth/hideClose |
| `<EmptyState>` | [EmptyState.tsx](../src/components/ui/EmptyState.tsx) | icon halo + action slot, tonal variants |
| `<Skeleton>` + `SkeletonRow` / `SkeletonCard` | [Skeleton.tsx](../src/components/ui/Skeleton.tsx) | token-aware pulse |
| `<Table>` + `THead`/`TBody`/`TR`/`TH`/`TD` | [Table.tsx](../src/components/ui/Table.tsx) | tone-based row separation |

### Buttons (legacy quick-ref — prefer the `<Button>` primitive)

**Primary** — `bg-brand-500 hover:bg-brand-600 text-white shadow-soft` — main CTA.
**Secondary** — `bg-surface hover:bg-surface-sunken text-content border border-outline` — secondary actions.
**Outline** — `border border-brand-500 text-brand-500 hover:bg-brand-50` — neutral context.
**Ghost** — `text-content-muted hover:text-brand-500 hover:bg-surface` — toolbar / icon-only.
**Danger** — `bg-red-600 hover:bg-red-700 text-white` — destructive (cancel order, delete).
**Gold** — `bg-gold-400 hover:bg-gold-500 text-white` — premium callouts.

### Cards

Default card: `rounded-2xl shadow-soft bg-surface-elevated p-6`. Hero/feature cards: `rounded-3xl shadow-soft-lg bg-surface-elevated p-8`. **Don't add hard borders** — soft shadows give definition.

### Forms

Inputs sit on `bg-surface-sunken` with no border by default; on focus they lift to `bg-surface-elevated` with a `border-brand-400` and a 2px brand-200 ring. Label sits above (`text-sm text-content mb-1.5`), hint/error below.

### Modals

`rounded-3xl bg-surface-elevated shadow-soft-xl` with a blurred stone-900/40 backdrop. Title uses `font-display`. Generous padding (`px-7 py-6`).

### Cards

```
Background: white
Border: 1px #e5e7eb (light gray)
Border Radius: 12px
Padding: 20px
Box Shadow: 0 1px 3px rgba(0,0,0,0.1)
Hover: shadow-lg, slight lift (-2px)
```

### Form Inputs

```
Background: white
Border: 1px #d1d5db
Border Radius: 8px
Padding: 12px 16px
Font: 16px Inter 400
Focus: border-brand-500, ring-brand-200
Error: border-red-500
Disabled: bg-gray-50, text-gray-500
```

### Navigation

- **Header Height:** 64px
- **Sidebar Width:** 256px (desktop) → 0 (mobile)
- **Background:** white with subtle border bottom
- **Spacing:** 16px horizontal padding
- **Logo Height:** 32px

---

## Layout System

### Desktop Breakpoints
- **Desktop:** ≥1024px (2-column or full-width)
- **Tablet:** 768px–1023px (1-column with sidebar)
- **Mobile:** <768px (full-width, hamburger menu)

### Container Widths
- **Max Content Width:** 1280px (Tailwind default)
- **Sidebar + Content:** 256px + remainder
- **Padding:** 20px mobile, 32px desktop

### Common Layouts

**Buyer Portal (Header + Content)**
```
┌────────────────────────────────────────┐  64px Header
│ Logo  Search  User Menu                │
├────────────────────────────────────────┤
│                                        │
│  Content Area                          │
│  (full width or with sidebars)         │
│                                        │
└────────────────────────────────────────┘
```

**Seller Portal (Sidebar + Header + Content)**
```
┌──────┬──────────────────────────────────┐
│ Logo │ Seller Name  Notifications       │  64px Header
├──────┼──────────────────────────────────┤
│      │                                  │
│ Nav  │  Content Area                    │
│      │  (main panel)                    │
│      │                                  │
└──────┴──────────────────────────────────┘
256px   1024px (or responsive)
```

---

## Interactive States

### Hover
- Slight color shift
- Subtle shadow elevation
- Cursor change (pointer for interactive elements)
- Duration: 150ms ease-out

### Active / Pressed
- Darker color
- Inset shadow (for buttons)
- Duration: 50ms ease-in

### Disabled
- Opacity: 0.5
- Cursor: not-allowed
- No hover effects

### Loading
- Show spinner or skeleton
- Disable interactions
- Maintain layout (no jumping)

### Focus
- 2px ring in brand color
- Offset: 2px
- Keyboard navigation support (visible focus ring)

---

## Animations & Transitions

### Duration Standards
- **Quick:** 150ms (hovers, small state changes)
- **Normal:** 300ms (page transitions, modals)
- **Slow:** 500ms (loading screens, large animations)

### Easing Functions
- **Entrance:** `ease-out` (feels responsive)
- **Exit:** `ease-in` (feels natural)
- **Standard:** `ease-in-out` (balanced)

### Common Animations
- **Page fade:** opacity 0 → 1, 150ms ease-out
- **Slide from left:** transform -4px → 0, 300ms ease-out
- **Modal entrance:** scale 0.95 → 1 + opacity, 200ms ease-out
- **Loading:** spin 360deg, 1s linear infinite

---

## Accessibility Standards

### WCAG 2.1 Level AA Compliance

**Color Contrast:**
- Body text on background: ≥4.5:1
- Large text (18px+): ≥3:1
- UI components: ≥3:1

**Typography:**
- Min font size: 14px (mobile), 16px (desktop)
- Line height: ≥1.5
- Letter spacing: not reduced

**Interactive Elements:**
- Min touch target: 44px × 44px
- Keyboard navigation: full support
- Focus indicators: always visible
- ARIA labels: where needed

**Images & Icons:**
- All images have alt text
- Icons have aria-labels or context

---

## Unified Branding Across Portals

### Buyer Portal (`/`)
- **Header:** Logo + Search + User Menu
- **Footer:** Links, Newsletter signup
- **Navigation:** Mega-menu (categories)
- **Feel:** Open, inviting, product-focused

### Seller Portal (`/seller`)
- **Header:** Logo + Seller Name + Notifications
- **Sidebar:** Navigation (Dashboard, Products, Orders, Profile)
- **Feel:** Professional, organized, business-focused

### Shared Elements
- Same logo (all pages, tabs, loading screens)
- Same color palette
- Same typography
- Same buttons, cards, forms
- Same spacing & rhythm
- Same animations

### Authentication Pages (`/login`, `/seller/login`)
- Centered layout
- Same header with logo
- Same form styling
- Same button appearance
- Consistent error handling

---

## Icons & Imagery

### Icon System
- **Library:** Lucide React or Heroicons
- **Size:** 20px (default), 24px (large), 16px (small)
- **Color:** Inherit text color or brand color
- **Stroke width:** 2px for clarity

### Photography / Imagery
- **Style:** Clean, bright, lifestyle photography
- **Orientation:** Mostly landscape for products
- **Color Grading:** Natural, well-lit, premium feel
- **Examples:** Unsplash (high-quality free images)

---

## Dark Mode (Future)

Currently light mode only. Dark mode support:
- Invert color palette (light backgrounds → dark)
- Increase contrast on text
- Reduce brightness of colors
- Maintain brand red (shift slightly for readability)

---

## Implementation Checklist

- [x] Tailwind color configuration
- [x] Typography system in place
- [x] Shared component library (Button, Card, Input, etc.)
- [x] Layout components (Header, Sidebar, Footer)
- [ ] Logo & favicon assets
- [ ] Icon system integration
- [ ] Animation utilities
- [ ] Responsive breakpoint patterns
- [ ] Accessibility audit
- [ ] Dark mode (future)

---

## Design Token Export

For developers & designers:

```typescript
// colors.ts
export const COLORS = {
  brand: { primary: '#c41230', dark: '#6b111e', light: '#fdf2f2' },
  gold: { default: '#d4a017', dark: '#9a7009' },
  neutral: { white: '#ffffff', gray: '#6b7280', black: '#000000' },
};

// spacing.ts
export const SPACING = {
  xs: '4px', sm: '8px', md: '16px', lg: '24px', xl: '32px', '2xl': '48px',
};

// typography.ts
export const FONT_SIZES = {
  h1: '48px', h2: '36px', h3: '28px', base: '16px', sm: '14px',
};
```

---

## Questions & Decisions

**Q: Should seller portal have dark mode?**  
A: Not in MVP. Light mode only, consistent with buyer portal.

**Q: Premium animations or minimal?**  
A: Minimal but polished. Animations serve purpose (feedback), not decoration.

**Q: Mobile-first or desktop-first?**  
A: Desktop-first design, mobile-optimized (Tailwind responsive).

**Q: Custom or icon library?**  
A: Lucide React (customizable, consistent, lightweight).

---

## Brand Guidelines Summary

✅ **One logo** everywhere (favicon, header, loading screens)  
✅ **One color palette** (StopNShop red + gold + neutrals)  
✅ **One typography** (Playfair Display + Inter)  
✅ **One component library** (shared across portals)  
✅ **One spacing system** (8px base unit)  
✅ **One tone** (premium, professional, elegant)  
✅ **Different layouts** (buyer header-based, seller sidebar-based)  
✅ **Different URLs** (`/` vs `/seller/`)  
✅ **Same UX quality** (modern startup-grade)

---

## Theme System (Phase 4)

### Modes

The platform supports three theme modes, persisted in `localStorage` under the
`theme` key:

| Mode     | Behavior                                                          |
|----------|-------------------------------------------------------------------|
| `light`  | Force light palette                                                |
| `dark`   | Force dark palette                                                 |
| `system` | Follow `prefers-color-scheme`; updates live when the OS flips      |

The default for first-time visitors is `system`. The toggle in the header
cycles `light → dark → system → light` or opens a menu with all three options.

### How it works

1. **FOUC guard** — an inline `<script>` in [index.html](../index.html) runs
   before React mounts. It reads `localStorage.theme`, resolves `system` via
   `matchMedia`, and sets `class="dark"` + `data-theme` on `<html>` so the
   very first paint matches the user's preference. Without this, dark-mode
   users see a white flash on every cold load.
2. **`ThemeProvider`** ([src/context/ThemeContext.tsx](../src/context/ThemeContext.tsx))
   owns the state, persists changes, and subscribes to OS preference changes
   when in `system` mode.
3. **CSS variables** ([src/styles/tokens.css](../src/styles/tokens.css))
   define every color/spacing/radius/shadow/z/typography token. The `.dark`
   selector overrides only the values that change between themes — component
   code references the same token names regardless.
4. **Tailwind bridge** — `tailwind.config.ts` exposes semantic class names
   (`bg-bg`, `text-content`, `border-outline`, `bg-accent`, …) whose values
   are `var(--color-*)`. New components should prefer these over hard-coded
   `gray-*` / `brand-*` values.

### Token reference

#### Colors (semantic)

| Token                    | Light                  | Dark                  | Use                          |
|--------------------------|------------------------|-----------------------|------------------------------|
| `--color-bg`             | `#ffffff`              | `#0f0f0f`             | page background              |
| `--color-surface`        | `#f9fafb`              | `#1a1a1a`             | recessed surface             |
| `--color-surface-elevated` | `#ffffff`            | `#232323`             | cards, modals                |
| `--color-text`           | `#1f2937`              | `#f5f5f5`             | primary text                 |
| `--color-text-muted`     | `#6b7280`              | `#a0a0a0`             | secondary text               |
| `--color-text-subtle`    | `#9ca3af`              | `#6b7280`             | placeholders, captions       |
| `--color-border`         | `#e5e7eb`              | `rgba(255,255,255,.1)`| dividers                     |
| `--color-accent`         | `#c41230`              | `#e63d56`             | primary CTAs                 |
| `--color-accent-hover`   | `#a10e27`              | `#f15a72`             | CTA hover                    |
| `--color-success/warning/danger/info` | semantic    | semantic              | status                       |

#### Spacing scale

`--space-0` → `--space-16` (0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 px).
Tailwind's built-in spacing already aligns to this scale.

#### Radius scale

`xs (2)`, `sm (4)`, `md (8)`, `lg (12)`, `xl (16)`, `2xl (24)`, `full`.

#### Shadow scale

`xs`, `sm`, `md`, `lg`, `xl`, `focus`. Dark-mode shadows use higher alpha to
remain visible against the near-black surface.

#### Z-index scale

`base (0)`, `raised (10)`, `sticky (100)`, `overlay (1000)`, `modal (1100)`,
`toast (1200)`, `tooltip (1300)`. Never use ad-hoc `z-50`; promote to a token.

#### Typography

- Display: `Playfair Display` (headings, hero copy).
- Body: `Inter` (everything else).
- Size scale: `xs 12, sm 14, base 16, lg 18, xl 20, 2xl 24, 3xl 30, 4xl 36, 5xl 48`.

### Do / Don't

✅ **Do** use semantic Tailwind classes: `bg-surface-elevated`, `text-content-muted`, `border-outline`.

❌ **Don't** hard-code `bg-white dark:bg-gray-900` in new components — that
duplicates what tokens already solve.

✅ **Do** add a new token when an existing one doesn't fit (e.g. brand-specific
    surface). Update both light and dark blocks in `tokens.css`.

❌ **Don't** branch on `theme === 'dark'` in component code. If you need
   different *behavior* (e.g. swapping an image), use `data-theme` selectors in
   CSS or read `useTheme().theme` once at the boundary.

✅ **Do** rely on the focus ring (`:focus-visible` in `index.css`) for
   keyboard a11y. Override only when you have a custom design that still meets
   AA contrast against the accent.

### Accessibility checklist

- AA contrast verified for body text on every surface in both themes.
- Focus ring uses `--shadow-focus` (3px ring at 35–45% accent alpha).
- Theme toggle is a `role="menu"` with `role="menuitemradio"` items and full
  keyboard support (Escape to close, focus-visible state on items).
- The toggle's `aria-label` announces the current mode.

