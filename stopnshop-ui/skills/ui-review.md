Review the provided React component or page. Check for:

1. **TypeScript** — no `any` types; all props, state, and API responses are typed
2. **API calls** — all calls go through `src/api/` files using `axiosInstance`, never direct axios/fetch
3. **States handled** — loading, error, and empty states all have UI (not just the happy path)
4. **Responsiveness** — layout works on mobile (375px), tablet (768px), and desktop (1280px)
5. **Accessibility** — interactive elements have accessible labels; images have `alt` text
6. **Styling** — Tailwind classes only; no inline styles
7. **Performance** — no unnecessary re-renders; expensive operations are memoised where appropriate

Report issues as: Critical / Warning / Suggestion.
