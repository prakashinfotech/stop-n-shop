import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Loader2, MessageSquare, ChevronDown, ChevronUp, Inbox, X } from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import {
  complaintsApi,
  COMPLAINT_STATUS_LABEL,
  type AdminComplaintRow,
} from '../../api/complaintsApi';
import { useToast } from '../../components/ui/Toast';

const PAGE_SIZE = 20;

const STATUS_PILLS: { key: number | undefined; label: string }[] = [
  { key: undefined, label: 'All' },
  { key: 1,         label: 'Open' },
  { key: 2,         label: 'In progress' },
  { key: 3,         label: 'Resolved' },
  { key: 4,         label: 'Closed' },
];

const STATUS_COLORS: Record<number, string> = {
  1: 'bg-amber-100 text-amber-800',
  2: 'bg-blue-100 text-blue-700',
  3: 'bg-emerald-100 text-emerald-800',
  4: 'bg-stone-200 text-stone-700',
};

const CATEGORY_COLORS: Record<string, string> = {
  delivery: 'bg-purple-100 text-purple-700',
  product:  'bg-pink-100 text-pink-700',
  payment:  'bg-amber-100 text-amber-700',
  account:  'bg-blue-100 text-blue-700',
  other:    'bg-stone-100 text-stone-700',
};

export const AdminComplaintsPage: React.FC = () => {
  const qc = useQueryClient();
  const { showToast } = useToast();
  const [statusFilter, setStatusFilter] = useState<number | undefined>(undefined);
  const [page, setPage] = useState(1);
  const [openId, setOpenId] = useState<number | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['admin-complaints', statusFilter, page],
    queryFn: () =>
      complaintsApi
        .adminList({ status: statusFilter, page, pageSize: PAGE_SIZE })
        .then((r) => r.data.data),
  });

  const items: AdminComplaintRow[] = (data as any)?.items ?? [];
  const total: number              = (data as any)?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const updateMut = useMutation({
    mutationFn: ({ id, status, note }: { id: number; status: number; note: string }) =>
      complaintsApi.adminUpdate(id, { status, adminNote: note.trim() || undefined }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-complaints'] });
      showToast('Complaint updated', 'success');
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Update failed', 'error'),
  });

  return (
    <AdminLayout>
      <div className="mb-4">
        <h1 className="text-2xl font-display font-bold text-content flex items-center gap-2">
          <MessageSquare className="h-6 w-6 text-brand-500" /> Complaints
        </h1>
        <p className="text-sm text-content-muted mt-1">
          Buyer-filed tickets from Aria and the support surface. Will move to a dedicated tech-support role later.
        </p>
      </div>

      {/* Status pills */}
      <div className="mb-4 flex flex-wrap items-center gap-2">
        {STATUS_PILLS.map((p) => {
          const active = p.key === statusFilter;
          return (
            <button
              key={String(p.key)}
              onClick={() => { setStatusFilter(p.key); setPage(1); }}
              className={`px-3 py-1 rounded-full text-xs font-medium border transition-colors ${
                active
                  ? 'bg-brand-50 text-brand-700 border-brand-200'
                  : 'bg-surface text-content-muted border-outline hover:text-content'
              }`}
            >
              {p.label}
            </button>
          );
        })}
        <span className="text-xs text-content-muted ml-auto">{total} ticket{total === 1 ? '' : 's'}</span>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-6 w-6 animate-spin text-content-muted" />
        </div>
      ) : items.length === 0 ? (
        <div className="text-center py-20 text-content-muted">
          <Inbox className="h-12 w-12 mx-auto mb-3 text-content-subtle" />
          <p className="text-sm">Nothing to review.</p>
        </div>
      ) : (
        <ul className="space-y-2">
          {items.map((c) => (
            <ComplaintRow
              key={c.complaintId}
              c={c}
              isOpen={openId === c.complaintId}
              onToggle={() => setOpenId((prev) => (prev === c.complaintId ? null : c.complaintId))}
              onSave={(status, note) => updateMut.mutate({ id: c.complaintId, status, note })}
              saving={updateMut.isPending}
            />
          ))}
        </ul>
      )}

      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-3 mt-6 text-sm">
          <button
            disabled={page <= 1}
            onClick={() => setPage((p) => p - 1)}
            className="px-3 py-1.5 border border-outline rounded-lg text-content hover:bg-surface disabled:opacity-40"
          >
            Previous
          </button>
          <span className="text-content-muted">{page} / {totalPages}</span>
          <button
            disabled={page >= totalPages}
            onClick={() => setPage((p) => p + 1)}
            className="px-3 py-1.5 border border-outline rounded-lg text-content hover:bg-surface disabled:opacity-40"
          >
            Next
          </button>
        </div>
      )}
    </AdminLayout>
  );
};

const ComplaintRow: React.FC<{
  c: AdminComplaintRow;
  isOpen: boolean;
  onToggle: () => void;
  onSave: (status: number, note: string) => void;
  saving: boolean;
}> = ({ c, isOpen, onToggle, onSave, saving }) => {
  const [status, setStatus] = useState<number>(c.status);
  const [note, setNote]     = useState<string>(c.adminNote ?? '');

  React.useEffect(() => { setStatus(c.status); setNote(c.adminNote ?? ''); }, [c.complaintId, c.status, c.adminNote]);

  return (
    <li className="bg-surface-elevated border border-outline/60 rounded-2xl overflow-hidden">
      <button
        onClick={onToggle}
        className="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-surface transition-colors"
      >
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5 flex-wrap">
            <span className="font-mono text-xs text-content-subtle">#{c.complaintId}</span>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${STATUS_COLORS[c.status]}`}>
              {COMPLAINT_STATUS_LABEL[c.status] ?? c.status}
            </span>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${CATEGORY_COLORS[c.category] ?? CATEGORY_COLORS.other}`}>
              {c.category}
            </span>
            {c.orderNumber && (
              <span className="text-[10px] text-content-subtle font-mono">{c.orderNumber}</span>
            )}
          </div>
          <p className="font-medium text-content truncate">{c.subject}</p>
          <p className="text-xs text-content-muted">
            From <strong className="font-medium">{c.userName ?? c.userEmail ?? `User #${c.userId}`}</strong> ·{' '}
            {new Date(c.createdAt).toLocaleString('en-IN', {
              day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
            })}
          </p>
        </div>
        {isOpen ? <ChevronUp className="h-4 w-4 text-content-muted" /> : <ChevronDown className="h-4 w-4 text-content-muted" />}
      </button>

      {isOpen && (
        <div className="border-t border-outline/60 px-4 py-4 space-y-4 bg-bg">
          <section>
            <p className="text-xs uppercase tracking-wider text-content-subtle mb-1">Reported</p>
            <p className="text-sm text-content whitespace-pre-line">{c.body}</p>
          </section>

          <section className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-content-muted block mb-1">Status</label>
              <select
                value={status}
                onChange={(e) => setStatus(Number(e.target.value))}
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-elevated text-sm"
              >
                {Object.entries(COMPLAINT_STATUS_LABEL).map(([k, v]) => (
                  <option key={k} value={Number(k)}>{v}</option>
                ))}
              </select>
            </div>
            <div>
              <p className="text-xs font-medium text-content-muted mb-1">Source</p>
              <p className="px-3 py-2 rounded-lg border border-outline bg-surface text-sm text-content-muted">
                {c.source} · user #{c.userId}
              </p>
            </div>
          </section>

          <section>
            <label className="text-xs font-medium text-content-muted block mb-1">Internal note (optional)</label>
            <textarea
              rows={3}
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="What did you do about it? This is shown to the buyer on status change."
              className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
            />
          </section>

          <div className="flex justify-end gap-3">
            <button
              onClick={onToggle}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm text-content-muted hover:text-content"
            >
              <X className="h-3.5 w-3.5" /> Cancel
            </button>
            <button
              onClick={() => onSave(status, note)}
              disabled={saving || (status === c.status && note === (c.adminNote ?? ''))}
              className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-lg bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 disabled:opacity-50"
            >
              {saving && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
              Save changes
            </button>
          </div>
        </div>
      )}
    </li>
  );
};
