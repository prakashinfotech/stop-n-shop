import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Download, Calendar, Banknote } from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { Spinner } from '../../components/ui/Spinner';
import { sellerLifecycleApi, SETTLEMENT_STATUS_LABELS } from '../../api/sellerLifecycleApi';

const inr = (n: number) => `₹${n.toLocaleString('en-IN', { maximumFractionDigits: 2 })}`;
const fmtDate = (s: string) => new Date(s).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });

const statusClass = (status: number) =>
  status === 2 ? 'bg-emerald-50 text-emerald-700'
  : status === 1 ? 'bg-amber-50 text-amber-700'
  : status === 3 ? 'bg-surface-sunken text-content'
  : 'bg-rose-50 text-rose-700';

export const SellerSettlementsPage: React.FC = () => {
  const [page, setPage] = useState(1);
  const pageSize = 20;

  const { data, isLoading } = useQuery({
    queryKey: ['seller-settlements', page, pageSize],
    queryFn: () => sellerLifecycleApi.settlements.list(page, pageSize).then(r => r.data.data),
    staleTime: 60_000,
  });

  return (
    <SellerLayout>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-display font-bold text-content mb-2">Settlements</h1>
          <p className="text-content-muted">Weekly payouts after T+7 hold — net of commission and TDS.</p>
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-16"><Spinner /></div>
      ) : !data || data.items.length === 0 ? (
        <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-16 text-center">
          <Banknote className="mx-auto text-content-subtle mb-4" size={48} />
          <p className="text-lg font-semibold text-content mb-1">No settlements yet</p>
          <p className="text-sm text-content-muted">Your first payout will appear here once delivered orders clear the 7-day return window.</p>
        </div>
      ) : (
        <>
          <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-surface text-content-muted">
                <tr>
                  <th className="text-left px-4 py-3 font-medium">Period</th>
                  <th className="text-right px-4 py-3 font-medium">Gross</th>
                  <th className="text-right px-4 py-3 font-medium">Commission</th>
                  <th className="text-right px-4 py-3 font-medium">TDS</th>
                  <th className="text-right px-4 py-3 font-medium">Net Payout</th>
                  <th className="text-center px-4 py-3 font-medium">Status</th>
                  <th className="text-right px-4 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline/60">
                {data.items.map(s => (
                  <tr key={s.settlementId} className="hover:bg-surface">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <Calendar size={14} className="text-content-subtle" />
                        <span>{fmtDate(s.periodStart)} → {fmtDate(s.periodEnd)}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right tabular-nums">{inr(s.grossSales)}</td>
                    <td className="px-4 py-3 text-right tabular-nums text-rose-700">−{inr(s.commissionAmount)}</td>
                    <td className="px-4 py-3 text-right tabular-nums text-rose-700">−{inr(s.tdsAmount)}</td>
                    <td className="px-4 py-3 text-right font-semibold tabular-nums">{inr(s.netPayout)}</td>
                    <td className="px-4 py-3 text-center">
                      <span className={`inline-block px-2.5 py-1 rounded-full text-xs font-medium ${statusClass(s.status)}`}>
                        {SETTLEMENT_STATUS_LABELS[s.status] ?? 'Unknown'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Link to={`/seller/settlements/${s.settlementId}`}
                            className="inline-flex items-center gap-1 text-brand-600 hover:text-brand-700 font-medium">
                        <Download size={14} /> Statement
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {data.totalCount > pageSize && (
            <div className="flex items-center justify-between mt-6">
              <p className="text-sm text-content-muted">
                Page {data.page} — {data.totalCount} settlement{data.totalCount === 1 ? '' : 's'}
              </p>
              <div className="flex gap-2">
                <button disabled={page === 1} onClick={() => setPage(p => p - 1)}
                        className="px-3 py-1.5 text-sm border border-outline rounded-md disabled:opacity-40 hover:bg-surface">
                  Previous
                </button>
                <button disabled={page * pageSize >= data.totalCount} onClick={() => setPage(p => p + 1)}
                        className="px-3 py-1.5 text-sm border border-outline rounded-md disabled:opacity-40 hover:bg-surface">
                  Next
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </SellerLayout>
  );
};
