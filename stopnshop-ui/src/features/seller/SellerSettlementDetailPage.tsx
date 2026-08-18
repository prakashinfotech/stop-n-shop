import React from 'react';
import { useParams, Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft } from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { Spinner } from '../../components/ui/Spinner';
import { sellerLifecycleApi, SETTLEMENT_STATUS_LABELS } from '../../api/sellerLifecycleApi';

const inr = (n: number) => `₹${n.toLocaleString('en-IN', { maximumFractionDigits: 2 })}`;
const fmtDate = (s: string) => new Date(s).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });

export const SellerSettlementDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const settlementId = Number(id);

  const { data, isLoading } = useQuery({
    queryKey: ['seller-settlement', settlementId],
    enabled: Number.isFinite(settlementId) && settlementId > 0,
    queryFn: () => sellerLifecycleApi.settlements.get(settlementId).then(r => r.data.data),
  });

  return (
    <SellerLayout>
      <Link to="/seller/settlements" className="inline-flex items-center gap-1 text-sm text-content-muted hover:text-content mb-6">
        <ArrowLeft size={14} /> Back to settlements
      </Link>

      {isLoading ? (
        <div className="flex justify-center py-16"><Spinner /></div>
      ) : !data?.settlement ? (
        <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-16 text-center">
          <p className="text-lg font-semibold text-content">Settlement not found</p>
        </div>
      ) : (
        <>
          <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-8 mb-6">
            <div className="flex items-start justify-between mb-6">
              <div>
                <h1 className="text-2xl font-display font-bold text-content">
                  Settlement #{data.settlement.settlementId}
                </h1>
                <p className="text-sm text-content-muted mt-1">
                  {fmtDate(data.settlement.periodStart)} → {fmtDate(data.settlement.periodEnd)}
                </p>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-medium bg-amber-50 text-amber-700">
                {SETTLEMENT_STATUS_LABELS[data.settlement.status] ?? 'Unknown'}
              </span>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-5 gap-6">
              {[
                { label: 'Gross Sales', value: inr(data.settlement.grossSales) },
                { label: 'Commission', value: `−${inr(data.settlement.commissionAmount)}`, tone: 'rose' },
                { label: 'TDS', value: `−${inr(data.settlement.tdsAmount)}`, tone: 'rose' },
                { label: 'Penalty', value: `−${inr(data.settlement.penaltyAmount)}`, tone: 'rose' },
                { label: 'Net Payout', value: inr(data.settlement.netPayout), tone: 'emerald' },
              ].map(({ label, value, tone }) => (
                <div key={label}>
                  <p className="text-xs text-content-muted mb-1">{label}</p>
                  <p className={`text-lg font-semibold ${tone === 'rose' ? 'text-rose-700' : tone === 'emerald' ? 'text-emerald-700' : 'text-content'}`}>
                    {value}
                  </p>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 overflow-hidden">
            <div className="px-6 py-4 border-b border-outline/60">
              <h2 className="text-base font-semibold text-content">Line items ({data.lines.length})</h2>
            </div>
            <table className="w-full text-sm">
              <thead className="bg-surface text-content-muted">
                <tr>
                  <th className="text-left px-4 py-3 font-medium">Order item</th>
                  <th className="text-right px-4 py-3 font-medium">Gross</th>
                  <th className="text-right px-4 py-3 font-medium">Commission</th>
                  <th className="text-right px-4 py-3 font-medium">TDS</th>
                  <th className="text-right px-4 py-3 font-medium">Net</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline/60">
                {data.lines.map(l => (
                  <tr key={l.settlementLineId} className="hover:bg-surface">
                    <td className="px-4 py-3 font-mono text-xs text-content-muted">#{l.orderItemId} (order #{l.orderId})</td>
                    <td className="px-4 py-3 text-right tabular-nums">{inr(l.grossAmount)}</td>
                    <td className="px-4 py-3 text-right tabular-nums text-rose-700">−{inr(l.commissionAmount)}</td>
                    <td className="px-4 py-3 text-right tabular-nums text-rose-700">−{inr(l.tdsAmount)}</td>
                    <td className="px-4 py-3 text-right font-semibold tabular-nums">{inr(l.netAmount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </SellerLayout>
  );
};
