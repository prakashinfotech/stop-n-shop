import React, { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { CheckCircle, XCircle, PauseCircle, X } from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { DataTable } from '../../components/admin/DataTable';
import { adminApi, type AdminSeller } from '../../api/adminApi';
import { useToast } from '../../components/ui/Toast';

const PAGE_SIZE = 20;

// Seller.ApprovalStatus: 1=Pending, 2=Approved, 3=Rejected, 4=Suspended
const STATUS_LABEL: Record<string, { byte: number; label: string }> = {
  pending:   { byte: 1, label: 'Pending approval' },
  approved:  { byte: 2, label: 'Approved sellers' },
  rejected:  { byte: 3, label: 'Rejected sellers' },
  suspended: { byte: 4, label: 'Suspended sellers' },
};

export const AdminSellersPage: React.FC = () => {
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [searchParams, setSearchParams] = useSearchParams();

  const statusParam = searchParams.get('status');
  const statusKey   = statusParam && STATUS_LABEL[statusParam] ? statusParam : undefined;
  const approvalStatus = statusKey ? STATUS_LABEL[statusKey].byte : undefined;

  const { data, isLoading } = useQuery({
    queryKey: ['admin-sellers', page, approvalStatus],
    queryFn: () =>
      adminApi.sellers.getAll({ pageNo: page, pageSize: PAGE_SIZE, approvalStatus }).then((r) => r.data.data),
  });

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['admin-sellers'] });

  const approveMutation = useMutation({
    mutationFn: (id: number) => adminApi.sellers.approve(id),
    onSuccess: () => { invalidate(); showToast('Seller approved'); },
    onError: () => showToast('Action failed', 'error'),
  });
  const rejectMutation = useMutation({
    mutationFn: (id: number) => adminApi.sellers.reject(id),
    onSuccess: () => { invalidate(); showToast('Seller rejected'); },
    onError: () => showToast('Action failed', 'error'),
  });
  const suspendMutation = useMutation({
    mutationFn: (id: number) => adminApi.sellers.suspend(id),
    onSuccess: () => { invalidate(); showToast('Seller suspended'); },
    onError: () => showToast('Action failed', 'error'),
  });

  const sellers = (data as any)?.items ?? [];
  const totalCount = (data as any)?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  const setStatusFilter = (next: string | undefined) => {
    const params = new URLSearchParams(searchParams);
    if (next) params.set('status', next); else params.delete('status');
    setSearchParams(params);
    setPage(1);
  };

  return (
    <AdminLayout>
      <div className="mb-4">
        <h1 className="text-2xl font-display font-bold text-content">Seller Management</h1>
        <p className="text-sm text-content-muted mt-1">Approve, reject, or suspend seller accounts</p>
      </div>

      {/* Filter pills */}
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <button
          onClick={() => setStatusFilter(undefined)}
          className={`px-3 py-1 rounded-full text-xs font-medium border ${
            !statusKey
              ? 'bg-brand-50 text-brand-700 border-brand-200'
              : 'bg-surface text-content-muted border-outline hover:text-content'
          }`}
        >
          All
        </button>
        {Object.entries(STATUS_LABEL).map(([key, { label }]) => (
          <button
            key={key}
            onClick={() => setStatusFilter(key)}
            className={`px-3 py-1 rounded-full text-xs font-medium border ${
              statusKey === key
                ? 'bg-brand-50 text-brand-700 border-brand-200'
                : 'bg-surface text-content-muted border-outline hover:text-content'
            }`}
          >
            {label}
          </button>
        ))}
        {statusKey && (
          <button
            onClick={() => setStatusFilter(undefined)}
            className="text-xs text-content-subtle hover:text-content inline-flex items-center gap-1"
          >
            <X className="h-3 w-3" /> Clear
          </button>
        )}
        <span className="text-xs text-content-muted ml-auto">{totalCount} seller{totalCount === 1 ? '' : 's'}</span>
      </div>

      <DataTable<AdminSeller>
        keyExtractor={(s) => s.id}
        isLoading={isLoading}
        data={sellers}
        emptyMessage={statusKey ? `No ${statusKey} sellers.` : 'No sellers found.'}
        page={page}
        totalPages={totalPages}
        onPageChange={setPage}
        columns={[
          { key: 'businessName', header: 'Business' },
          { key: 'ownerName', header: 'Owner' },
          { key: 'email', header: 'Email' },
          { key: 'phoneNumber', header: 'Phone' },
          {
            key: 'isApproved',
            header: 'Status',
            render: (s) => (
              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                s.isApproved && s.isActive ? 'bg-green-100 text-green-700'
                  : !s.isActive ? 'bg-red-100 text-red-700'
                  : 'bg-yellow-100 text-yellow-700'
              }`}>
                {s.isApproved && s.isActive ? 'Approved' : !s.isActive ? 'Suspended' : 'Pending'}
              </span>
            ),
          },
          {
            key: 'createdAt',
            header: 'Joined',
            render: (s) => new Date(s.createdAt).toLocaleDateString('en-IN'),
          },
          {
            key: 'actions',
            header: 'Actions',
            render: (s) => (
              <div className="flex items-center gap-1">
                <button
                  onClick={() => approveMutation.mutate(s.id)}
                  title="Approve"
                  disabled={s.isApproved && s.isActive}
                  className="p-1.5 text-green-500 hover:bg-green-50 rounded-lg transition-colors disabled:opacity-30"
                >
                  <CheckCircle className="h-4 w-4" />
                </button>
                <button
                  onClick={() => rejectMutation.mutate(s.id)}
                  title="Reject"
                  className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <XCircle className="h-4 w-4" />
                </button>
                <button
                  onClick={() => suspendMutation.mutate(s.id)}
                  title="Suspend"
                  className="p-1.5 text-amber-500 hover:bg-amber-50 rounded-lg transition-colors"
                >
                  <PauseCircle className="h-4 w-4" />
                </button>
              </div>
            ),
          },
        ]}
      />
    </AdminLayout>
  );
};
