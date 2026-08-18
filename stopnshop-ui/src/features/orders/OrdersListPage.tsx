import React from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Package, ChevronRight } from 'lucide-react';
import { ordersApi } from '../../api/ordersApi';

const STATUS_COLORS: Record<string, string> = {
  PLACED:            'bg-blue-100 text-blue-700',
  CONFIRMED:         'bg-indigo-100 text-indigo-700',
  PACKED:            'bg-purple-100 text-purple-700',
  DISPATCHED:        'bg-amber-100 text-amber-700',
  SHIPPED:           'bg-amber-100 text-amber-700',   // legacy alias
  OUT_FOR_DELIVERY:  'bg-yellow-100 text-yellow-700',
  DELIVERED:         'bg-green-100 text-green-700',
  CANCELLED:         'bg-red-100 text-red-700',
  RETURNED:          'bg-stone-200 text-stone-700',
  REJECTED:          'bg-red-100 text-red-700',
};

// Friendly labels — turns "OUT_FOR_DELIVERY" into "Out for Delivery" so the
// pill reads as a sentence, not a constant.
const STATUS_LABELS: Record<string, string> = {
  PLACED:            'Placed',
  CONFIRMED:         'Confirmed',
  PACKED:            'Packed',
  DISPATCHED:        'Dispatched',
  SHIPPED:           'Dispatched',
  OUT_FOR_DELIVERY:  'Out for Delivery',
  DELIVERED:         'Delivered',
  CANCELLED:         'Cancelled',
  RETURNED:          'Returned',
  REJECTED:          'Rejected',
};

export const OrdersListPage: React.FC = () => {
  const { data: orders = [], isLoading, isError } = useQuery({
    queryKey: ['orders'],
    queryFn: () => ordersApi.getOrders().then((r) => r.data.data),
  });

  if (isLoading) {
    return (
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-3">
        <div className="h-8 bg-surface-sunken rounded animate-pulse w-40 mb-6" />
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-24 bg-surface-sunken rounded-2xl animate-pulse" />
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-16 text-center text-red-500 text-sm">
        Failed to load orders.
      </div>
    );
  }

  if (orders.length === 0) {
    return (
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-20 text-center">
        <Package className="h-16 w-16 text-content-subtle mx-auto mb-4" />
        <h2 className="font-display text-2xl font-bold text-content mb-2">No orders yet</h2>
        <p className="text-content-muted text-sm mb-6">Start shopping to see your orders here.</p>
        <Link
          to="/products"
          className="inline-block bg-stone-900 hover:bg-brand-500 text-white font-semibold px-8 py-3 rounded-xl text-sm transition-colors"
        >
          Continue Shopping
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <h1 className="font-display text-2xl font-bold text-content mb-8">My Orders</h1>

      <div className="space-y-3">
        {orders.map((order) => (
          <Link
            key={order.id}
            to={`/user/orders/${order.id}`}
            className="flex items-center gap-4 bg-surface-elevated border border-outline/60 rounded-2xl p-4 hover:shadow-md transition-shadow"
          >
            {order.primaryImage ? (
              <img
                src={order.primaryImage}
                alt=""
                className="w-16 h-20 object-cover rounded-lg flex-shrink-0"
              />
            ) : (
              <div className="w-16 h-20 bg-surface-sunken rounded-lg flex-shrink-0 flex items-center justify-center">
                <Package className="h-6 w-6 text-content-subtle" />
              </div>
            )}

            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <p className="text-xs text-content-subtle">Order #{order.orderNumber}</p>
                  <p className="text-sm font-semibold text-content mt-0.5">
                    {order.itemCount} item{order.itemCount !== 1 ? 's' : ''}
                  </p>
                </div>
                <span
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full flex-shrink-0 uppercase tracking-wider ${
                    STATUS_COLORS[order.status] ?? 'bg-surface-sunken text-content-muted'
                  }`}
                >
                  {STATUS_LABELS[order.status] ?? order.status}
                </span>
              </div>
              <div className="flex items-center justify-between mt-2">
                <p className="text-xs text-content-subtle">
                  {new Date(order.createdAt).toLocaleDateString('en-IN', {
                    day: 'numeric', month: 'short', year: 'numeric',
                  })}
                </p>
                <p className="text-sm font-bold text-content">
                  ₹{order.finalAmount.toLocaleString('en-IN')}
                </p>
              </div>
            </div>

            <ChevronRight className="h-4 w-4 text-content-subtle flex-shrink-0" />
          </Link>
        ))}
      </div>
    </div>
  );
};
