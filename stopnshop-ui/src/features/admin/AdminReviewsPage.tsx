import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { CheckCircle, Star } from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { DataTable } from '../../components/admin/DataTable';
import { adminApi, type AdminReview } from '../../api/adminApi';
import { useToast } from '../../components/ui/Toast';

export const AdminReviewsPage: React.FC = () => {
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery({
    queryKey: ['admin-reviews', page],
    queryFn: () => adminApi.reviews.getAll({ pageNo: page, pageSize: 20 }).then((r) => r.data.data),
  });

  const approveMutation = useMutation({
    mutationFn: (id: number) => adminApi.reviews.approve(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-reviews'] });
      showToast('Review approved');
    },
    onError: () => showToast('Failed to approve review', 'error'),
  });

  const reviews = (data as any)?.items ?? [];
  const totalPages = (data as any)?.totalPages ?? 1;

  return (
    <AdminLayout>
      <div className="mb-6">
        <h1 className="text-2xl font-display font-bold text-content">Review Moderation</h1>
        <p className="text-sm text-content-muted mt-1">Approve user reviews before they appear on products</p>
      </div>

      <DataTable<AdminReview>
        keyExtractor={(r) => r.id}
        isLoading={isLoading}
        data={reviews}
        emptyMessage="No reviews pending moderation."
        page={page}
        totalPages={totalPages}
        onPageChange={setPage}
        columns={[
          { key: 'productName', header: 'Product' },
          { key: 'reviewerName', header: 'Reviewer' },
          {
            key: 'rating',
            header: 'Rating',
            render: (r) => (
              <div className="flex items-center gap-1">
                <Star className="h-3.5 w-3.5 text-amber-400 fill-amber-400" />
                <span className="text-sm font-medium">{r.rating}</span>
              </div>
            ),
          },
          {
            key: 'comment',
            header: 'Comment',
            render: (r) => <p className="line-clamp-2 text-xs text-content-muted max-w-xs">{r.comment}</p>,
          },
          {
            key: 'isApproved',
            header: 'Status',
            render: (r) => (
              <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                r.isApproved ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
              }`}>
                {r.isApproved ? 'Approved' : 'Pending'}
              </span>
            ),
          },
          {
            key: 'createdAt',
            header: 'Date',
            render: (r) => new Date(r.createdAt).toLocaleDateString('en-IN'),
          },
          {
            key: 'actions',
            header: 'Action',
            render: (r) => !r.isApproved ? (
              <button
                onClick={() => approveMutation.mutate(r.id)}
                className="p-1.5 text-green-500 hover:bg-green-50 rounded-lg transition-colors"
                title="Approve"
              >
                <CheckCircle className="h-4 w-4" />
              </button>
            ) : null,
          },
        ]}
      />
    </AdminLayout>
  );
};
