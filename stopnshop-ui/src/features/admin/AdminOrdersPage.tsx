import React, { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { X } from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { DataTable } from '../../components/admin/DataTable';
import { adminApi, type AdminOrder } from '../../api/adminApi';

const STATUS_COLORS: Record<string, string> = {
  PLACED:    'bg-blue-100 text-blue-700',
  CONFIRMED: 'bg-indigo-100 text-indigo-700',
  SHIPPED:   'bg-amber-100 text-amber-700',
  DELIVERED: 'bg-green-100 text-green-700',
  CANCELLED: 'bg-red-100 text-red-700',
};

const PAGE_SIZE = 20;

const LINE_STATUS_LABEL: Record<string, string> = {
  unfulfilled: 'Unfulfilled (awaiting seller confirmation)',
  rejected:    'Rejected by seller',
};
const PAYMENT_STATUS_LABEL: Record<string, string> = {
  paid:     'Paid',
  unpaid:   'Unpaid',
  refunded: 'Refunded',
};

export const AdminOrdersPage: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [page, setPage] = useState(1);

  const lineStatusParam    = searchParams.get('status');
  const paymentStatusParam = searchParams.get('paymentStatus');
  const lineStatus    = lineStatusParam === 'unfulfilled' || lineStatusParam === 'rejected' ? lineStatusParam : undefined;
  const paymentStatus =
    paymentStatusParam === 'paid' || paymentStatusParam === 'unpaid' || paymentStatusParam === 'refunded'
      ? paymentStatusParam
      : undefined;

  const { data, isLoading } = useQuery({
    queryKey: ['admin-orders', page, lineStatus, paymentStatus],
    queryFn: () =>
      adminApi.orders
        .getAll({ pageNo: page, pageSize: PAGE_SIZE, lineStatus, paymentStatus })
        .then((r) => r.data.data),
  });

  const orders = (data as any)?.items ?? [];
  const totalCount = (data as any)?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  const clearFilter = (key: 'status' | 'paymentStatus') => {
    const next = new URLSearchParams(searchParams);
    next.delete(key);
    setSearchParams(next);
    setPage(1);
  };

  const hasFilter = lineStatus || paymentStatus;

  return (
    <AdminLayout>
      <div className="mb-4">
        <h1 className="text-2xl font-display font-bold text-content">All Orders</h1>
        <p className="text-sm text-content-muted mt-1">Platform-wide order history across all sellers</p>
      </div>

      {hasFilter && (
        <div className="mb-4 flex flex-wrap items-center gap-2">
          <span className="text-xs uppercase tracking-wide text-content-muted">Filters:</span>
          {lineStatus && (
            <FilterPill onClear={() => clearFilter('status')}>
              {LINE_STATUS_LABEL[lineStatus]}
            </FilterPill>
          )}
          {paymentStatus && (
            <FilterPill onClear={() => clearFilter('paymentStatus')}>
              Payment: {PAYMENT_STATUS_LABEL[paymentStatus]}
            </FilterPill>
          )}
          <span className="text-xs text-content-muted ml-1">{totalCount} match{totalCount === 1 ? '' : 'es'}</span>
        </div>
      )}

      <DataTable<AdminOrder>
        keyExtractor={(o) => o.id}
        isLoading={isLoading}
        data={orders}
        emptyMessage={hasFilter ? 'No orders match these filters.' : 'No orders found.'}
        page={page}
        totalPages={totalPages}
        onPageChange={setPage}
        columns={[
          { key: 'orderNumber', header: 'Order #', render: (o) => `#${o.orderNumber}` },
          { key: 'customerName', header: 'Customer' },
          { key: 'sellerName', header: 'Seller' },
          {
            key: 'finalAmount',
            header: 'Amount',
            render: (o) => `₹${o.finalAmount.toLocaleString('en-IN')}`,
          },
          {
            key: 'status',
            header: 'Status',
            render: (o) => (
              <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[o.status] ?? 'bg-surface-sunken text-content'}`}>
                {o.status}
              </span>
            ),
          },
          {
            key: 'createdAt',
            header: 'Date',
            render: (o) => new Date(o.createdAt).toLocaleDateString('en-IN', {
              day: 'numeric', month: 'short', year: 'numeric',
            }),
          },
        ]}
      />
    </AdminLayout>
  );
};

const FilterPill: React.FC<{ children: React.ReactNode; onClear: () => void }> = ({ children, onClear }) => (
  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-brand-50 text-brand-700 border border-brand-200 text-xs font-medium">
    {children}
    <button onClick={onClear} aria-label="Remove filter" className="hover:text-brand-900">
      <X className="h-3 w-3" />
    </button>
  </span>
);
