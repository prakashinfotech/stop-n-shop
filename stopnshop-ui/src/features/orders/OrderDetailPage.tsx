import React, { useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Check, Package, Home, MapPin, Star, X, MessageSquare, Box, Send, Navigation, AlertCircle,
  RotateCcw, HelpCircle, Printer, ChevronLeft, CreditCard, Wallet, Banknote, ShieldCheck, Phone,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { ordersApi } from '../../api/ordersApi';
import { axiosInstance } from '../../api/axiosInstance';
import { useToast } from '../../components/ui/Toast';
import type { OrderItem, OrderDetail } from '../../types/cart.types';

const TRACKING_STEPS = [
  'PLACED', 'CONFIRMED', 'PACKED', 'DISPATCHED',
  'ENROUTE', 'OUT_FOR_DELIVERY', 'DELIVERED',
];

const STEP_ICONS: Record<string, React.ReactNode> = {
  PLACED:            <Package className="h-4 w-4" />,
  CONFIRMED:         <Check className="h-4 w-4" />,
  PACKED:            <Box className="h-4 w-4" />,
  DISPATCHED:        <Send className="h-4 w-4" />,
  ENROUTE:           <MapPin className="h-4 w-4" />,
  OUT_FOR_DELIVERY:  <Navigation className="h-4 w-4" />,
  DELIVERED:         <Home className="h-4 w-4" />,
  MISSED:            <AlertCircle className="h-4 w-4" />,
};

const STEP_LABELS: Record<string, string> = {
  PLACED:            'Order Placed',
  CONFIRMED:         'Received by Store',
  PACKED:            'Packed & Ready',
  DISPATCHED:        'Dispatched',
  ENROUTE:           'En Route',
  OUT_FOR_DELIVERY:  'Out for Delivery',
  DELIVERED:         'Delivered',
  MISSED:            'Delivery Missed',
};

// Buyer-friendly label for the per-item status pill on the items list.
// Drives off OrderItems.OrderStatus (numeric) which can take values the
// Order header CK never reaches (esp. 9 = OutForDelivery).
const LINE_STATUS_PILL: Record<number, { label: string; cls: string }> = {
  3: { label: 'Packed',           cls: 'bg-purple-50 text-purple-700' },
  4: { label: 'Dispatched',       cls: 'bg-amber-50 text-amber-700' },
  9: { label: 'Out for Delivery', cls: 'bg-yellow-50 text-yellow-700' },
  5: { label: 'Delivered',        cls: 'bg-emerald-50 text-emerald-700' },
};

const STATUS_COLORS: Record<string, string> = {
  PLACED:            'bg-blue-100 text-blue-700',
  CONFIRMED:         'bg-indigo-100 text-indigo-700',
  PACKED:            'bg-purple-100 text-purple-700',
  DISPATCHED:        'bg-amber-100 text-amber-700',
  ENROUTE:           'bg-orange-100 text-orange-700',
  OUT_FOR_DELIVERY:  'bg-yellow-100 text-yellow-700',
  DELIVERED:         'bg-green-100 text-green-700',
  MISSED:            'bg-red-100 text-red-700',
  CANCELLED:         'bg-red-100 text-red-700',
  // legacy status aliases kept for backwards compat
  SHIPPED:           'bg-amber-100 text-amber-700',
};

interface ReviewModal {
  item: OrderItem;
  rating: number;
  comment: string;
}

const CANCEL_REASONS = [
  'Want to change color or size',
  'Want to continue shopping (add more items)',
  'Order placed by mistake',
  'Other',
] as const;

// Maps order.paymentMethod to a friendly label + icon for the header pill.
const PAYMENT_META: Record<string, { label: string; icon: React.ReactNode }> = {
  RAZORPAY:   { label: 'Paid · Razorpay',     icon: <ShieldCheck className="h-3.5 w-3.5" /> },
  CARD:       { label: 'Paid · Card',         icon: <CreditCard className="h-3.5 w-3.5" /> },
  UPI:        { label: 'Paid · UPI',          icon: <Wallet     className="h-3.5 w-3.5" /> },
  NETBANKING: { label: 'Paid · Net Banking',  icon: <Wallet     className="h-3.5 w-3.5" /> },
  COD:        { label: 'Cash on Delivery',    icon: <Banknote   className="h-3.5 w-3.5" /> },
  '1':        { label: 'Cash on Delivery',    icon: <Banknote   className="h-3.5 w-3.5" /> },
  '2':        { label: 'Paid · Razorpay',     icon: <ShieldCheck className="h-3.5 w-3.5" /> },
};

export const OrderDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const [reviewModal, setReviewModal] = useState<ReviewModal | null>(null);
  const [reviewedIds, setReviewedIds] = useState<Set<number>>(new Set());
  const [cancelOpen, setCancelOpen] = useState(false);
  const [cancelReason, setCancelReason] = useState<string>(CANCEL_REASONS[0]);
  const [helpOpen, setHelpOpen] = useState(false);

  const cancelOrderMutation = useMutation({
    mutationFn: (reason: string) => ordersApi.cancelOrder(Number(id), reason),
    onSuccess: () => {
      showToast('Order cancelled. Refund (if any) will be processed.', 'success');
      setCancelOpen(false);
      queryClient.invalidateQueries({ queryKey: ['order', id] });
      queryClient.invalidateQueries({ queryKey: ['orders'] });
    },
    onError: (err: any) => {
      const msg = err?.response?.data?.message ?? 'Could not cancel order';
      showToast(msg, 'error');
    },
  });

  const { data: order, isLoading, isError } = useQuery({
    queryKey: ['order', id],
    queryFn: () => ordersApi.getOrderDetail(Number(id)).then((r) => r.data.data),
    enabled: !!id,
  });

  const submitReview = useMutation({
    mutationFn: ({ productId, rating, comment }: { productId: number; rating: number; comment: string }) =>
      axiosInstance.post(`/products/${productId}/reviews`, { rating, comment }),
    onSuccess: () => {
      if (reviewModal) {
        setReviewedIds((prev) => new Set(prev).add(reviewModal.item.productId));
        showToast('Review submitted! It will appear after moderation.');
        setReviewModal(null);
      }
    },
    onError: () => showToast('Failed to submit review', 'error'),
  });

  if (isLoading) {
    return (
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-4">
        <div className="h-8 bg-surface-sunken rounded animate-pulse w-48 mb-6" />
        <div className="h-32 bg-surface-sunken rounded-2xl animate-pulse" />
        <div className="h-48 bg-surface-sunken rounded-2xl animate-pulse" />
      </div>
    );
  }

  if (isError || !order) {
    return (
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-16 text-center">
        <p className="text-content-muted">Order not found.</p>
        <Link to="/user/orders" className="text-brand-500 hover:underline text-sm mt-2 inline-block">
          ← Back to orders
        </Link>
      </div>
    );
  }

  // currentStepIdx no longer used — tracking step logic is computed inline in JSX

  const isCancelled = order.status === 'CANCELLED';
  const isDelivered = order.status === 'DELIVERED';
  const cancelEntry = order.tracking.find((t) => t.status === 'CANCELLED');
  const payment = PAYMENT_META[order.paymentMethod] ?? { label: order.paymentMethod, icon: <CreditCard className="h-3.5 w-3.5" /> };

  // Re-add every still-active line item to the cart (used by the Reorder action).
  // Falls back to a navigate-to-PDP for cancelled lines so the buyer can re-pick a size.
  const handleReorder = async () => {
    showToast('Adding items to your bag…');
    try {
      const ok = order.items.filter((i) => i.lineStatus !== 8);
      // Lazy-import to avoid pulling cart code into the orders bundle on cold load.
      const { cartApi } = await import('../../api/cartApi');
      for (const item of ok) {
        await cartApi.addToCart({
          productId: item.productId,
          sizeLabel: item.sizeLabel ?? '',
          colorName: item.colorName ?? '',
          quantity: item.quantity,
        });
      }
      queryClient.invalidateQueries({ queryKey: ['cart'] });
      showToast('Items added to bag', 'success');
      navigate('/user/cart');
    } catch {
      showToast('Could not add all items. Try one at a time.', 'error');
    }
  };

  return (
    <>
      {/*
        Print-only stylesheet — strips site chrome (header / footer / nav / sticky bars)
        and hides the entire screen view (`[data-printable="false"]`). The dedicated
        InvoiceReceipt below takes over the printed page with a thermal-receipt-style
        document. Margins are tightened via @page.
      */}
      <style>{`
        @media print {
          @page { margin: 14mm; size: A4; }
          header, footer, nav, [data-printable="false"] { display: none !important; }
          html, body { background: white !important; }
          a { color: inherit !important; text-decoration: none !important; }
          [data-receipt="true"] { display: block !important; }
        }
        @media screen {
          [data-receipt="true"] { display: none; }
        }
      `}</style>

      {/* Receipt-style printable — only visible when printing. */}
      <InvoiceReceipt order={order} payment={payment} isCancelled={isCancelled} />

      <div data-printable="false" className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-5">

      {/* Breadcrumb — hidden in print, only meaningful when navigating in-app. */}
      <Link to="/user/orders" className="inline-flex items-center gap-1 text-xs text-content-subtle hover:text-brand-500 transition-colors print:hidden">
        <ChevronLeft className="h-3.5 w-3.5" /> My Orders
      </Link>

      {/* Hero header — gradient surface, status pill, payment + items meta. */}
      <div className={`relative overflow-hidden rounded-3xl border border-outline/60 shadow-soft ${
        isCancelled
          ? 'bg-gradient-to-br from-red-50 via-surface-elevated to-surface-elevated'
          : isDelivered
            ? 'bg-gradient-to-br from-green-50 via-surface-elevated to-surface-elevated'
            : 'bg-gradient-to-br from-amber-50 via-surface-elevated to-brand-50/40'
      }`}>
        {/* Decorative ring */}
        <div className="absolute -right-12 -top-12 w-44 h-44 rounded-full bg-surface-elevated/40" aria-hidden />
        <div className="relative px-6 py-6 sm:px-8 sm:py-7 flex flex-wrap items-start justify-between gap-4">
          <div className="min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <span className={`inline-flex items-center gap-1 text-[11px] font-bold tracking-wider uppercase px-2.5 py-1 rounded-full ${STATUS_COLORS[order.status] ?? 'bg-surface-sunken text-content-muted'}`}>
                {isDelivered && <Check className="h-3 w-3" strokeWidth={3} />}
                {isCancelled && <X className="h-3 w-3" strokeWidth={3} />}
                {order.status}
              </span>
              <span className="inline-flex items-center gap-1 text-[11px] font-medium text-content-muted bg-surface-elevated/80 px-2.5 py-1 rounded-full border border-outline/60">
                {payment.icon} {payment.label}
              </span>
            </div>
            <h1 className="font-display text-2xl sm:text-3xl font-bold text-content mt-3 break-all">
              Order #{order.orderNumber}
            </h1>
            <p className="text-xs text-content-muted mt-1.5">
              Placed on{' '}
              {new Date(order.createdAt).toLocaleDateString('en-IN', {
                day: 'numeric', month: 'long', year: 'numeric',
              })}
              {' · '}
              {order.items.length} {order.items.length === 1 ? 'item' : 'items'}
              {' · '}
              <span className="font-semibold text-content">₹{order.summary.finalAmount.toLocaleString('en-IN')}</span>
            </p>
          </div>
        </div>
      </div>

      {/* Action toolbar — hidden when printing; the printout is for records, not actions. */}
      <div className="flex flex-wrap items-center gap-2 print:hidden">
        <button
          onClick={handleReorder}
          className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-brand-500 hover:bg-brand-600 text-white text-xs font-semibold transition-colors shadow-soft"
        >
          <RotateCcw className="h-3.5 w-3.5" /> Reorder
        </button>
        <button
          onClick={() => setHelpOpen(true)}
          className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full border border-outline-strong text-content text-xs font-semibold hover:bg-surface transition-colors"
        >
          <HelpCircle className="h-3.5 w-3.5" /> Need help?
        </button>
        <button
          onClick={() => window.print()}
          className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full border border-outline-strong text-content text-xs font-semibold hover:bg-surface transition-colors"
        >
          <Printer className="h-3.5 w-3.5" /> Invoice
        </button>
        {order.status === 'PLACED' && (
          <button
            onClick={() => setCancelOpen(true)}
            className="ml-auto inline-flex items-center gap-1.5 px-4 py-2 rounded-full border border-red-200 text-red-600 text-xs font-semibold hover:bg-red-50 transition-colors"
          >
            <X className="h-3.5 w-3.5" /> Cancel order
          </button>
        )}
      </div>

      {/* Tracking timeline — replaced by a cancellation summary when the order is cancelled. */}
      {isCancelled ? null : (
      /* Tracking timeline */
      <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-6">
        <div className="flex items-center justify-between mb-5">
          <h2 className="font-semibold text-content text-sm">Order Tracking</h2>
          {order.status === 'MISSED' && (
            <span className="flex items-center gap-1 text-xs font-semibold text-red-600 bg-red-50 px-2.5 py-1 rounded-full">
              <AlertCircle className="h-3 w-3" /> Delivery Missed
            </span>
          )}
        </div>
        <div className="relative">
          {TRACKING_STEPS.map((trackStep, idx) => {
            // Map legacy SHIPPED → DISPATCHED for older orders
            const normalizedStatus = order.status === 'SHIPPED' ? 'DISPATCHED' : order.status;
            const normalizedIdx = TRACKING_STEPS.indexOf(normalizedStatus);
            const done = idx <= normalizedIdx;
            const isCurrent = idx === normalizedIdx;
            const trackingEntry = order.tracking.find(
              (t) => t.status === trackStep || (trackStep === 'DISPATCHED' && t.status === 'SHIPPED')
            );
            return (
              <div key={trackStep} className="flex gap-4 pb-6 last:pb-0 relative">
                {idx < TRACKING_STEPS.length - 1 && (
                  <div className={`absolute left-4 top-8 w-0.5 h-full -translate-x-0.5 transition-colors ${done && idx < normalizedIdx ? 'bg-green-500' : 'bg-surface-sunken'}`} />
                )}
                <div className={`relative w-8 h-8 rounded-full flex-shrink-0 flex items-center justify-center z-10 transition-colors ${
                  done ? 'bg-green-600 text-white' : 'bg-surface-sunken text-content-subtle'
                } ${isCurrent ? 'ring-2 ring-green-300 ring-offset-2 ring-offset-surface-elevated' : ''}`}>
                  {STEP_ICONS[trackStep] ?? <span className="text-xs">{idx + 1}</span>}
                  {isCurrent && (
                    <span className="absolute inset-0 rounded-full bg-green-500/40 animate-ping" aria-hidden />
                  )}
                </div>
                <div className="pt-1">
                  <p className={`text-sm font-semibold ${done ? 'text-content' : 'text-content-subtle'}`}>
                    {STEP_LABELS[trackStep] ?? trackStep}
                  </p>
                  {trackingEntry ? (
                    <>
                      {trackingEntry.description && (
                        <p className="text-xs text-content-muted mt-0.5">{trackingEntry.description}</p>
                      )}
                      <p className="text-xs text-content-subtle mt-0.5">
                        {new Date(trackingEntry.createdAt).toLocaleString('en-IN', {
                          day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
                        })}
                      </p>
                    </>
                  ) : done && isCurrent ? (
                    <p className="text-xs text-green-600 mt-0.5">Current status</p>
                  ) : null}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      )}

      {/* Cancellation summary — shown only when order.status === CANCELLED. */}
      {isCancelled && (
        <div className="bg-surface-elevated border border-red-100 rounded-2xl p-6">
          <div className="flex items-start gap-4">
            <div className="w-10 h-10 rounded-full bg-red-50 text-red-600 flex items-center justify-center flex-shrink-0">
              <X className="h-5 w-5" strokeWidth={2.5} />
            </div>
            <div className="flex-1 min-w-0">
              <h2 className="font-semibold text-content">This order was cancelled</h2>
              {cancelEntry?.description && (
                <p className="text-sm text-content-muted mt-1">
                  <span className="font-medium text-content">Reason:</span> {cancelEntry.description}
                </p>
              )}
              {cancelEntry?.createdAt && (
                <p className="text-xs text-content-subtle mt-1">
                  Cancelled on{' '}
                  {new Date(cancelEntry.createdAt).toLocaleString('en-IN', {
                    day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
                  })}
                </p>
              )}
              {(order.paymentMethod === 'RAZORPAY' || order.paymentMethod === '2') && (
                <p className="text-xs text-emerald-700 mt-2 inline-flex items-center gap-1">
                  <ShieldCheck className="h-3.5 w-3.5" />
                  Refund of ₹{order.summary.finalAmount.toLocaleString('en-IN')} initiated to your original payment method
                </p>
              )}
              <button
                onClick={handleReorder}
                className="mt-4 inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-brand-500 hover:bg-brand-600 text-white text-xs font-semibold transition-colors print:hidden"
              >
                <RotateCcw className="h-3.5 w-3.5" /> Buy these items again
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delivery address */}
      <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-5">
        <h2 className="font-semibold text-content mb-3 text-sm flex items-center gap-2">
          <MapPin className="h-4 w-4 text-brand-500" /> Delivery Address
        </h2>
        <div className="text-sm text-content-muted space-y-0.5">
          <p className="font-semibold text-content">{order.address.name || 'Delivery contact'}</p>
          {order.address.line1 && (
            <p>{order.address.line1}{order.address.line2 ? `, ${order.address.line2}` : ''}</p>
          )}
          <p>{order.address.city}, {order.address.state} — {order.address.pincode}</p>
          {order.address.mobile && (
            <p className="text-content-subtle text-xs flex items-center gap-1.5 mt-1">
              <Phone className="h-3 w-3" /> {order.address.mobile}
            </p>
          )}
        </div>
      </div>

      {/* Items */}
      <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-5">
        <h2 className="font-semibold text-content mb-4 text-sm">Items ({order.items.length})</h2>
        <div className="space-y-4">
          {order.items.map((item) => {
            const isRejected   = item.lineStatus === 8;
            const isConfirmed  = item.lineStatus === 2;
            const prepaid      = order.paymentMethod === 'RAZORPAY' || order.paymentMethod === '2';
            const lineTotal    = item.sellingPrice * item.quantity;
            return (
              <div key={item.id} className="flex gap-4 group">
                <Link
                  to={`/products/${item.productId}`}
                  className="flex-shrink-0"
                  aria-label={item.productName}
                >
                  <img
                    src={item.imageUrl}
                    alt={item.productName}
                    className={`w-20 h-24 object-cover rounded-xl border border-outline/40 transition-transform group-hover:scale-[1.02] ${isRejected ? 'grayscale opacity-70' : ''}`}
                  />
                </Link>
                <div className="flex-1 min-w-0">
                  <p className="text-[11px] uppercase tracking-wider text-content-muted">{item.brand}</p>
                  <Link to={`/products/${item.productId}`} className="block">
                    <p className={`text-sm font-medium line-clamp-2 hover:text-brand-500 transition-colors ${isRejected ? 'text-content-muted line-through' : 'text-content'}`}>
                      {item.productName}
                    </p>
                  </Link>
                  {/* Meta row — only render chips that have data so empty fields don't show a bare divider. */}
                  <div className="flex flex-wrap items-center gap-1.5 mt-1.5">
                    {item.sizeLabel && item.sizeLabel.trim() && (
                      <span className="inline-flex items-center text-[11px] text-content-muted bg-surface px-2 py-0.5 rounded-full">
                        Size: <span className="font-semibold text-content ml-1">{item.sizeLabel}</span>
                      </span>
                    )}
                    {item.colorName && item.colorName.trim() && (
                      <span className="inline-flex items-center text-[11px] text-content-muted bg-surface px-2 py-0.5 rounded-full">
                        Color: <span className="font-semibold text-content ml-1">{item.colorName}</span>
                      </span>
                    )}
                    <span className="inline-flex items-center text-[11px] text-content-muted bg-surface px-2 py-0.5 rounded-full">
                      Qty: <span className="font-semibold text-content ml-1">{item.quantity}</span>
                    </span>
                  </div>
                  <div className="flex items-center justify-between mt-2">
                    <div>
                      <p className={`text-sm font-semibold tabular-nums ${isRejected ? 'text-content-muted line-through' : 'text-content'}`}>
                        ₹{lineTotal.toLocaleString('en-IN')}
                      </p>
                      {item.quantity > 1 && !isRejected && (
                        <p className="text-[11px] text-content-subtle tabular-nums">
                          ₹{item.sellingPrice.toLocaleString('en-IN')} each
                        </p>
                      )}
                    </div>
                    {isConfirmed && (
                      <span className="flex items-center gap-1 text-xs text-emerald-700 font-medium bg-emerald-50 px-2 py-0.5 rounded-full">
                        <Check className="h-3 w-3" /> Confirmed by seller
                      </span>
                    )}
                    {/* Per-item fulfilment stage. Surfaced from OrderItems.OrderStatus
                        so the buyer can see Packed → Dispatched → Out for Delivery →
                        Delivered even when the order header lags behind. */}
                    {item.lineStatus != null && LINE_STATUS_PILL[item.lineStatus] && (
                      <span className={`flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full uppercase tracking-wider ${LINE_STATUS_PILL[item.lineStatus]!.cls}`}>
                        {LINE_STATUS_PILL[item.lineStatus]!.label}
                      </span>
                    )}
                    {!isRejected && order.status === 'DELIVERED' && (
                      reviewedIds.has(item.productId) ? (
                        <span className="flex items-center gap-1 text-xs text-green-600 font-medium">
                          <Check className="h-3 w-3" /> Reviewed
                        </span>
                      ) : (
                        <button
                          onClick={() => setReviewModal({ item, rating: 5, comment: '' })}
                          className="flex items-center gap-1 text-xs text-brand-500 font-semibold hover:text-brand-600 transition-colors print:hidden"
                        >
                          <MessageSquare className="h-3 w-3" /> Write Review
                        </button>
                      )
                    )}
                  </div>
                  {isRejected && (
                    <div className="mt-2 flex items-start gap-2 text-xs bg-red-50 border border-red-200 rounded-lg px-3 py-2 text-red-700">
                      <AlertCircle className="h-3.5 w-3.5 flex-shrink-0 mt-0.5" />
                      <div className="min-w-0">
                        <p className="font-semibold">Cancelled by seller</p>
                        {item.rejectionReason && (
                          <p className="mt-0.5 text-red-700/90">{item.rejectionReason}</p>
                        )}
                        {prepaid && (
                          <p className="mt-0.5 text-emerald-700">
                            ₹{lineTotal.toLocaleString('en-IN')} refunded to your wallet.
                          </p>
                        )}
                        {item.rejectedAt && (
                          <p className="mt-0.5 text-red-600/70">
                            {new Date(item.rejectedAt).toLocaleString('en-IN', {
                              day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
                            })}
                          </p>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Price breakdown — same shape as the cart summary */}
      <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-5">
        <h2 className="font-semibold text-content mb-4 text-sm">Price Details</h2>
        <div className="space-y-2 text-sm">
          <div className="flex justify-between text-content-muted">
            <span>Total MRP ({order.items.length} {order.items.length === 1 ? 'item' : 'items'})</span>
            <span>₹{order.summary.totalMRP.toLocaleString('en-IN')}</span>
          </div>
          {order.summary.totalDiscount > 0 && (
            <div className="flex justify-between text-green-600">
              <span>Discount on MRP</span>
              <span>−₹{order.summary.totalDiscount.toLocaleString('en-IN')}</span>
            </div>
          )}
          {(order.summary.couponDiscount ?? 0) > 0 && (
            <div className="flex justify-between text-green-600">
              <span>Coupon{order.summary.couponCode ? ` (${order.summary.couponCode})` : ''}</span>
              <span>−₹{order.summary.couponDiscount!.toLocaleString('en-IN')}</span>
            </div>
          )}
          <div className="flex justify-between text-content-muted">
            <span>Delivery</span>
            <span>{order.summary.deliveryCharge === 0 ? <span className="text-green-600 font-medium">FREE</span> : `₹${order.summary.deliveryCharge}`}</span>
          </div>
          <div className="flex justify-between font-bold text-content text-base pt-3 border-t border-outline/60">
            <span>{order.paymentMethod === 'RAZORPAY' ? 'Amount paid' : 'Amount to be paid on delivery'}</span>
            <span>₹{order.summary.finalAmount.toLocaleString('en-IN')}</span>
          </div>
          {(order.summary.totalDiscount + (order.summary.couponDiscount ?? 0)) > 0 && (
            <p className="text-xs text-green-600 font-medium">
              You saved ₹{(order.summary.totalDiscount + (order.summary.couponDiscount ?? 0)).toLocaleString('en-IN')} on this order!
            </p>
          )}
        </div>
      </div>

      <div className="text-center print:hidden">
        <Link
          to="/home/products"
          className="inline-block bg-stone-900 hover:bg-brand-500 text-white font-semibold px-8 py-3 rounded-xl text-sm transition-colors"
        >
          Continue Shopping
        </Link>
      </div>

      {/* Write Review Modal */}
      <AnimatePresence>
        {reviewModal && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setReviewModal(null)}
              className="fixed inset-0 z-40 bg-black/40 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="fixed inset-x-4 top-1/2 -translate-y-1/2 z-50 max-w-md mx-auto bg-surface-elevated rounded-2xl shadow-2xl overflow-hidden"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-outline/60">
                <h3 className="font-display font-bold text-content">Write a Review</h3>
                <button onClick={() => setReviewModal(null)} className="p-1 text-content-subtle hover:text-content-muted">
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="p-6 space-y-5">
                {/* Product info */}
                <div className="flex gap-3">
                  <img src={reviewModal.item.imageUrl} alt={reviewModal.item.productName} className="w-12 h-14 object-cover rounded-lg" />
                  <div>
                    <p className="text-xs text-content-subtle">{reviewModal.item.brand}</p>
                    <p className="text-sm font-medium text-content line-clamp-2">{reviewModal.item.productName}</p>
                  </div>
                </div>

                {/* Star rating */}
                <div>
                  <label className="block text-xs font-semibold text-content-muted mb-2">Rating</label>
                  <div className="flex gap-1">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        onClick={() => setReviewModal((m) => m ? { ...m, rating: star } : m)}
                        className="transition-transform hover:scale-110"
                      >
                        <Star
                          className={`h-7 w-7 transition-colors ${
                            star <= reviewModal.rating ? 'text-amber-400 fill-amber-400' : 'text-content-subtle fill-stone-200'
                          }`}
                        />
                      </button>
                    ))}
                  </div>
                </div>

                {/* Comment */}
                <div>
                  <label className="block text-xs font-semibold text-content-muted mb-2">Your Review</label>
                  <textarea
                    value={reviewModal.comment}
                    onChange={(e) => setReviewModal((m) => m ? { ...m, comment: e.target.value } : m)}
                    rows={4}
                    placeholder="Share your experience with this product…"
                    className="w-full border border-outline rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-brand-400 resize-none"
                  />
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={() => setReviewModal(null)}
                    className="flex-1 py-2.5 border border-outline rounded-xl text-sm font-semibold text-content hover:bg-surface transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() =>
                      submitReview.mutate({
                        productId: reviewModal.item.productId,
                        rating: reviewModal.rating,
                        comment: reviewModal.comment,
                      })
                    }
                    disabled={!reviewModal.comment.trim() || submitReview.isPending}
                    className="flex-1 py-2.5 bg-brand-500 text-white rounded-xl text-sm font-semibold hover:bg-brand-600 transition-colors disabled:opacity-60"
                  >
                    {submitReview.isPending ? 'Submitting…' : 'Submit Review'}
                  </button>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Need help modal — non-blocking support actions. */}
      <AnimatePresence>
        {helpOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setHelpOpen(false)}
              className="fixed inset-0 z-40 bg-black/40 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.96, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: 16 }}
              className="fixed inset-x-4 top-1/2 -translate-y-1/2 z-50 max-w-md mx-auto bg-surface-elevated rounded-2xl shadow-2xl overflow-hidden"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-outline/60">
                <h3 className="font-display font-bold text-content">Need help with this order?</h3>
                <button onClick={() => setHelpOpen(false)} className="p-1 text-content-subtle hover:text-content-muted" aria-label="Close help">
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="p-6 space-y-2">
                {[
                  { label: 'Where is my order?',          desc: 'Check live tracking and ETA.' },
                  { label: 'I want to cancel an item',    desc: 'Cancel a specific item in this order.' },
                  { label: 'Wrong item received',         desc: 'Start a return or replacement request.' },
                  { label: 'Refund status',               desc: 'Track your refund timeline.' },
                  { label: 'Talk to a human',             desc: 'Connect with customer support.' },
                ].map((opt) => (
                  <button
                    key={opt.label}
                    onClick={() => { setHelpOpen(false); showToast('Our team will reach out within 24 hours.', 'success'); }}
                    className="w-full text-left flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-surface transition-colors"
                  >
                    <span className="w-8 h-8 rounded-full bg-brand-50 text-brand-500 flex items-center justify-center flex-shrink-0">
                      <HelpCircle className="h-4 w-4" />
                    </span>
                    <span className="min-w-0">
                      <p className="text-sm font-semibold text-content">{opt.label}</p>
                      <p className="text-xs text-content-muted">{opt.desc}</p>
                    </span>
                  </button>
                ))}
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Cancel Order modal — available until seller accepts (status === PLACED) */}
      {cancelOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="bg-surface-elevated rounded-2xl max-w-md w-full p-6 space-y-4">
            <div className="flex items-start justify-between">
              <h3 className="font-semibold text-content text-lg">Cancel order?</h3>
              <button onClick={() => setCancelOpen(false)} aria-label="Close" className="text-content-subtle hover:text-content-muted">
                <X className="h-5 w-5" />
              </button>
            </div>
            <p className="text-sm text-content-muted">Tell us why you're cancelling. This helps us improve.</p>
            <div className="space-y-2">
              {CANCEL_REASONS.map((r) => (
                <label key={r} className="flex items-center gap-2 cursor-pointer p-2 rounded-lg hover:bg-surface">
                  <input
                    type="radio"
                    name="cancelReason"
                    value={r}
                    checked={cancelReason === r}
                    onChange={() => setCancelReason(r)}
                    className="text-brand-500 focus:ring-brand-300"
                  />
                  <span className="text-sm text-content">{r}</span>
                </label>
              ))}
            </div>
            <div className="flex gap-3 pt-2">
              <button
                onClick={() => setCancelOpen(false)}
                className="flex-1 py-2.5 border border-outline rounded-xl text-sm font-semibold text-content hover:bg-surface transition-colors"
              >
                Keep order
              </button>
              <button
                onClick={() => cancelOrderMutation.mutate(cancelReason)}
                disabled={cancelOrderMutation.isPending}
                className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-semibold hover:bg-red-600 transition-colors disabled:opacity-60"
              >
                {cancelOrderMutation.isPending ? 'Cancelling…' : 'Cancel order'}
              </button>
            </div>
          </div>
        </div>
      )}
      </div>
    </>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// InvoiceReceipt — a thermal-receipt-styled document that becomes visible
// only when printing. Mirrors the Indian tax-invoice convention: centered
// merchant block, double-rule totals, monospace tabular numbers, signature
// strip at the bottom.
// ─────────────────────────────────────────────────────────────────────────
interface ReceiptProps {
  order: OrderDetail;
  payment: { label: string; icon: React.ReactNode };
  isCancelled: boolean;
}

const InvoiceReceipt: React.FC<ReceiptProps> = ({ order, payment, isCancelled }) => {
  const placedAt = new Date(order.createdAt);
  const formattedDate = placedAt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
  const formattedTime = placedAt.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });

  // Indian tax-invoice convention: prices are inclusive of 5% GST for apparel; back-compute
  // the taxable value so the breakdown is realistic on the printout.
  const grandTotal   = order.summary.finalAmount;
  const itemsTotal   = order.items.reduce((acc, it) => acc + it.sellingPrice * it.quantity, 0);
  const delivery     = order.summary.deliveryCharge ?? 0;
  const couponOff    = order.summary.couponDiscount ?? 0;
  const mrpDiscount  = order.summary.totalDiscount ?? 0;
  const taxableValue = Math.round((itemsTotal - couponOff) / 1.05 * 100) / 100;
  const gstAmount    = Math.round((itemsTotal - couponOff - taxableValue) * 100) / 100;

  const fmt = (n: number) => n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

  return (
    <div
      data-receipt="true"
      className="font-mono text-[11px] text-stone-900 leading-snug"
      style={{ fontFamily: '"Courier New", "Roboto Mono", ui-monospace, monospace' }}
    >
      {/* ── Merchant header ── */}
      <div className="text-center pb-3 border-b-2 border-stone-900 border-dashed">
        <p className="font-serif text-2xl font-bold tracking-tight" style={{ fontFamily: 'Georgia, "Times New Roman", serif' }}>
          Stop<span className="text-red-600 italic">N</span>Shop
        </p>
        <p className="mt-0.5 text-[10px] uppercase tracking-[0.2em] text-stone-600">India's Premium Fashion Destination</p>
        <p className="mt-1.5 text-[10px] text-stone-700">123 Fashion Street · Ahmedabad, GJ 380006</p>
        <p className="text-[10px] text-stone-700">GSTIN: 24AAACS1234A1Z5 · CIN: U74999GJ2024PTC123456</p>
        <p className="text-[10px] text-stone-700">care@stopnshop.in · 1800-XXX-XXXX</p>
      </div>

      {/* ── Document title ── */}
      <div className="text-center py-3 border-b border-stone-400 border-dashed">
        <p className="text-[14px] font-bold uppercase tracking-[0.3em]">
          {isCancelled ? 'Cancellation Receipt' : 'Tax Invoice'}
        </p>
        <p className="mt-1 text-[10px] text-stone-600">Original for Recipient</p>
      </div>

      {/* ── Meta + Bill To ── */}
      <div className="grid grid-cols-2 gap-6 py-3 border-b border-stone-400 border-dashed text-[11px]">
        <div>
          <p className="text-stone-500 uppercase text-[9px] tracking-widest mb-1">Invoice Details</p>
          <ReceiptKV k="Invoice #"    v={`SNS/${placedAt.getFullYear()}/${order.orderNumber}`} />
          <ReceiptKV k="Order #"      v={order.orderNumber} />
          <ReceiptKV k="Date"         v={formattedDate} />
          <ReceiptKV k="Time"         v={formattedTime} />
          <ReceiptKV k="Payment"      v={payment.label} />
          <ReceiptKV k="Status"       v={order.status} />
        </div>
        <div>
          <p className="text-stone-500 uppercase text-[9px] tracking-widest mb-1">Bill / Ship To</p>
          <p className="font-bold">{order.address.name || 'Delivery Contact'}</p>
          {order.address.line1 && (
            <p>{order.address.line1}{order.address.line2 ? `, ${order.address.line2}` : ''}</p>
          )}
          <p>{order.address.city}, {order.address.state}</p>
          <p>PIN — {order.address.pincode}</p>
          {order.address.mobile && <p className="mt-1">Tel: {order.address.mobile}</p>}
        </div>
      </div>

      {/* ── Item table ── */}
      <table className="w-full text-[10.5px] my-3" cellPadding={0}>
        <thead>
          <tr className="border-b border-stone-900">
            <th className="text-left  py-1 pr-2 font-bold uppercase text-[9px] tracking-wider w-[6%]">#</th>
            <th className="text-left  py-1 pr-2 font-bold uppercase text-[9px] tracking-wider">Description</th>
            <th className="text-left  py-1 pr-2 font-bold uppercase text-[9px] tracking-wider w-[14%]">HSN/SKU</th>
            <th className="text-right py-1 pr-2 font-bold uppercase text-[9px] tracking-wider w-[6%]">Qty</th>
            <th className="text-right py-1 pr-2 font-bold uppercase text-[9px] tracking-wider w-[14%]">Rate</th>
            <th className="text-right py-1       font-bold uppercase text-[9px] tracking-wider w-[16%]">Amount</th>
          </tr>
        </thead>
        <tbody>
          {order.items.map((it, i) => {
            const lineTotal = it.sellingPrice * it.quantity;
            const variantParts = [it.sizeLabel, it.colorName].filter((x) => x && x.trim()).join(' · ');
            return (
              <tr key={it.id} className="align-top border-b border-stone-300 border-dotted">
                <td className="py-2 pr-2 tabular-nums">{String(i + 1).padStart(2, '0')}</td>
                <td className="py-2 pr-2">
                  <p className="font-semibold">{it.productName}</p>
                  <p className="text-stone-600">{it.brand}{variantParts ? ` · ${variantParts}` : ''}</p>
                </td>
                <td className="py-2 pr-2 tabular-nums text-stone-600">61091000</td>
                <td className="py-2 pr-2 text-right tabular-nums">{it.quantity}</td>
                <td className="py-2 pr-2 text-right tabular-nums">{fmt(it.sellingPrice)}</td>
                <td className="py-2       text-right tabular-nums font-semibold">{fmt(lineTotal)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {/* ── Totals ── */}
      <div className="flex justify-end">
        <div className="w-[58%] text-[11px]">
          <ReceiptTotalRow label="Items Subtotal"        value={fmt(itemsTotal)} />
          {mrpDiscount > 0 && (
            <ReceiptTotalRow label="Discount on MRP"     value={`− ${fmt(mrpDiscount)}`} />
          )}
          {couponOff > 0 && (
            <ReceiptTotalRow label={`Coupon${order.summary.couponCode ? ` (${order.summary.couponCode})` : ''}`} value={`− ${fmt(couponOff)}`} />
          )}
          <ReceiptTotalRow label="Taxable Value"          value={fmt(taxableValue)} />
          <ReceiptTotalRow label="CGST @ 2.5%"            value={fmt(gstAmount / 2)} />
          <ReceiptTotalRow label="SGST @ 2.5%"            value={fmt(gstAmount / 2)} />
          <ReceiptTotalRow label="Delivery"               value={delivery === 0 ? 'FREE' : fmt(delivery)} />

          <div className="border-t-2 border-b-2 border-stone-900 my-1 py-1.5 flex items-baseline justify-between">
            <span className="font-bold uppercase tracking-wider">Grand Total</span>
            <span className="font-bold text-[14px] tabular-nums">₹ {fmt(grandTotal)}</span>
          </div>
          <p className="text-right text-[9px] text-stone-600 mt-1 italic">
            (All amounts in INR · GST inclusive)
          </p>
        </div>
      </div>

      {/* ── Payment status box ── */}
      <div className={`mt-4 border ${isCancelled ? 'border-red-700' : 'border-stone-900'} px-3 py-2 flex items-center justify-between`}>
        <span className="uppercase tracking-widest text-[10px] font-bold">
          {isCancelled ? 'Cancelled' : 'Payment Status'}
        </span>
        <span className="text-[11px]">
          {isCancelled
            ? 'No amount payable'
            : payment.label.toLowerCase().includes('cash')
              ? `₹ ${fmt(grandTotal)} payable on delivery`
              : `₹ ${fmt(grandTotal)} received via ${payment.label.replace(/^Paid\s·\s/, '')}`}
        </span>
      </div>

      {/* ── Amount in words ── */}
      <p className="mt-2 text-[10px] text-stone-700">
        <span className="font-bold uppercase tracking-wider text-[9px]">Amount in words:</span>{' '}
        Rupees {amountToWords(Math.round(grandTotal))} Only
      </p>

      {/* ── Footer / signature strip ── */}
      <div className="mt-5 pt-3 border-t border-stone-400 border-dashed">
        <div className="flex justify-between items-end">
          <div>
            <p className="text-[10px] text-stone-700">Thank you for shopping with StopNShop.</p>
            <p className="text-[9px] text-stone-500 mt-0.5">
              For returns or queries, write to care@stopnshop.in within 7 days of delivery.
            </p>
          </div>
          <div className="text-right">
            <div className="w-40 border-t border-stone-900 pt-1 text-[10px]">
              <p className="font-semibold">Authorized Signatory</p>
              <p className="text-stone-600 text-[9px]">StopNShop Retail Pvt Ltd</p>
            </div>
          </div>
        </div>
        <p className="text-center text-[8px] text-stone-500 mt-4 tracking-[0.25em] uppercase">
          ✶ This is a computer-generated receipt and does not require a physical signature ✶
        </p>
      </div>
    </div>
  );
};

const ReceiptKV: React.FC<{ k: string; v: string }> = ({ k, v }) => (
  <div className="flex items-baseline gap-2">
    <span className="text-stone-600 w-[70px] shrink-0">{k}:</span>
    <span className="font-semibold tabular-nums">{v}</span>
  </div>
);

const ReceiptTotalRow: React.FC<{ label: string; value: string }> = ({ label, value }) => (
  <div className="flex items-baseline justify-between py-0.5">
    <span className="text-stone-700">{label}</span>
    <span className="tabular-nums">{value}</span>
  </div>
);

/** Indian rupee → words. Small implementation, good enough for invoice line. */
function amountToWords(num: number): string {
  if (num === 0) return 'Zero';
  const ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
                'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
  const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
  const twoDigit = (n: number): string => n < 20 ? ones[n] : `${tens[Math.floor(n / 10)]}${n % 10 ? ' ' + ones[n % 10] : ''}`;
  const threeDigit = (n: number): string => {
    const h = Math.floor(n / 100), r = n % 100;
    return [h ? `${ones[h]} Hundred` : '', r ? twoDigit(r) : ''].filter(Boolean).join(' ');
  };
  const crore = Math.floor(num / 10000000);
  const lakh  = Math.floor((num % 10000000) / 100000);
  const thou  = Math.floor((num % 100000) / 1000);
  const rest  = num % 1000;
  return [
    crore ? `${twoDigit(crore)} Crore` : '',
    lakh  ? `${twoDigit(lakh)} Lakh`   : '',
    thou  ? `${twoDigit(thou)} Thousand` : '',
    rest  ? threeDigit(rest) : '',
  ].filter(Boolean).join(' ').trim();
}
