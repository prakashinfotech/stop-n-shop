Scaffold a new page for the StopNShop UI.

Steps:
1. Create the page component in the correct feature folder: `stopnshop-ui/src/features/<feature>/YourPage.tsx`
2. Add the route in `stopnshop-ui/src/router/AppRouter.tsx`
3. If the page is protected (requires login), wrap it with the auth guard already used in AppRouter

Page component rules:
- Use TypeScript — define all props and state types explicitly
- Handle three states: loading (show `<Spinner />`), error (show `<ErrorMessage />`), and data
- Use the shared API file from `src/api/` — never call axios directly in the component
- Use Tailwind for all styling
- Mobile-first layout — check at `sm:`, `md:`, `lg:` breakpoints

Read `AppRouter.tsx` and one existing page before generating to match the exact patterns used.
