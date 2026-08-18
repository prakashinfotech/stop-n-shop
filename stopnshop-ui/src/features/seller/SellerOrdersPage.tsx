import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Package, Eye } from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { sellerApi } from '../../api/sellerApi';
import { Spinner } from '../../components/ui/Spinner';
import { OrderItemDetailsModal, type OrderDetailsLike } from './OrderItemDetailsModal';

const STATUS_COLORS: Record<string, string> = {
  Pending:   'bg-yellow-100 text-yellow-800',
  Confirmed: 'bg-blue-100 text-blue-800',
  Processing:'bg-blue-100 text-blue-800',
  Shipped:   'bg-indigo-100 text-indigo-800',
  Delivered: 'bg-green-100 text-green-800',
  Cancelled: 'bg-red-100 text-red-800',
  Returned:  'bg-stone-200 text-stone-700',
};

export const SellerOrdersPage: React.FC = () => {
  const [viewing, setViewing] = useState<OrderDetailsLike | null>(null);

  const { data, isLoading, error } = useQuery({
    queryKey: ['seller-orders'],
    queryFn: () => sellerApi.orders.getAll({}).then((r) => r.data.data),
  });

  const orders = (data as any)?.items ?? (Array.isArray(data) ? data : []);

  return (
    <SellerLayout>
      <div className="mb-8">
        <h1 className="text-3xl font-display font-bold text-content mb-2">Orders History</h1>
        <p className="text-content-muted">Read-only view of every customer order. Active fulfilment lives in the Queue.</p>
      </div>

      {isLoading ? (
        <div className="flex justify-center items-center h-64">
          <Spinner size="lg" />
        </div>
      ) : error ? (
        <div className="bg-red-50 text-red-600 p-4 rounded-lg">
          Failed to load orders. Please try again.
        </div>
      ) : orders.length === 0 ? (
        <div className="bg-surface-elevated rounded-2xl shadow-soft p-12 text-center border border-outline/60">
          <div className="w-16 h-16 bg-brand-50 text-brand-500 rounded-full flex items-center justify-center mx-auto mb-4">
            <Package size={24} />
          </div>
          <h3 className="text-lg font-semibold text-content mb-2">No orders yet</h3>
          <p className="text-content-muted">When customers buy your products, the orders will appear here.</p>
        </div>
      ) : (
        <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface border-b border-outline/60">
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Order #</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Date</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Customer</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Total</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Status</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted text-right">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline/60">
                {orders.map((order: any) => {
                  const orderId  = order.orderId ?? order.id;
                  const orderNum = order.orderNumber ?? `#${orderId}`;
                  const status   = order.orderStatus ?? order.status ?? 'Pending';
                  return (
                    <tr key={orderId} className="hover:bg-surface transition-colors">
                      <td className="px-6 py-4 font-mono text-sm text-content">{orderNum}</td>
                      <td className="px-6 py-4 text-content-muted text-sm">
                        {new Date(order.createdAt ?? order.orderDate).toLocaleDateString('en-IN', {
                          day: 'numeric', month: 'short', year: 'numeric',
                        })}
                      </td>
                      <td className="px-6 py-4 text-content text-sm">
                        <div>{order.customerName?.trim() || 'Customer'}</div>
                        {order.customerEmail && (
                          <div className="text-xs text-content-subtle">{order.customerEmail}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 font-medium text-content">
                        ₹{(order.totalAmount ?? order.totalPrice ?? order.finalAmount ?? 0).toLocaleString('en-IN')}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${STATUS_COLORS[status] ?? 'bg-surface-sunken text-content'}`}>
                          {status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button
                          onClick={() => setViewing({
                            orderId,
                            orderNumber:    orderNum,
                            buyerName:      order.customerName,
                            buyerEmail:     order.customerEmail,
                            buyerMobile:    order.customerMobile ?? order.buyerMobile,
                            buyerCity:      order.shippingCity ?? order.buyerCity,
                            buyerPincode:   order.shippingPincode ?? order.buyerPincode,
                            paymentMode:    order.paymentMode,
                            paymentStatus:  order.paymentStatus,
                            totalPrice:     order.totalAmount ?? order.totalPrice ?? order.finalAmount,
                            createdAt:      order.createdAt ?? order.orderDate,
                            orderStatus:    status,
                            productName:    order.firstItemName ?? order.productName,
                            productId:      order.firstItemProductId ?? order.productId,
                            primaryImageUrl: order.primaryImageUrl,
                          })}
                          className="inline-flex items-center gap-1.5 text-xs font-semibold text-brand-600 hover:text-brand-700 hover:bg-brand-50 px-3 py-1.5 rounded-lg transition-colors"
                        >
                          <Eye className="h-3.5 w-3.5" /> View
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Order details modal — read-only view + product reviews */}
      {viewing && (
        <OrderItemDetailsModal item={viewing} onClose={() => setViewing(null)} />
      )}
    </SellerLayout>
  );
};
