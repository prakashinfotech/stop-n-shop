import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  X, Package, MapPin, CreditCard, User, Phone, Calendar,
  Star, MessageSquare, Loader2,
} from 'lucide-react';
import { reviewsApi } from '../../api/reviewsApi';

/**
 * Read-only order-item details + product reviews surface. Used by:
 *   - SellerOrderQueuePage (opens on row double-click)
 *   - SellerOrdersHistoryPage (opens via "View" button)
 *
 * The shape it accepts is a superset of both pages' row shapes — pass whatever
 * fields you have, missing ones just hide cleanly.
 */
export interface OrderDetailsLike {
  orderItemId?: number;
  orderId?:     number;
  orderNumber:  string;
  productId?:   number;
  productName?: string;
  variantSnapshot?: string;
  variantSku?:  string;
  color?:       string;
  size?:        string;
  quantity?:    number;
  unitPrice?:   number;
  totalPrice?:  number;
  orderStatus?: number | string;
  paymentMode?: number;
  paymentStatus?: number;
  buyerName?:   string;
  buyerMobile?: string;
  buyerCity?:   string;
  buyerPincode?: string;
  buyerEmail?:  string;
  createdAt?:   string;
  confirmedAt?: string;
  primaryImageUrl?: string;
}

const PAYMENT_LABEL: Record<number, string> = { 1: 'Cash on Delivery', 2: 'Online (Prepaid)', 3: 'Wallet' };
const STATUS_LABEL: Record<number, string> = {
  1: 'Placed', 2: 'Confirmed', 3: 'Packed', 4: 'Dispatched',
  9: 'Out for Delivery', 5: 'Delivered',
  6: 'Cancelled', 7: 'Returned', 8: 'Rejected',
};

const inr  = (n?: number) => n == null ? '—' : `₹${n.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
const date = (iso?: string) =>
  iso ? new Date(iso).toLocaleString('en-IN', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—';

interface Props {
  item:    OrderDetailsLike;
  onClose: () => void;
}

export const OrderItemDetailsModal: React.FC<Props> = ({ item, onClose }) => {
  // Reviews for the product on this line. Skipped silently if we don't have a
  // productId (e.g. when invoked from an order-header context without item drill-in).
  const reviewsQ = useQuery({
    queryKey: ['product-reviews', item.productId],
    queryFn: () => reviewsApi.getProductReviews(item.productId!, 1, 5).then((r) => r.data.data),
    enabled: !!item.productId,
    staleTime: 60_000,
  });

  const statusLabel = typeof item.orderStatus === 'number'
    ? (STATUS_LABEL[item.orderStatus] ?? `Status ${item.orderStatus}`)
    : (item.orderStatus ?? '—');

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm px-4 py-6 overflow-y-auto"
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="bg-surface-elevated rounded-2xl shadow-2xl w-full max-w-3xl my-auto"
      >
        {/* Header */}
        <header className="flex items-start justify-between px-6 py-4 border-b border-outline/60 sticky top-0 bg-surface-elevated z-10 rounded-t-2xl">
          <div>
            <h3 className="text-lg font-semibold text-content">Order details</h3>
            <p className="text-xs text-content-muted mt-0.5 font-mono">{item.orderNumber}</p>
          </div>
          <button
            onClick={onClose}
            aria-label="Close"
            className="p-1.5 rounded-lg text-content-muted hover:text-content hover:bg-surface transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </header>

        <div className="p-6 space-y-6">

          {/* Status pill */}
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-stone-100 text-stone-800 text-xs font-bold uppercase tracking-wider">
            <Package className="h-3.5 w-3.5" /> {statusLabel}
          </div>

          {/* Product card */}
          <section className="grid grid-cols-[auto_1fr] gap-4 items-start">
            {item.primaryImageUrl && (
              <img
                src={item.primaryImageUrl}
                alt=""
                className="w-24 h-24 rounded-xl object-cover border border-outline/40"
              />
            )}
            <div className="min-w-0">
              <p className="font-semibold text-content">{item.productName ?? '—'}</p>
              {item.variantSnapshot && (
                <p className="text-sm text-content-muted mt-0.5">{item.variantSnapshot}</p>
              )}
              <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-sm">
                {item.size && (
                  <DetailChip label="Size"  value={item.size} />
                )}
                {item.color && (
                  <DetailChip label="Color" value={item.color} />
                )}
                {item.variantSku && (
                  <DetailChip label="SKU" value={item.variantSku} mono />
                )}
              </div>
              <div className="mt-3 flex flex-wrap gap-x-6 gap-y-1 text-sm">
                {item.quantity != null && (
                  <span><span className="text-content-muted">Qty</span> <strong>{item.quantity}</strong></span>
                )}
                {item.unitPrice != null && (
                  <span><span className="text-content-muted">Unit</span> <strong>{inr(item.unitPrice)}</strong></span>
                )}
                {item.totalPrice != null && (
                  <span><span className="text-content-muted">Total</span> <strong>{inr(item.totalPrice)}</strong></span>
                )}
              </div>
            </div>
          </section>

          {/* Two-column meta grid */}
          <section className="grid sm:grid-cols-2 gap-4">
            <DetailPanel icon={<User className="h-4 w-4" />} title="Buyer">
              {item.buyerName  && <p className="font-medium text-content">{item.buyerName}</p>}
              {item.buyerEmail && <p className="text-content-muted text-xs">{item.buyerEmail}</p>}
              {item.buyerMobile && (
                <p className="text-content-muted text-xs flex items-center gap-1">
                  <Phone className="h-3 w-3" /> {item.buyerMobile}
                </p>
              )}
            </DetailPanel>

            <DetailPanel icon={<MapPin className="h-4 w-4" />} title="Ship to">
              {item.buyerCity || item.buyerPincode
                ? <p className="text-content">{[item.buyerCity, item.buyerPincode].filter(Boolean).join(' · ')}</p>
                : <p className="text-content-muted text-sm">No address available</p>}
            </DetailPanel>

            <DetailPanel icon={<CreditCard className="h-4 w-4" />} title="Payment">
              <p className="text-content">{item.paymentMode != null ? PAYMENT_LABEL[item.paymentMode] ?? '—' : '—'}</p>
              <p className={`text-xs font-medium ${item.paymentStatus === 2 ? 'text-emerald-700' : 'text-amber-700'}`}>
                {item.paymentStatus === 2 ? 'Paid' : 'Pending'}
              </p>
            </DetailPanel>

            <DetailPanel icon={<Calendar className="h-4 w-4" />} title="Timeline">
              {item.createdAt && (
                <p className="text-content text-sm"><span className="text-content-muted text-xs">Placed</span> {date(item.createdAt)}</p>
              )}
              {item.confirmedAt && (
                <p className="text-content text-sm"><span className="text-content-muted text-xs">Confirmed</span> {date(item.confirmedAt)}</p>
              )}
            </DetailPanel>
          </section>

          {/* Reviews — only if we know the productId */}
          {item.productId && (
            <section className="border-t border-outline/60 pt-5">
              <div className="flex items-center justify-between mb-3">
                <h4 className="font-semibold text-content flex items-center gap-2">
                  <MessageSquare className="h-4 w-4 text-brand-500" /> Reviews for this product
                </h4>
                {reviewsQ.data && reviewsQ.data.totalCount > 0 && (
                  <div className="inline-flex items-center gap-1.5 text-sm">
                    <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
                    <span className="font-semibold">{reviewsQ.data.averageRating.toFixed(1)}</span>
                    <span className="text-content-muted">· {reviewsQ.data.totalCount} review{reviewsQ.data.totalCount === 1 ? '' : 's'}</span>
                  </div>
                )}
              </div>

              {reviewsQ.isLoading ? (
                <div className="flex items-center gap-2 text-content-muted text-sm py-4">
                  <Loader2 className="h-4 w-4 animate-spin" /> Loading reviews…
                </div>
              ) : !reviewsQ.data || reviewsQ.data.totalCount === 0 ? (
                <div className="bg-surface/40 rounded-xl border border-dashed border-outline p-5 text-center">
                  <MessageSquare className="h-6 w-6 text-content-subtle mx-auto mb-2" />
                  <p className="text-sm text-content-muted">No reviews for this product yet.</p>
                </div>
              ) : (
                <ul className="space-y-3">
                  {reviewsQ.data.items.map((r) => (
                    <li key={r.reviewId} className="bg-surface/50 border border-outline/60 rounded-xl p-3">
                      <div className="flex items-center justify-between mb-1">
                        <p className="text-sm font-semibold text-content">{r.reviewerName}</p>
                        <div className="flex items-center gap-0.5">
                          {Array.from({ length: 5 }).map((_, i) => (
                            <Star
                              key={i}
                              className={`h-3.5 w-3.5 ${i < r.rating ? 'fill-amber-400 text-amber-400' : 'text-stone-300'}`}
                            />
                          ))}
                        </div>
                      </div>
                      {r.title && <p className="text-sm font-medium text-content">{r.title}</p>}
                      {r.body && <p className="text-sm text-content-muted mt-0.5 whitespace-pre-wrap">{r.body}</p>}
                      <p className="text-[10px] text-content-subtle mt-1.5">{date(r.createdAt)}</p>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          )}
        </div>
      </div>
    </div>
  );
};

const DetailChip: React.FC<{ label: string; value: string; mono?: boolean }> = ({ label, value, mono }) => (
  <span className="inline-flex items-center gap-1.5 text-xs">
    <span className="text-content-muted uppercase tracking-wider text-[10px]">{label}</span>
    <span className={`font-semibold text-content ${mono ? 'font-mono' : ''}`}>{value}</span>
  </span>
);

const DetailPanel: React.FC<{ icon: React.ReactNode; title: string; children: React.ReactNode }> = ({ icon, title, children }) => (
  <div className="bg-surface/40 border border-outline/60 rounded-xl p-3">
    <p className="text-[10px] uppercase tracking-widest text-content-muted font-bold flex items-center gap-1.5 mb-1.5">
      <span className="text-brand-500">{icon}</span> {title}
    </p>
    <div className="space-y-0.5">{children}</div>
  </div>
);
