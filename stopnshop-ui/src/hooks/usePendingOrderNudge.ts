import { useEffect, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAppStore } from '../store/useAppStore';
import { sellerApi } from '../api/sellerApi';
import { useAuthContext } from '../context/AuthContext';

const SNOOZE_KEY        = 'aria-nudge.pending-orders.snooze-until';
const LAST_NUDGED_KEY   = 'aria-nudge.pending-orders.last-count';
const SNOOZE_MS         = 60 * 60 * 1000;   // 1 hour
const POLL_MS           = 30_000;           // 30 s — matches the counts query

/**
 * Watches the seller's fulfilment-queue counts and fires an Aria nudge when
 * pending orders need attention.
 *
 * Fire rule (combination of "don't be annoying" + "don't be useless"):
 *  - Skip when snooze is active (`SNOOZE_KEY` > now).
 *  - Skip when the placed-count hasn't increased since the last nudge — we
 *    only re-fire on a fresh order, not while the seller is working through
 *    an existing backlog.
 *  - When placed drops to 0, reset the "last count" baseline so the *next*
 *    new order fires the nudge again.
 *
 * Producer-side dedupe also exists in the store (see `setAriaNudge`), so a
 * second hook firing while the drawer hasn't yet consumed the first one is
 * safely ignored.
 */
export const usePendingOrderNudge = () => {
  const { user } = useAuthContext();
  const isSeller = user?.role === 'Seller';

  const setNudge = useAppStore((s) => s.setAriaNudge);
  const lastFiredRef = useRef<number | null>(null);

  const { data: counts } = useQuery({
    queryKey: ['seller-queue-counts'],
    queryFn: () => sellerApi.orders.getQueueCounts().then((r) => r.data.data),
    refetchInterval: POLL_MS,
    staleTime: POLL_MS / 2,
    enabled: isSeller,
  });

  useEffect(() => {
    if (!counts) return;
    const placed = counts.placed;

    // Reset baseline once the seller clears the queue — keeps the nudge from
    // being "stuck" after they've worked through everything.
    if (placed === 0) {
      localStorage.setItem(LAST_NUDGED_KEY, '0');
      lastFiredRef.current = 0;
      return;
    }

    // Snoozed? Bail.
    const snoozeUntil = Number(localStorage.getItem(SNOOZE_KEY) ?? '0');
    if (snoozeUntil > Date.now()) return;

    const lastNudged = lastFiredRef.current ??
                       Number(localStorage.getItem(LAST_NUDGED_KEY) ?? '0');
    if (placed <= lastNudged) return;

    // Fire.
    const noun = placed === 1 ? 'order' : 'orders';
    setNudge({
      id:        `pending-orders-${placed}-${Date.now()}`,
      dedupeKey: `pending-orders:${placed}`,
      tone:      'info',
      content:
        `Heads up — you have **${placed} pending ${noun}** waiting for action. ` +
        `Buyers are watching the clock; want me to open the queue?`,
      cta: { label: 'Open Pending tab', href: '/seller/orders/queue?tab=placed' },
      suggestions: ['Snooze 1h', 'How do I confirm orders?'],
    });

    localStorage.setItem(LAST_NUDGED_KEY, String(placed));
    lastFiredRef.current = placed;
  }, [counts, setNudge]);
};

/** Called from the drawer when the seller picks the "Snooze 1h" chip. */
export const snoozePendingOrderNudge = () => {
  localStorage.setItem(SNOOZE_KEY, String(Date.now() + SNOOZE_MS));
};
