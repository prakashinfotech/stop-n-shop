import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { DataTable } from '../../components/admin/DataTable';
import { adminApi, type AdminUser } from '../../api/adminApi';

const ROLES = ['', 'Customer', 'Seller', 'Admin'];

const PAGE_SIZE = 20;

export const AdminUsersPage: React.FC = () => {
  const [page, setPage] = useState(1);
  const [role, setRole] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['admin-users', page, role],
    queryFn: () => adminApi.users.getAll({ pageNo: page, pageSize: PAGE_SIZE, role: role || undefined }).then((r) => r.data.data),
  });

  const users = (data as any)?.items ?? [];
  const totalCount = (data as any)?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  return (
    <AdminLayout>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-display font-bold text-content">User Management</h1>
          <p className="text-sm text-content-muted mt-1">View all registered users</p>
        </div>
        <select
          value={role}
          onChange={(e) => { setRole(e.target.value); setPage(1); }}
          className="border border-outline rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-brand-400"
        >
          {ROLES.map((r) => (
            <option key={r} value={r}>{r || 'All Roles'}</option>
          ))}
        </select>
      </div>

      <DataTable<AdminUser>
        keyExtractor={(u) => u.id}
        isLoading={isLoading}
        data={users}
        emptyMessage="No users found."
        page={page}
        totalPages={totalPages}
        onPageChange={setPage}
        columns={[
          {
            key: 'name',
            header: 'Name',
            render: (u) => u.firstName ? `${u.firstName} ${u.lastName ?? ''}`.trim() : (u.name ?? '—'),
          },
          { key: 'email', header: 'Email', render: (u) => u.email ?? '—' },
          { key: 'mobile', header: 'Mobile' },
          {
            key: 'role',
            header: 'Role',
            render: (u) => (
              <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                u.role === 'Admin' ? 'bg-purple-100 text-purple-700'
                  : u.role === 'Seller' ? 'bg-blue-100 text-blue-700'
                  : 'bg-surface-sunken text-content'
              }`}>
                {u.role}
              </span>
            ),
          },
          {
            key: 'createdAt',
            header: 'Joined',
            render: (u) => new Date(u.createdAt).toLocaleDateString('en-IN'),
          },
        ]}
      />
    </AdminLayout>
  );
};
