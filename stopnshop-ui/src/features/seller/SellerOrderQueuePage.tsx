import React, { useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Check, X, Loader2, AlertCircle, Package, Printer,
  ArrowRight, Box, Truck, MapPin, CheckCircle2,
} from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { sellerApi, type SellerQueueCounts } from '../../api/sellerApi';
import { useToast } from '../../components/ui/Toast';
import { OrderItemDetailsModal } from './OrderItemDetailsModal';

type Tab = 'placed' | 'confirmed' | 'rejected' | 'fulfilled' | 'all';

const TAB_LABELS: Record<Tab, string> = {
  placed:    'Pending',
  confirmed: 'Confirmed',
  rejected:  'Rejected',
  fulfilled: 'Fulfilled',
  all:       'All',
};

interface QueueItem {
  orderItemId: number;
  orderId: number;
  orderNumber: string;
  productId: number;
  variantId: number;
  productName: string;
  variantSnapshot?: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  orderStatus: number;
  createdAt: string;
  confirmedAt?: string;
  rejectedAt?: string;
  rejectionReason?: string;
  paymentMode: number;
  paymentStatus: number;
  buyerName?: string;
  buyerMobile?: string;
  buyerCity?: string;
  buyerPincode?: string;
  primaryImageUrl?: string;
}

const PAYMENT_LABEL: Record<number, string> = { 1: 'COD', 2: 'Online', 3: 'Wallet' };
const STATUS_LABEL: Record<number, string> = {
  1: 'Placed', 2: 'Confirmed', 3: 'Packed', 4: 'Dispatched',
  9: 'Out for Delivery',
  5: 'Delivered', 6: 'Cancelled', 7: 'Returned', 8: 'Rejected',
};

// Forward-only fulfilment ladder. Each entry is the "next step" available from
// the current status — drives the contextual action button on a row.
// Backend SP enforces the same rule.
interface NextStep { code: number; label: string; icon: React.ElementType; }
const NEXT_STEP: Record<number, NextStep> = {
  2: { code: 3, label: 'Mark as Packed',           icon: Box },
  3: { code: 4, label: 'Mark as Dispatched',       icon: Truck },
  4: { code: 9, label: 'Mark as Out for Delivery', icon: MapPin },
  9: { code: 5, label: 'Mark as Delivered',        icon: CheckCircle2 },
};

const PRESET_REASONS = [
  'Out of stock',
  'Damaged in storage',
  'Address unreachable',
  'Pricing error — relisting',
];

const fmt = (n: number) => `₹${n.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
const formatAge = (iso: string) => {
  const min = Math.floor((Date.now() - new Date(iso).getTime()) / 60_000);
  if (min < 60)       return `${min}m ago`;
  if (min < 60 * 24)  return `${Math.floor(min / 60)}h ago`;
  return `${Math.floor(min / 60 / 24)}d ago`;
};

// Valid tab keys + a runtime guard so we never trust the URL blindly.
const TAB_KEYS: Tab[] = ['placed', 'confirmed', 'rejected', 'fulfilled', 'all'];
const isTab = (v: string | null): v is Tab => !!v && (TAB_KEYS as string[]).includes(v);

export const SellerOrderQueuePage: React.FC = () => {
  const qc = useQueryClient();
  const { showToast } = useToast();

  // URL is the source of truth for the active tab — bookmarks, back/forward,
  // and external links (e.g. from Aria) all just work. Default is 'all' so the
  // seller sees the full queue on first visit; per-seller preference can
  // override this in Phase 4.
  const [searchParams, setSearchParams] = useSearchParams();
  const tab: Tab = isTab(searchParams.get('tab')) ? (searchParams.get('tab') as Tab) : 'all';
  const setTab = (t: Tab) => setSearchParams((sp) => {
    sp.set('tab', t);
    return sp;
  }, { replace: true });

  const [rejecting, setRejecting] = useState<QueueItem | null>(null);
  const [reason, setReason] = useState('');
  const [detailsItem, setDetailsItem] = useState<QueueItem | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['seller-queue', tab],
    queryFn: () =>
      sellerApi.orders.getQueue({ status: tab, page: 1, pageSize: 50 })
        .then((r: any) => r.data.data as { items: QueueItem[]; totalCount: number }),
  });

  // Per-tab counts. Polled every 30s so badges feel "live" without the user
  // having to refresh — picks up newly-placed orders or seller actions.
  const { data: counts } = useQuery({
    queryKey: ['seller-queue-counts'],
    queryFn: () => sellerApi.orders.getQueueCounts().then((r) => r.data.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const items = data?.items ?? [];

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['seller-queue'] });
    qc.invalidateQueries({ queryKey: ['seller-queue-counts'] });
  };

  const confirmMut = useMutation({
    mutationFn: (id: number) => sellerApi.orders.confirmItem(id),
    onSuccess: () => { invalidate(); showToast('Order item confirmed.', 'success'); },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Confirm failed.', 'error'),
  });

  const rejectMut = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) => sellerApi.orders.rejectItem(id, reason),
    onSuccess: () => {
      invalidate();
      setRejecting(null);
      setReason('');
      showToast('Item rejected. Buyer has been notified.', 'success');
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Reject failed.', 'error'),
  });

  // Forward-progression mutation. The SP refuses backwards or skipping moves,
  // so we surface the API's error message verbatim if it pushes back.
  const advanceMut = useMutation({
    mutationFn: ({ id, status }: { id: number; status: number }) =>
      sellerApi.orders.updateItemStatus(id, status),
    onSuccess: (_data, vars) => {
      invalidate();
      showToast(`Marked as ${STATUS_LABEL[vars.status] ?? 'next stage'}.`, 'success');
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Status update failed.', 'error'),
  });

  return (
    <SellerLayout>
      <div className="mb-6">
        <h1 className="text-3xl font-display font-bold text-content">Fulfilment Queue</h1>
        <p className="text-content-muted mt-1">
          Confirm or reject incoming order items. Rejecting restocks the item and refunds the buyer when applicable.
        </p>
      </div>

      {/* Tabs with live counts. The Pending badge is brand-red to draw the eye
          whenever there's work to do; other tabs use a neutral chip. Badges
          hide entirely at zero — Slack-style "absence = good news". */}
      <div className="flex gap-1 border-b border-outline/60 mb-6 overflow-x-auto">
        {(Object.keys(TAB_LABELS) as Tab[]).map((t) => {
          const active = tab === t;
          const count  = countForTab(counts, t);
          const showBadge = count > 0;
          return (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-4 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors inline-flex items-center gap-1.5 ${
                active
                  ? 'border-brand-500 text-brand-600'
                  : 'border-transparent text-content-muted hover:text-content'
              }`}
            >
              {TAB_LABELS[t]}
              <AnimatePresence mode="popLayout">
                {showBadge && (
                  <motion.span
                    key={count}
                    initial={{ scale: 0.6, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.6, opacity: 0 }}
                    transition={{ type: 'spring', stiffness: 500, damping: 22 }}
                    className={`inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full text-[10px] font-bold tabular-nums ${
                      t === 'placed'
                        ? 'bg-brand-500 text-white'
                        : active
                          ? 'bg-brand-50 text-brand-700'
                          : 'bg-surface-sunken text-content-muted'
                    }`}
                  >
                    {count}
                  </motion.span>
                )}
              </AnimatePresence>
            </button>
          );
        })}
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="h-6 w-6 animate-spin text-content-muted" />
        </div>
      ) : items.length === 0 ? (
        <div className="text-center py-16 text-content-muted">
          <Package className="h-12 w-12 mx-auto mb-3 text-content-subtle" />
          <p className="text-sm">No items in this view.</p>
        </div>
      ) : (
        <ul className="space-y-3">
          {items.map((item) => (
            <li
              key={item.orderItemId}
              onDoubleClick={() => setDetailsItem(item)}
              title="Double-click for full details"
              className="bg-surface-elevated border border-outline/60 rounded-2xl p-5 flex flex-col sm:flex-row gap-4 cursor-pointer select-none hover:border-outline-strong transition-colors"
            >
              {item.primaryImageUrl && (
                <img
                  src={item.primaryImageUrl}
                  alt=""
                  className="w-20 h-20 rounded-xl object-cover border border-outline/40 flex-shrink-0"
                />
              )}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs font-mono text-content-subtle">{item.orderNumber}</span>
                  <StatusBadge status={item.orderStatus} />
                  <span className="text-xs text-content-subtle">· {formatAge(item.createdAt)}</span>
                </div>
                <p className="font-semibold text-content truncate">{item.productName}</p>
                {item.variantSnapshot && (
                  <p className="text-xs text-content-muted truncate">{item.variantSnapshot}</p>
                )}
                <div className="flex flex-wrap items-baseline gap-x-4 gap-y-1 mt-2 text-sm">
                  <span className="text-content">
                    {item.quantity} × {fmt(item.unitPrice)}
                  </span>
                  <span className="font-bold text-content">{fmt(item.totalPrice)}</span>
                  <span className="text-xs text-content-subtle">
                    {PAYMENT_LABEL[item.paymentMode]} ·{' '}
                    {item.paymentStatus === 2 ? 'Paid' : 'Unpaid'}
                  </span>
                </div>
                <p className="text-xs text-content-muted mt-1.5">
                  Ship to <strong>{item.buyerName ?? '—'}</strong>
                  {item.buyerCity && <>, {item.buyerCity}</>}
                  {item.buyerPincode && <> {item.buyerPincode}</>}
                </p>
                {item.rejectionReason && (
                  <p className="mt-2 text-xs flex items-start gap-1.5 text-amber-700 bg-amber-50/60 border border-amber-200 rounded-lg px-2 py-1.5">
                    <AlertCircle className="h-3.5 w-3.5 flex-shrink-0 mt-0.5" />
                    <span><strong>Rejected:</strong> {item.rejectionReason}</span>
                  </p>
                )}
              </div>

              {/* Per-status actions:
                  1 (Placed)          → Confirm + Reject
                  2/3/4/9 (in flight) → Print label + Next-step progression button
                  5 (Delivered)       → read-only "delivered" badge
                  Any other (Cancelled/Returned/Rejected) → nothing (status badge in body)
                  All buttons stopPropagation so a double-click on a button doesn't open
                  the details modal as well. */}
              {item.orderStatus === 1 && (
                <div className="flex sm:flex-col gap-2 sm:items-stretch sm:justify-center flex-shrink-0">
                  <button
                    onClick={(e) => { e.stopPropagation(); confirmMut.mutate(item.orderItemId); }}
                    disabled={confirmMut.isPending}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 disabled:opacity-50"
                  >
                    <Check className="h-4 w-4" /> Confirm
                  </button>
                  <button
                    onClick={(e) => { e.stopPropagation(); setRejecting(item); setReason(''); }}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-outline-strong text-content text-sm font-medium hover:bg-surface"
                  >
                    <X className="h-4 w-4" /> Reject
                  </button>
                </div>
              )}

              {[2, 3, 4, 9].includes(item.orderStatus) && (
                <div className="flex sm:flex-col items-end justify-center gap-2 flex-shrink-0">
                  {/* Next-step button — only present if the current status has a next step */}
                  {NEXT_STEP[item.orderStatus] && (() => {
                    const next = NEXT_STEP[item.orderStatus];
                    const Icon = next.icon;
                    return (
                      <button
                        onClick={(e) => { e.stopPropagation(); advanceMut.mutate({ id: item.orderItemId, status: next.code }); }}
                        disabled={advanceMut.isPending}
                        className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-stone-900 text-white text-xs font-semibold hover:bg-stone-800 disabled:opacity-50 transition-colors"
                      >
                        <Icon className="h-3.5 w-3.5" /> {next.label}
                        <ArrowRight className="h-3 w-3 opacity-70" />
                      </button>
                    );
                  })()}
                  {/* Print label — only after Confirm. Status 1 doesn't get this. */}
                  <Link
                    to={`/seller/orders/items/${item.orderItemId}/print`}
                    onClick={(e) => e.stopPropagation()}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-outline-strong text-content text-xs font-medium hover:bg-surface"
                  >
                    <Printer className="h-3.5 w-3.5" /> Print label
                  </Link>
                </div>
              )}

              {item.orderStatus === 5 && (
                <div className="flex flex-col items-end justify-center gap-1 flex-shrink-0 text-right">
                  <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-green-100 text-green-800 text-xs font-bold uppercase tracking-wider">
                    <CheckCircle2 className="h-3.5 w-3.5" /> Delivered
                  </span>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}

      {/* Details modal — opens on double-click of a row */}
      {detailsItem && (
        <OrderItemDetailsModal
          item={detailsItem}
          onClose={() => setDetailsItem(null)}
        />
      )}

      {/* Reject modal */}
      {rejecting && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-surface-elevated rounded-2xl shadow-soft-lg w-full max-w-md p-6 space-y-4">
            <div>
              <h3 className="text-lg font-semibold text-content">Reject this item?</h3>
              <p className="text-sm text-content-muted mt-1">
                Order {rejecting.orderNumber} · {rejecting.productName}
              </p>
            </div>

            <div>
              <p className="text-xs font-medium text-content-muted mb-2">Pick a reason</p>
              <div className="flex flex-wrap gap-2 mb-3">
                {PRESET_REASONS.map((r) => (
                  <button
                    key={r}
                    onClick={() => setReason(r)}
                    className={`px-3 py-1 rounded-full text-xs font-medium ${
                      reason === r
                        ? 'bg-brand-500 text-white'
                        : 'bg-surface-sunken text-content hover:bg-surface'
                    }`}
                  >
                    {r}
                  </button>
                ))}
              </div>
              <textarea
                rows={4}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="Explain why this item can't be fulfilled (minimum 10 characters)…"
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm focus:ring-2 focus:ring-brand-200 focus:border-transparent"
              />
              <p className="text-xs text-content-subtle mt-1">
                {reason.trim().length}/500 characters
              </p>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2 border-t border-outline/60">
              <button
                onClick={() => { setRejecting(null); setReason(''); }}
                className="px-4 py-2 text-sm text-content-muted hover:text-content"
              >
                Cancel
              </button>
              <button
                onClick={() => rejectMut.mutate({ id: rejecting.orderItemId, reason })}
                disabled={reason.trim().length < 10 || rejectMut.isPending}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-red-500 text-white text-sm font-medium hover:bg-red-600 disabled:opacity-50"
              >
                {rejectMut.isPending && <Loader2 className="h-4 w-4 animate-spin" />}
                Reject &amp; notify buyer
              </button>
            </div>
          </div>
        </div>
      )}
    </SellerLayout>
  );
};

// Tab → counts-field mapping. Kept narrow so it's grep-able when adding tabs.
const countForTab = (counts: SellerQueueCounts | undefined, t: Tab): number => {
  if (!counts) return 0;
  switch (t) {
    case 'placed':    return counts.placed;
    case 'confirmed': return counts.confirmed;
    case 'rejected':  return counts.rejected;
    case 'fulfilled': return counts.fulfilled;
    case 'all':       return counts.all;
  }
};

const StatusBadge: React.FC<{ status: number }> = ({ status }) => {
  const palette: Record<number, string> = {
    1: 'bg-amber-100 text-amber-700',
    2: 'bg-emerald-100 text-emerald-700',
    3: 'bg-blue-100 text-blue-700',
    4: 'bg-blue-100 text-blue-700',
    5: 'bg-green-100 text-green-700',
    6: 'bg-stone-100 text-stone-600',
    7: 'bg-stone-100 text-stone-600',
    8: 'bg-red-100 text-red-700',
  };
  return (
    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${palette[status] ?? 'bg-stone-100 text-stone-700'}`}>
      {STATUS_LABEL[status] ?? `Status ${status}`}
    </span>
  );
};
