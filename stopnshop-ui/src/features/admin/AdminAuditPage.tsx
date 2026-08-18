import React from 'react';
import { useSearchParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { FileClock } from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { DataTable, type Column } from '../../components/admin/DataTable';
import { FilterBar } from '../../components/admin/FilterBar';
import { KpiCard } from '../../components/admin/KpiCard';
import { adminApi, type AdminAuditEntry } from '../../api/adminApi';

const TABLE_OPTIONS = [
  { label: 'All tables', value: '' },
  { label: 'Sellers',    value: 'Sellers' },
  { label: 'Products',   value: 'Products' },
  { label: 'Users',      value: 'Users' },
  { label: 'Orders',     value: 'Orders' },
  { label: 'Coupons',    value: 'Coupons' },
  { label: 'Reviews',    value: 'Reviews' },
];

interface AuditPayload {
  verb?: string;
  data?: Record<string, unknown> | null;
}

const parseNewValues = (raw?: string | null): AuditPayload => {
  if (!raw) return {};
  try { return JSON.parse(raw) as AuditPayload; } catch { return {}; }
};

const formatDate = (iso: string) => {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? iso : d.toLocaleString();
};

export const AdminAuditPage: React.FC = () => {
  // URL-as-state for filters so the audit view is shareable.
  const [params, setParams] = useSearchParams();
  const tableName = params.get('tableName') ?? '';
  const from      = params.get('from')      ?? '';
  const to        = params.get('to')        ?? '';
  const pageNo    = Number(params.get('pageNo') ?? '1');
  const pageSize  = 20;

  const updateParam = (key: string, value: string) => {
    const next = new URLSearchParams(params);
    if (value) next.set(key, value); else next.delete(key);
    if (key !== 'pageNo') next.set('pageNo', '1');
    setParams(next, { replace: true });
  };

  const resetFilters = () => setParams({}, { replace: true });

  const { data, isLoading } = useQuery({
    queryKey: ['admin-audit', { tableName, from, to, pageNo }],
    queryFn: async () => {
      const res = await adminApi.audit.query({
        tableName: tableName || undefined,
        from:      from || undefined,
        to:        to   || undefined,
        pageNo,
        pageSize,
      });
      return res.data.data!;
    },
    placeholderData: (prev) => prev,
  });

  const items = data?.items ?? [];
  const total = data?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / pageSize));

  const verbCounts = React.useMemo(() => {
    const counts: Record<string, number> = {};
    for (const r of items) {
      const v = parseNewValues(r.newValues).verb ?? r.action;
      counts[v] = (counts[v] ?? 0) + 1;
    }
    return counts;
  }, [items]);

  const columns: Column<AdminAuditEntry>[] = [
    {
      key: 'changedAt',
      header: 'When',
      render: (r) => <span className="text-xs text-content-muted">{formatDate(r.changedAt)}</span>,
    },
    {
      key: 'verb',
      header: 'Action',
      render: (r) => {
        const verb = parseNewValues(r.newValues).verb ?? r.action;
        return (
          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-surface-sunken text-content">
            {verb}
          </span>
        );
      },
    },
    {
      key: 'target',
      header: 'Target',
      render: (r) => <span className="font-mono text-xs">{r.tableName}#{r.recordId}</span>,
    },
    {
      key: 'actor',
      header: 'By',
      render: (r) =>
        r.changedByName ? (
          <div className="flex flex-col">
            <span className="text-sm">{r.changedByName}</span>
            <span className="text-xs text-content-muted">{r.changedByEmail ?? `user #${r.changedBy ?? '—'}`}</span>
          </div>
        ) : (
          <span className="text-xs text-content-muted">system</span>
        ),
    },
    {
      key: 'detail',
      header: 'Detail',
      render: (r) => {
        const parsed = parseNewValues(r.newValues);
        if (!parsed.data) return <span className="text-xs text-content-subtle">—</span>;
        return (
          <code className="text-xs text-content break-all">
            {JSON.stringify(parsed.data)}
          </code>
        );
      },
    },
    {
      key: 'ip',
      header: 'IP',
      render: (r) => <span className="font-mono text-xs text-content-muted">{r.ipAddress ?? '—'}</span>,
    },
  ];

  return (
    <AdminLayout>
      <div className="space-y-6">
        <header className="flex items-center gap-3">
          <FileClock className="w-6 h-6 text-[#c41230]" />
          <div>
            <h1 className="text-2xl font-semibold text-content">Audit Trail</h1>
            <p className="text-sm text-content-muted">
              Every admin write to sellers, products, users, orders, and coupons is recorded here.
            </p>
          </div>
        </header>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          <KpiCard label="Entries (page)" value={items.length} hint={`of ${total} total`} />
          <KpiCard label="Approvals"      value={(verbCounts['APPROVE_SELLER'] ?? 0) + (verbCounts['APPROVE_PRODUCT'] ?? 0)} tone="positive" />
          <KpiCard label="Rejections"     value={(verbCounts['REJECT_SELLER'] ?? 0) + (verbCounts['REJECT_PRODUCT'] ?? 0)} tone="warning" />
          <KpiCard label="Suspensions"    value={(verbCounts['SUSPEND_SELLER'] ?? 0) + (verbCounts['SUSPEND_USER'] ?? 0)} tone="danger" />
        </div>

        <FilterBar
          filters={[
            {
              kind: 'select',
              key: 'tableName',
              label: 'Table',
              value: tableName,
              options: TABLE_OPTIONS,
              onChange: (v) => updateParam('tableName', v),
            },
            { kind: 'date', key: 'from', label: 'From', value: from, onChange: (v) => updateParam('from', v) },
            { kind: 'date', key: 'to',   label: 'To',   value: to,   onChange: (v) => updateParam('to', v) },
          ]}
          onReset={tableName || from || to ? resetFilters : undefined}
        />

        <DataTable
          columns={columns}
          data={items}
          isLoading={isLoading}
          emptyMessage="No audit entries match the current filters."
          page={pageNo}
          totalPages={totalPages}
          onPageChange={(p) => updateParam('pageNo', String(p))}
          keyExtractor={(r) => r.auditId}
        />
      </div>
    </AdminLayout>
  );
};
