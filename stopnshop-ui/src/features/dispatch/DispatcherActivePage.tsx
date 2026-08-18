import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  ClipboardList, Loader2, Truck, Box, MapPin, AlertTriangle, IndianRupee,
  ArrowRight, CheckCircle2, X, Send,
} from 'lucide-react';
import { DispatcherLayout } from '../../components/layout/DispatcherLayout';
import { dispatcherApi, type DispatcherAssignment } from '../../api/dispatcherApi';
import { useToast } from '../../components/ui/Toast';

/**
 * Active assignments — items currently in flight (status 10/4/9/11).
 *   • status 4 → "Mark Out for Delivery" button
 *   • status 9 → "Deliver" button opens the OTP + proof + COD modal
 */
const STATUS_META: Record<number, { label: string; icon: React.ElementType; cls: string }> = {
  10: { label: 'Picked up',         icon: Box,            cls: 'bg-amber-50 text-amber-700  border-amber-200' },
  4:  { label: 'Dispatched',        icon: Truck,          cls: 'bg-blue-50 text-blue-700    border-blue-200' },
  9:  { label: 'Out for Delivery',  icon: MapPin,         cls: 'bg-yellow-50 text-yellow-800 border-yellow-200' },
  11: { label: 'Delivery failed',   icon: AlertTriangle,  cls: 'bg-red-50 text-red-700      border-red-200' },
};

const inr = (n: number) => `₹${n.toLocaleString('en-IN')}`;

export const DispatcherActivePage: React.FC = () => {
  const qc = useQueryClient();
  const { showToast } = useToast();
  const [delivering, setDelivering] = useState<DispatcherAssignment | null>(null);

  const activeQ = useQuery({
    queryKey: ['dispatcher-active'],
    queryFn: () => dispatcherApi.getActive({ page: 1, pageSize: 50 }).then((r) => r.data.data),
    refetchInterval: 30_000,
  });

  const ofdMut = useMutation({
    mutationFn: (assignmentId: number) => dispatcherApi.markOutForDelivery(assignmentId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['dispatcher-active'] });
      qc.invalidateQueries({ queryKey: ['dispatcher-today'] });
      showToast('Marked out for delivery. Buyer notified.', 'success');
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Could not update.', 'error'),
  });

  const items = activeQ.data?.items ?? [];

  return (
    <DispatcherLayout>
      <h1 className="text-2xl font-display font-bold text-content mb-1">Active deliveries</h1>
      <p className="text-sm text-content-muted mb-6">
        Everything currently in flight. Status updates flow back to the buyer's timeline in real time.
      </p>

      {activeQ.isLoading ? (
        <div className="flex items-center justify-center py-16 text-content-muted">
          <Loader2 className="h-5 w-5 animate-spin" />
        </div>
      ) : items.length === 0 ? (
        <div className="text-center py-20 text-content-muted">
          <ClipboardList className="h-12 w-12 text-content-subtle mx-auto mb-3" />
          <p className="font-medium text-content">Nothing in flight.</p>
          <p className="text-xs mt-1">Claim a pickup to get started.</p>
        </div>
      ) : (
        <ul className="space-y-3">
          {items.map((a) => (
            <ActiveRow
              key={a.assignmentId}
              a={a}
              onMarkOfd={() => ofdMut.mutate(a.assignmentId)}
              ofdPending={ofdMut.isPending && ofdMut.variables === a.assignmentId}
              onDeliver={() => setDelivering(a)}
            />
          ))}
        </ul>
      )}

      {delivering && (
        <DeliveryModal
          a={delivering}
          onClose={() => setDelivering(null)}
          onDelivered={() => {
            qc.invalidateQueries({ queryKey: ['dispatcher-active'] });
            qc.invalidateQueries({ queryKey: ['dispatcher-today'] });
            setDelivering(null);
          }}
        />
      )}
    </DispatcherLayout>
  );
};

const ActiveRow: React.FC<{
  a: DispatcherAssignment;
  onMarkOfd: () => void;
  ofdPending: boolean;
  onDeliver: () => void;
}> = ({ a, onMarkOfd, ofdPending, onDeliver }) => {
  const meta = STATUS_META[a.assignmentStatus] ?? STATUS_META[4];
  const Icon = meta.icon;
  return (
    <li className="bg-surface-elevated border border-outline/60 rounded-2xl p-4 sm:p-5">
      <div className="flex flex-wrap items-center justify-between gap-2 mb-2">
        <div className="flex items-center gap-2 min-w-0">
          <span className="text-xs font-mono text-content-subtle">{a.orderNumber}</span>
          <span className={`inline-flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full border ${meta.cls}`}>
            <Icon className="h-3 w-3" /> {meta.label}
          </span>
          {a.attemptNumber > 1 && (
            <span className="text-[10px] uppercase tracking-wider text-content-muted">
              · attempt #{a.attemptNumber}
            </span>
          )}
        </div>
        {a.codAmount != null && (
          <span className="inline-flex items-center gap-1 text-xs font-semibold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-full">
            <IndianRupee className="h-3 w-3" /> COD {inr(a.codAmount)}
          </span>
        )}
      </div>

      <p className="font-semibold text-content truncate">{a.productName}</p>
      {a.variantSnapshot && <p className="text-xs text-content-muted">{a.variantSnapshot}</p>}

      <div className="mt-2 text-sm">
        <span className="text-content-muted">Qty</span> <strong>{a.quantity}</strong>{' '}
        <span className="text-content-muted">·</span>{' '}
        <strong>{inr(a.totalPrice)}</strong>{' '}
        <span className="text-content-muted">·</span>{' '}
        <span className="text-content-muted">From</span> <strong>{a.warehouseCode}</strong>
      </div>

      <div className="mt-2 text-xs text-content-muted leading-tight">
        <p>
          <strong className="text-content">{a.buyerName ?? 'Customer'}</strong> ·{' '}
          {[a.buyerAddressLine1, a.buyerCity, a.buyerState, a.buyerPincode].filter(Boolean).join(', ') || '—'}
        </p>
        {a.buyerMobile && (
          <p className="font-mono mt-0.5">
            <a href={`tel:${a.buyerMobile}`} className="hover:text-brand-600">{a.buyerMobile}</a>
          </p>
        )}
      </div>

      {/* Contextual action per status */}
      <div className="mt-3">
        {a.assignmentStatus === 4 && (
          <button
            onClick={onMarkOfd}
            disabled={ofdPending}
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-stone-900 text-white text-sm font-semibold hover:bg-stone-800 disabled:opacity-50 transition-colors"
          >
            {ofdPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <MapPin className="h-4 w-4" />}
            Mark Out for Delivery
            <ArrowRight className="h-3.5 w-3.5 opacity-70" />
          </button>
        )}
        {a.assignmentStatus === 9 && (
          <button
            onClick={onDeliver}
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-brand-500 text-white text-sm font-semibold hover:bg-brand-600 transition-colors"
          >
            <CheckCircle2 className="h-4 w-4" /> Deliver
            <ArrowRight className="h-3.5 w-3.5 opacity-70" />
          </button>
        )}
        {a.assignmentStatus === 10 && (
          <div className="text-[11px] text-content-subtle italic">
            Picked up — confirm pickup on the Pickups tab to dispatch.
          </div>
        )}
      </div>
    </li>
  );
};

// ── Delivery modal — Send OTP → buyer reads it → verify + proof + COD ───────
const DeliveryModal: React.FC<{
  a: DispatcherAssignment;
  onClose: () => void;
  onDelivered: () => void;
}> = ({ a, onClose, onDelivered }) => {
  const { showToast } = useToast();
  const [otp, setOtp]             = useState('');
  const [otpSent, setOtpSent]     = useState(false);
  const [cod, setCod]             = useState<string>(a.codAmount != null ? String(a.codAmount) : '');

  const sendMut = useMutation({
    mutationFn: () => dispatcherApi.sendDeliveryOtp(a.assignmentId),
    onSuccess: (r) => {
      setOtpSent(true);
      showToast(r.data.message ?? 'OTP sent to buyer.', 'success');
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Could not send OTP.', 'error'),
  });

  const completeMut = useMutation({
    mutationFn: () => {
      // Best-effort GPS — non-blocking, sent if the browser grants it quickly.
      return new Promise<void>((resolve, reject) => {
        const submit = (lat?: number, lng?: number) => {
          dispatcherApi.completeDelivery(a.assignmentId, {
            otp: otp.trim(),
            gpsLat: lat ?? null,
            gpsLng: lng ?? null,
            codAmount: a.codAmount != null && cod.trim() ? Number(cod) : null,
          }).then(() => resolve()).catch(reject);
        };
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (pos) => submit(pos.coords.latitude, pos.coords.longitude),
            () => submit(),                  // denied/failed → submit without GPS
            { timeout: 4000 },
          );
        } else submit();
      });
    },
    onSuccess: () => {
      showToast('Delivered. Order complete.', 'success');
      onDelivered();
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Delivery failed.', 'error'),
  });

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 p-0 sm:p-4" onClick={onClose}>
      <div
        onClick={(e) => e.stopPropagation()}
        className="bg-surface-elevated w-full sm:max-w-md rounded-t-2xl sm:rounded-2xl shadow-2xl"
      >
        <header className="flex items-start justify-between px-5 py-4 border-b border-outline/60">
          <div>
            <h3 className="font-semibold text-content">Complete delivery</h3>
            <p className="text-xs text-content-muted mt-0.5">{a.orderNumber} · {a.buyerName}</p>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg text-content-muted hover:bg-surface">
            <X className="h-5 w-5" />
          </button>
        </header>

        <div className="p-5 space-y-5">
          <div className="text-sm">
            <p className="font-medium text-content">{a.productName}</p>
            <p className="text-xs text-content-muted mt-0.5">
              {[a.buyerAddressLine1, a.buyerCity, a.buyerPincode].filter(Boolean).join(', ')}
            </p>
          </div>

          {/* Step 1 — Send OTP */}
          <div>
            <p className="text-[11px] uppercase tracking-wider font-bold text-content-subtle mb-2">Step 1 · Send OTP</p>
            <button
              onClick={() => sendMut.mutate()}
              disabled={sendMut.isPending}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-stone-900 text-white text-sm font-semibold hover:bg-stone-800 disabled:opacity-50 transition-colors"
            >
              {sendMut.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
              {otpSent ? 'Resend OTP' : 'Send OTP to buyer'}
            </button>
            {otpSent && (
              <p className="text-xs text-emerald-700 mt-2">
                Sent. Ask the buyer to read out the 6-digit code (also in their app notifications).
              </p>
            )}
          </div>

          {/* Step 2 — Enter OTP */}
          <div>
            <p className="text-[11px] uppercase tracking-wider font-bold text-content-subtle mb-2">Step 2 · Enter buyer's OTP</p>
            <input
              inputMode="numeric"
              maxLength={6}
              value={otp}
              onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
              placeholder="••••••"
              className="w-full text-center tracking-[0.5em] text-xl font-mono bg-surface-sunken border border-outline rounded-lg px-3 py-3 focus:outline-none focus:ring-2 focus:ring-brand-300"
            />
          </div>

          {/* Step 3 — COD (only for COD orders) */}
          {a.codAmount != null && (
            <div>
              <p className="text-[11px] uppercase tracking-wider font-bold text-content-subtle mb-2">Step 3 · Collect cash</p>
              <div className="flex items-center gap-2 bg-amber-50 border border-amber-200 rounded-lg px-3 py-2">
                <IndianRupee className="h-4 w-4 text-amber-700" />
                <input
                  inputMode="decimal"
                  value={cod}
                  onChange={(e) => setCod(e.target.value)}
                  className="flex-1 bg-transparent text-sm font-semibold text-amber-800 focus:outline-none"
                />
                <span className="text-[11px] text-amber-700">expected {inr(a.codAmount)}</span>
              </div>
            </div>
          )}
        </div>

        <footer className="px-5 py-4 border-t border-outline/60 flex gap-3">
          <button onClick={onClose} className="px-4 py-2.5 text-sm text-content-muted hover:bg-surface rounded-lg">
            Cancel
          </button>
          <button
            onClick={() => completeMut.mutate()}
            disabled={otp.trim().length !== 6 || completeMut.isPending}
            className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-brand-500 text-white text-sm font-semibold hover:bg-brand-600 disabled:opacity-50 transition-colors"
          >
            {completeMut.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <CheckCircle2 className="h-4 w-4" />}
            Mark delivered
          </button>
        </footer>
      </div>
    </div>
  );
};
