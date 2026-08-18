# UI — Claude Rules

> Read [ARCHITECTURE.md](ARCHITECTURE.md) before any frontend work.

## Tool Rule
Always use **Bash** tool for shell commands. Never PowerShell tool.

## Dev Commands
```bash
npm run dev       # http://localhost:3000
npm run build     # production build to dist/
npm run lint      # eslint
npm run test      # vitest
```

## Coding Rules
- All API calls go through `src/api/` modules — never call `axios` directly in components.
- All server state (fetches, mutations) via React Query v5 — no `useEffect` + `fetch` patterns.
- Use `useAuthContext()` for auth state — never read `localStorage` directly in components.
- New pages go in `src/features/{domain}/` with the route added in `src/router/AppRouter.tsx`.
- New shared UI goes in `src/components/ui/` and must consume the design tokens (see below).
- All routes use lazy imports (`React.lazy`) — don't break this pattern.

## Design System (v2 — Claude.ai hybrid, see [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md))
- **Brand action colour:** `#c41230` red (`bg-brand-500`) for CTAs, links, active states. `#d4a017` gold for premium accents. Unchanged from v1.
- **Surfaces:** never use raw `bg-white` or `bg-gray-*` / `border-gray-*` / `text-gray-*` in JSX. Use the tokens:
  - `bg-bg` (page root) / `bg-surface` (recessed) / `bg-surface-elevated` (cards) / `bg-surface-sunken` (form fields)
  - `text-content` / `text-content-muted` / `text-content-subtle`
  - `border-outline` / `border-outline-strong` / `divide-outline/60`
- **If you need a warm dark accent** (e.g. hero overlay, dark footer), use `stone-*` family — never `gray-*`.
- **Cards default to** `rounded-2xl shadow-soft bg-surface-elevated`. Hero/feature cards use `rounded-3xl shadow-soft-lg`.
- **Always use primitives** from `src/components/ui/` (`Button`, `Card`, `Input`, `Badge`, `Modal`, `EmptyState`, `Skeleton`, `Table`) — don't hand-roll.
- **Tokens flip themes automatically** — light ↔ dark works without per-component `dark:` classes when you use tokens. Only add `dark:` overrides for components that *can't* use tokens (e.g. third-party widgets).

## Adding a New Page Checklist
1. Create `src/features/{domain}/{PageName}.tsx`.
2. Add lazy import in `AppRouter.tsx`.
3. Add `<Route path="..." element={...}>` inside correct guard wrapper.
4. Add API function in `src/api/{domain}Api.ts` if needed.
5. Add TypeScript types in `src/types/` if introducing new shapes.

## Known Issues
- No vitest test cases yet — setup.ts is there but tests need to be written.
- Seller dashboard chart renders a placeholder `<div>` — needs real charting.
