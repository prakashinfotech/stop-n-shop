Scaffold a new reusable UI component for StopNShop.

Place the file in `stopnshop-ui/src/components/<category>/ComponentName.tsx`.
Categories: `ui/`, `layout/`, `forms/`, `auth/`, `cart/`, `admin/`

Rules:
- Export a named function component (not default export for components)
- Define a TypeScript `Props` interface above the component
- No hardcoded colours — use Tailwind design tokens from `tailwind.config.ts`
- No internal state that belongs in a parent — keep components as dumb as possible
- If the component fetches its own data, use a dedicated hook in `src/hooks/`
- Read existing components in the same category folder before generating to match style
