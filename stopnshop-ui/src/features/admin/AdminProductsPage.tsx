import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useLocation } from 'react-router-dom';
import { CheckCircle, XCircle } from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { DataTable } from '../../components/admin/DataTable';
import { adminApi, type AdminProduct } from '../../api/adminApi';
import { useToast } from '../../components/ui/Toast';

const PAGE_SIZE = 20;

export const AdminProductsPage: React.FC = () => {
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const { pathname } = useLocation();
  const [page, setPage] = useState(1);

  const isModerationView = pathname.endsWith('/moderation');

  const { data, isLoading } = useQuery({
    queryKey: ['admin-products', isModerationView ? 'moderation' : 'all', page],
    queryFn: () => {
      const call = isModerationView ? adminApi.products.moderationQueue : adminApi.products.getAll;
      return call({ pageNo: page, pageSize: PAGE_SIZE }).then((r) => r.data.data);
    },
  });

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['admin-products'] });

  const approveMutation = useMutation({
    mutationFn: (id: number) => adminApi.products.approve(id),
    onSuccess: () => { invalidate(); showToast('Product approved'); },
    onError: () => showToast('Action failed', 'error'),
  });
  const rejectMutation = useMutation({
    mutationFn: (id: number) => adminApi.products.reject(id),
    onSuccess: () => { invalidate(); showToast('Product rejected'); },
    onError: () => showToast('Action failed', 'error'),
  });

  const products = (data as any)?.items ?? [];
  const totalCount = (data as any)?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  return (
    <AdminLayout>
      <div className="mb-6">
        <h1 className="text-2xl font-display font-bold text-content">
          {isModerationView ? 'Product Moderation' : 'All Products'}
        </h1>
        <p className="text-sm text-content-muted mt-1">
          {isModerationView
            ? 'Approve or reject pending seller products before they go live'
            : 'Catalog overview — every seller product across the platform'}
        </p>
      </div>

      <DataTable<AdminProduct>
        keyExtractor={(p) => p.id}
        isLoading={isLoading}
        data={products}
        emptyMessage={isModerationView ? 'No products pending moderation.' : 'No products in the catalog yet.'}
        page={page}
        totalPages={totalPages}
        onPageChange={setPage}
        columns={[
          {
            key: 'name',
            header: 'Product',
            render: (p) => (
              <div className="flex items-center gap-3">
                {p.primaryImage && (
                  <img src={p.primaryImage} alt={p.name} className="w-10 h-10 object-cover rounded-lg flex-shrink-0" />
                )}
                <div>
                  <p className="font-medium text-content line-clamp-1">{p.name}</p>
                  <p className="text-xs text-content-subtle">{p.sellerName}</p>
                </div>
              </div>
            ),
          },
          {
            key: 'sellingPrice',
            header: 'Price',
            render: (p) => (
              <div>
                <p className="font-medium">₹{p.sellingPrice.toLocaleString('en-IN')}</p>
                <p className="text-xs text-content-subtle line-through">₹{p.mrp.toLocaleString('en-IN')}</p>
              </div>
            ),
          },
          {
            key: 'isApproved',
            header: 'Status',
            render: (p) => (
              <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                p.isApproved ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
              }`}>
                {p.isApproved ? 'Approved' : 'Pending'}
              </span>
            ),
          },
          {
            key: 'createdAt',
            header: 'Added',
            render: (p) => new Date(p.createdAt).toLocaleDateString('en-IN'),
          },
          {
            key: 'actions',
            header: 'Actions',
            render: (p) => (
              <div className="flex gap-1">
                <button
                  onClick={() => approveMutation.mutate(p.id)}
                  disabled={p.isApproved}
                  title="Approve"
                  className="p-1.5 text-green-500 hover:bg-green-50 rounded-lg transition-colors disabled:opacity-30"
                >
                  <CheckCircle className="h-4 w-4" />
                </button>
                <button
                  onClick={() => rejectMutation.mutate(p.id)}
                  title="Reject"
                  className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <XCircle className="h-4 w-4" />
                </button>
              </div>
            ),
          },
        ]}
      />
    </AdminLayout>
  );
};
