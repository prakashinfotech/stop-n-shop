## Styling Rules

- Use Tailwind utility classes exclusively — no separate CSS files except `src/index.css`
- No inline `style={{}}` props
- Colours must come from the design tokens defined in `tailwind.config.ts` — no hardcoded hex values in JSX
- All layouts must be mobile-first: start with base styles (mobile), then add `sm:`, `md:`, `lg:` breakpoints
- Use the shared components in `src/components/ui/` (Button, Spinner, Modal, Toast, etc.) before creating new ones
- Refer to `stopnshop-ui/BRANDING_GUIDE.md` for brand colours, typography, and spacing standards
