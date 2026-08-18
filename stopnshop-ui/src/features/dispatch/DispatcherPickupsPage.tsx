import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Package, MapPin, IndianRupee, Phone, Check, Truck, Loader2, AlertCircle,
} from 'lucide-react';
import { DispatcherLayout } from '../../components/layout/DispatcherLayout';
import { dispatcherApi, type DispatcherQueueItem } from '../../api/dispatcherApi';
import { useToast } from '../../components/ui/Toast';

/**
 * Pickup queue — two-section view:
 *   1. "Available to claim" (status 3) — primary CTA: Claim
 *   2. "Claimed, ready to leave" (status 10) — primary CTA: Confirm all
 *
 * After all status-10 items are confirmed in one batch, the seller's
 * dashboard + buyer tracking strip simultaneously update to "Dispatched".
 */
export const DispatcherPickupsPage: React.FC = () => {
  const qc = useQueryClient();
  const { showToast } = useToast();

  const queueQ = useQuery({
    queryKey: ['dispatcher-pickup-queue'],
    queryFn: () => dispatcherApi.getPickupQueue({ page: 1, pageSize: 50 }).then((r) => r.data.data),
    refetchInterval: 30_000,
  });

  const claimMut = useMutation({
    mutationFn: (orderItemId: number) => dispatcherApi.claimPickup(orderItemId),
    onSuccess: () => {
      showToast('Picked up. Item is now at the warehouse.', 'success');
      qc.invalidateQueries({ queryKey: ['dispatcher-pickup-queue'] });
      qc.invalidateQueries({ queryKey: ['dispatcher-active'] });
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Claim failed.', 'error'),
  });

  const confirmMut = useMutation({
    mutationFn: () => dispatcherApi.confirmPickup(),
    onSuccess: (res) => {
      const n = res.data.data?.confirmed ?? 0;
      // Toast API only knows "success" / "error" — fall back to success for the zero case.
      showToast(
        n === 0 ? 'Nothing to confirm — claim items first.' : `${n} item${n === 1 ? '' : 's'} dispatched. Good route!`,
        'success',
      );
      qc.invalidateQueries({ queryKey: ['dispatcher-pickup-queue'] });
      qc.invalidateQueries({ queryKey: ['dispatcher-active'] });
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Confirm failed.', 'error'),
  });

  const items = queueQ.data?.items ?? [];
  const available = items.filter((i) => i.orderStatus === 3);
  const claimed   = items.filter((i) => i.orderStatus === 10);

  return (
    <DispatcherLayout>
      <header className="mb-6 flex flex-col sm:flex-row sm:items-end sm:justify-between gap-3">
        <div>
          <h1 className="text-2xl font-display font-bold text-content">Pickups</h1>
          <p className="text-sm text-content-muted mt-1">
            Packed orders at your warehouses. Claim what you'll take, then confirm pickup when leaving.
          </p>
        </div>
        {claimed.length > 0 && (
          <button
            onClick={() => confirmMut.mutate()}
            disabled={confirmMut.isPending}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-stone-900 hover:bg-stone-800 disabled:opacity-50 text-white font-semibold text-sm transition-colors shadow-soft"
          >
            <Truck className="h-4 w-4" />
            {confirmMut.isPending ? 'Confirming…' : `Confirm pickup (${claimed.length})`}
          </button>
        )}
      </header>

      {queueQ.isLoading ? (
        <div className="flex items-center justify-center py-16 text-content-muted">
          <Loader2 className="h-5 w-5 animate-spin" />
        </div>
      ) : items.length === 0 ? (
        <EmptyQueue />
      ) : (
        <div className="space-y-8">
          {claimed.length > 0 && (
            <Section
              title={`Claimed — ready to dispatch (${claimed.length})`}
              hint="These are loaded for you. Hit 'Confirm pickup' above when you've left the warehouse."
              tone="amber"
            >
              {claimed.map((item) => (
                <PickupRow
                  key={item.orderItemId}
                  item={item}
                  variant="claimed"
                  onClaim={() => {}}
                  busy={false}
                />
              ))}
            </Section>
          )}

          {available.length > 0 && (
            <Section
              title={`Available to claim (${available.length})`}
              hint="Order shown ascending by age — oldest first."
              tone="brand"
            >
              {available.map((item) => (
                <PickupRow
                  key={item.orderItemId}
                  item={item}
                  variant="available"
                  onClaim={() => claimMut.mutate(item.orderItemId)}
                  busy={claimMut.isPending}
                />
              ))}
            </Section>
          )}
        </div>
      )}
    </DispatcherLayout>
  );
};

const EmptyQueue: React.FC = () => (
  <div className="text-center py-20 text-content-muted">
    <Package className="h-12 w-12 text-content-subtle mx-auto mb-3" />
    <p className="font-medium text-content">No pickups right now.</p>
    <p className="text-xs mt-1">New orders will appear here once sellers mark them Packed.</p>
  </div>
);

const SECTION_TONE = {
  brand: 'border-brand-200 bg-brand-50/30',
  amber: 'border-amber-200 bg-amber-50/30',
} as const;

const Section: React.FC<{
  title: string; hint?: string; tone: keyof typeof SECTION_TONE; children: React.ReactNode;
}> = ({ title, hint, tone, children }) => (
  <section>
    <div className={`rounded-xl border ${SECTION_TONE[tone]} px-3 py-2 mb-3 flex items-start gap-2`}>
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-content">{title}</p>
        {hint && <p className="text-[11px] text-content-muted mt-0.5">{hint}</p>}
      </div>
    </div>
    <ul className="space-y-3">{children}</ul>
  </section>
);

interface PickupRowProps {
  item:    DispatcherQueueItem;
  variant: 'available' | 'claimed';
  onClaim: () => void;
  busy:    boolean;
}

const PickupRow: React.FC<PickupRowProps> = ({ item, variant, onClaim, busy }) => {
  const inr = (n: number) => `₹${n.toLocaleString('en-IN')}`;
  return (
    <li className="bg-surface-elevated border border-outline/60 rounded-2xl p-4 sm:p-5 flex flex-col sm:flex-row gap-4">
      <div className="flex-1 min-w-0">
        <div className="flex flex-wrap items-center gap-2 mb-1">
          <span className="text-xs font-mono text-content-subtle">{item.orderNumber}</span>
          <span className="inline-flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-stone-100 text-stone-700">
            <MapPin className="h-3 w-3" /> {item.warehouseCode}
          </span>
          {variant === 'claimed' && (
            <span className="inline-flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-amber-100 text-amber-700">
              <Check className="h-3 w-3" /> Picked up
            </span>
          )}
        </div>

        <p className="font-semibold text-content truncate">{item.productName}</p>
        {item.variantSnapshot && (
          <p className="text-xs text-content-muted truncate">{item.variantSnapshot}</p>
        )}

        <div className="mt-2 grid sm:grid-cols-2 gap-x-4 gap-y-1 text-sm">
          <div>
            <span className="text-content-muted">Qty</span> <strong>{item.quantity}</strong>{' '}
            <span className="text-content-muted">·</span>{' '}
            <span className="font-bold text-content">{inr(item.totalPrice)}</span>
          </div>
          {item.codAmount != null && (
            <div className="text-amber-700 font-medium">
              <IndianRupee className="h-3.5 w-3.5 inline -mt-0.5" />
              COD collect {inr(item.codAmount)}
            </div>
          )}
        </div>

        <div className="mt-2 text-xs text-content-muted leading-tight">
          <p>
            <strong className="text-content">{item.buyerName ?? 'Customer'}</strong> ·{' '}
            {[item.buyerAddressLine1, item.buyerCity, item.buyerState, item.buyerPincode].filter(Boolean).join(', ') || '—'}
          </p>
          {item.buyerMobile && (
            <p className="flex items-center gap-1 mt-0.5">
              <Phone className="h-3 w-3 text-brand-500" />
              <a href={`tel:${item.buyerMobile}`} className="font-mono hover:text-brand-600">{item.buyerMobile}</a>
            </p>
          )}
        </div>
      </div>

      {variant === 'available' && (
        <div className="flex sm:flex-col items-stretch sm:justify-center gap-2 flex-shrink-0 sm:w-32">
          <button
            onClick={onClaim}
            disabled={busy}
            className="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-lg bg-brand-500 hover:bg-brand-600 disabled:opacity-50 text-white text-sm font-medium transition-colors"
          >
            {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
            Claim
          </button>
        </div>
      )}
    </li>
  );
};

// Lightweight info alert for warehouse mismatch errors — visual only; used in
// catch blocks when needed. Kept here to avoid an extra file.
export const QueueWarning: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="flex items-start gap-2 text-xs bg-amber-50 border border-amber-200 rounded-lg px-3 py-2 text-amber-700">
    <AlertCircle className="h-3.5 w-3.5 flex-shrink-0 mt-0.5" />
    <span>{children}</span>
  </div>
);
