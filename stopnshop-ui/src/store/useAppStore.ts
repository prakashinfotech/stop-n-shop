import { create } from 'zustand';

/**
 * A proactive nudge from Aria — message + optional CTA + suggestion chips —
 * pushed in from outside the drawer (e.g. the seller layout polling pending
 * orders). The drawer consumes the nudge, renders it as an Aria message, and
 * calls `consumeAriaNudge()` to clear it.
 *
 * `dedupeKey` lets the producer prevent duplicates (e.g. "pending-orders:3"
 * won't refire while the count stays at 3).
 */
export interface AriaNudge {
  id:         string;             // unique per fire, used as message id
  dedupeKey:  string;             // producer-defined, e.g. "pending-orders:3"
  content:    string;
  cta?:       { label: string; href: string };
  suggestions?: string[];
  tone?:      'info' | 'success' | 'default';
}

interface AppStore {
  cartCount: number;
  setCartCount: (count: number) => void;
  incrementCartCount: () => void;
  decrementCartCount: () => void;

  notificationCount: number;
  setNotificationCount: (count: number) => void;
  incrementNotificationCount: () => void;

  ariaOpen: boolean;
  setAriaOpen: (open: boolean) => void;
  toggleAria: () => void;

  pendingAriaNudge: AriaNudge | null;
  setAriaNudge:     (n: AriaNudge) => void;
  consumeAriaNudge: () => void;

  commandPaletteOpen: boolean;
  setCommandPaletteOpen: (open: boolean) => void;
  toggleCommandPalette: () => void;
}

export const useAppStore = create<AppStore>((set) => ({
  cartCount: 0,
  setCartCount: (count) => set({ cartCount: count }),
  incrementCartCount: () => set((state) => ({ cartCount: state.cartCount + 1 })),
  decrementCartCount: () => set((state) => ({ cartCount: Math.max(0, state.cartCount - 1) })),

  notificationCount: 0,
  setNotificationCount: (count) => set({ notificationCount: count }),
  incrementNotificationCount: () => set((state) => ({ notificationCount: state.notificationCount + 1 })),

  ariaOpen: false,
  setAriaOpen: (open) => set({ ariaOpen: open }),
  toggleAria: () => set((state) => ({ ariaOpen: !state.ariaOpen })),

  pendingAriaNudge: null,
  setAriaNudge: (nudge) => set((state) => {
    // Drop the new nudge if its dedupeKey matches a still-unconsumed one —
    // prevents the same condition firing twice while the drawer is closed.
    if (state.pendingAriaNudge?.dedupeKey === nudge.dedupeKey) return state;
    return { pendingAriaNudge: nudge };
  }),
  consumeAriaNudge: () => set({ pendingAriaNudge: null }),

  commandPaletteOpen: false,
  setCommandPaletteOpen: (open) => set({ commandPaletteOpen: open }),
  toggleCommandPalette: () => set((state) => ({ commandPaletteOpen: !state.commandPaletteOpen })),
}));
