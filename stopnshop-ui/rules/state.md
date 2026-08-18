## State Management Rules

- Do not prop-drill more than 2 levels — lift state to a Context or a shared parent
- Global state (auth, cart, wishlist) lives in `src/context/` — do not duplicate in local state
- Use custom hooks in `src/hooks/` for shared stateful logic (e.g., `useCart`, `useWishlist`)
- Every async operation must track: `isLoading`, `error`, and `data` — never show stale data silently
- Do not store derived data in state — compute it from existing state during render
