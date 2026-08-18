import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  AlertTriangle, Package, X, History, ArrowDownCircle, ArrowUpCircle,
  Lock, Unlock, Send, Undo2, Sliders, ChevronRight,
} from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { inventoryApi, MOVEMENT_TYPE_LABELS, type StockMatrixRow } from '../../api/inventoryApi';

const PAGE_SIZE = 25;

const MOVEMENT_ICONS: Record<number, React.ElementType> = {
  1: ArrowDownCircle, // Receipt
  2: Sliders,         // Adjustment
  3: Lock,            // Reserve
  4: Unlock,          // Release
  5: Send,            // Ship
  6: Undo2,           // Return
  7: ArrowUpCircle,   // Transfer Out
  8: ArrowDownCircle, // Transfer In
};

const MOVEMENT_TONES: Record<number, string> = {
  1: 'text-emerald-600 bg-emerald-50',
  2: 'text-amber-600 bg-amber-50',
  3: 'text-stone-600 bg-stone-100',
  4: 'text-sky-600 bg-sky-50',
  5: 'text-brand-600 bg-brand-50',
  6: 'text-violet-600 bg-violet-50',
  7: 'text-rose-600 bg-rose-50',
  8: 'text-emerald-600 bg-emerald-50',
};

export const SellerInventoryPage: React.FC = () => {
  const qc = useQueryClient();
  const [search, setSearch]         = useState('');
  const [pageNo, setPageNo]         = useState(1);
  const [warehouseId, setWh]        = useState<number | undefined>();
  const [adjustOpen, setAdjustOpen] = useState<StockMatrixRow | null>(null);
  const [historyRow, setHistoryRow] = useState<StockMatrixRow | null>(null);

  const matrixQ = useQuery({
    queryKey: ['seller-inv', { search, pageNo, warehouseId }],
    queryFn: () =>
      inventoryApi.getMatrix({ search: search || undefined, warehouseId, pageNo, pageSize: PAGE_SIZE })
        .then((r) => r.data.data),
    placeholderData: (prev) => prev,
  });

  const lowQ = useQuery({
    queryKey: ['seller-inv-low'],
    queryFn: () => inventoryApi.getLowStock({ pageNo: 1, pageSize: 10 }).then((r) => r.data.data),
  });

  const warehousesQ = useQuery({
    queryKey: ['seller-warehouses'],
    queryFn: () => inventoryApi.getWarehouses().then((r) => r.data.data),
  });

  const items = matrixQ.data?.items ?? [];
  const total = matrixQ.data?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <SellerLayout>
      <div className="mb-6">
        <h1 className="text-2xl font-display font-bold text-content">Inventory</h1>
        <p className="text-sm text-content-muted mt-1">Stock levels per warehouse — click any row to see movement history.</p>
      </div>

      {/* Summary chips */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-surface-elevated rounded-2xl border border-outline/60 p-4 flex items-start gap-3 shadow-soft">
          <div className="bg-brand-500 p-2 rounded-lg flex-shrink-0">
            <Package className="h-4 w-4 text-white" />
          </div>
          <div>
            <p className="text-xs text-content-muted font-medium uppercase tracking-wide">My SKUs</p>
            <p className="text-2xl font-bold text-content mt-0.5">{total}</p>
          </div>
        </div>
        <div className="bg-surface-elevated rounded-2xl border border-outline/60 p-4 flex items-start gap-3 shadow-soft">
          <div className="bg-amber-500 p-2 rounded-lg flex-shrink-0">
            <AlertTriangle className="h-4 w-4 text-white" />
          </div>
          <div>
            <p className="text-xs text-content-muted font-medium uppercase tracking-wide">Low stock</p>
            <p className="text-2xl font-bold text-content mt-0.5">{lowQ.data?.totalCount ?? 0}</p>
          </div>
        </div>
        <div className="bg-surface-elevated rounded-2xl border border-outline/60 p-4 flex items-start gap-3 shadow-soft">
          <div className="bg-emerald-500 p-2 rounded-lg flex-shrink-0">
            <Package className="h-4 w-4 text-white" />
          </div>
          <div>
            <p className="text-xs text-content-muted font-medium uppercase tracking-wide">Warehouses</p>
            <p className="text-2xl font-bold text-content mt-0.5">{warehousesQ.data?.length ?? 0}</p>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-surface-elevated rounded-2xl border border-outline/60 p-4 mb-6 flex flex-wrap items-end gap-3 shadow-soft">
        <div className="flex-1 min-w-[220px]">
          <label className="block text-xs font-medium text-content-muted mb-1">Search</label>
          <input
            type="text"
            placeholder="SKU or product name"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPageNo(1); }}
            className="w-full bg-surface-sunken border border-outline rounded-lg px-3 py-2 text-sm text-content focus:outline-none focus:ring-2 focus:ring-brand-500/30"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-content-muted mb-1">Warehouse</label>
          <select
            value={warehouseId ?? ''}
            onChange={(e) => { setWh(e.target.value ? Number(e.target.value) : undefined); setPageNo(1); }}
            className="bg-surface-sunken border border-outline rounded-lg px-3 py-2 text-sm text-content focus:outline-none focus:ring-2 focus:ring-brand-500/30"
          >
            <option value="">All warehouses</option>
            {warehousesQ.data?.map((w) => (
              <option key={w.warehouseId} value={w.warehouseId}>{w.code} — {w.name}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Matrix table */}
      <div className="bg-surface-elevated rounded-2xl border border-outline/60 overflow-hidden shadow-soft">
        <table className="w-full text-sm">
          <thead className="bg-surface text-left text-xs font-medium text-content-muted uppercase tracking-wide">
            <tr>
              <th className="px-4 py-3">SKU</th>
              <th className="px-4 py-3">Product</th>
              <th className="px-4 py-3">Warehouse</th>
              <th className="px-4 py-3 text-right">On hand</th>
              <th className="px-4 py-3 text-right">Reserved</th>
              <th className="px-4 py-3 text-right">Available</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-outline/60">
            {matrixQ.isLoading ? (
              [...Array(5)].map((_, i) => (
                <tr key={i}>
                  <td colSpan={7} className="px-4 py-3">
                    <div className="h-8 bg-surface-sunken rounded animate-pulse" />
                  </td>
                </tr>
              ))
            ) : items.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-12 text-center">
                  <Package className="h-10 w-10 text-content-subtle mx-auto mb-2" />
                  <p className="text-content-muted text-sm">No stock rows match your filters.</p>
                </td>
              </tr>
            ) : items.map((row, idx) => {
              const isLow = row.available <= row.lowStockThreshold;
              return (
                <tr key={`${row.variantId}-${row.warehouseId ?? 'none'}-${idx}`} className="hover:bg-surface transition-colors">
                  <td className="px-4 py-3 font-mono text-xs text-content">{row.variantSku}</td>
                  <td className="px-4 py-3">
                    <div className="font-medium text-content">{row.productName}</div>
                    <div className="text-xs text-content-muted">{[row.color, row.size].filter(Boolean).join(' · ') || '—'}</div>
                  </td>
                  <td className="px-4 py-3 text-content-muted">{row.warehouseName ?? '—'}</td>
                  <td className="px-4 py-3 text-right text-content">{row.onHand}</td>
                  <td className="px-4 py-3 text-right text-content-muted">{row.reserved}</td>
                  <td className={`px-4 py-3 text-right font-semibold ${isLow ? 'text-brand-600' : 'text-content'}`}>
                    {row.available}
                    {isLow && <span className="ml-1.5 text-[10px] bg-brand-50 text-brand-600 px-1.5 py-0.5 rounded-full font-medium uppercase">low</span>}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <button
                        onClick={() => setHistoryRow(row)}
                        title="View movement history"
                        className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded text-content-muted hover:bg-surface hover:text-content transition-colors"
                      >
                        <History className="h-3.5 w-3.5" /> History
                      </button>
                      <button
                        onClick={() => setAdjustOpen(row)}
                        disabled={!row.warehouseId}
                        className="text-xs px-2 py-1 rounded text-brand-500 hover:bg-brand-50 disabled:opacity-40 transition-colors"
                      >
                        Adjust
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        <div className="flex items-center justify-between px-4 py-3 border-t border-outline/60 text-sm">
          <span className="text-content-muted">Page {pageNo} of {totalPages} · {total} variants</span>
          <div className="space-x-2">
            <button onClick={() => setPageNo((p) => Math.max(1, p - 1))} disabled={pageNo <= 1}
                    className="px-3 py-1.5 rounded border border-outline text-content hover:bg-surface disabled:opacity-40 transition-colors">Prev</button>
            <button onClick={() => setPageNo((p) => Math.min(totalPages, p + 1))} disabled={pageNo >= totalPages}
                    className="px-3 py-1.5 rounded border border-outline text-content hover:bg-surface disabled:opacity-40 transition-colors">Next</button>
          </div>
        </div>
      </div>

      {adjustOpen && adjustOpen.warehouseId && (
        <AdjustModal
          row={adjustOpen}
          onClose={() => setAdjustOpen(null)}
          onSuccess={() => {
            void qc.invalidateQueries({ queryKey: ['seller-inv'] });
            void qc.invalidateQueries({ queryKey: ['seller-inv-low'] });
            setAdjustOpen(null);
          }}
        />
      )}

      {historyRow && (
        <HistoryDrawer row={historyRow} onClose={() => setHistoryRow(null)} />
      )}
    </SellerLayout>
  );
};

const HistoryDrawer: React.FC<{ row: StockMatrixRow; onClose: () => void }> = ({ row, onClose }) => {
  const q = useQuery({
    queryKey: ['seller-inv-movements', row.variantId, row.warehouseId],
    queryFn: () =>
      inventoryApi.getMovements(row.variantId, {
        warehouseId: row.warehouseId ?? undefined,
        pageNo: 1,
        pageSize: 50,
      }).then((r) => r.data.data),
  });

  const items = q.data?.items ?? [];

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/40" onClick={onClose}>
      <div
        className="bg-surface-elevated w-full max-w-md h-full overflow-y-auto shadow-2xl flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <header className="flex items-center justify-between px-5 py-4 border-b border-outline/60 sticky top-0 bg-surface-elevated z-10">
          <div>
            <h3 className="font-semibold text-content flex items-center gap-2">
              <History className="h-4 w-4 text-brand-500" />
              Movement history
            </h3>
            <p className="text-xs text-content-muted mt-0.5">
              {row.variantSku} · {row.warehouseName ?? 'All warehouses'}
            </p>
          </div>
          <button onClick={onClose} className="p-1.5 rounded hover:bg-surface text-content-muted">
            <X className="h-4 w-4" />
          </button>
        </header>

        <div className="p-5 flex-1">
          {q.isLoading ? (
            <div className="space-y-3">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="h-16 bg-surface-sunken rounded-xl animate-pulse" />
              ))}
            </div>
          ) : items.length === 0 ? (
            <div className="text-center py-12">
              <Package className="h-10 w-10 text-content-subtle mx-auto mb-2" />
              <p className="text-sm text-content-muted">No movements recorded yet.</p>
              <p className="text-xs text-content-subtle mt-1">Adjustments, receipts, and shipments will appear here.</p>
            </div>
          ) : (
            <ol className="relative border-l-2 border-outline/60 ml-3 space-y-4">
              {items.map((m) => {
                const Icon = MOVEMENT_ICONS[m.movementType] ?? Sliders;
                const tone = MOVEMENT_TONES[m.movementType] ?? 'text-content-muted bg-surface';
                const label = MOVEMENT_TYPE_LABELS[m.movementType] ?? 'Unknown';
                const sign = m.quantityDelta > 0 ? '+' : '';
                return (
                  <li key={m.movementId} className="ml-5">
                    <span className={`absolute -left-[14px] flex items-center justify-center h-7 w-7 rounded-full ring-2 ring-surface-elevated ${tone}`}>
                      <Icon className="h-3.5 w-3.5" />
                    </span>
                    <div className="bg-surface rounded-xl border border-outline/60 p-3">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-sm font-semibold text-content">{label}</span>
                        <span className={`text-sm font-mono font-semibold ${m.quantityDelta > 0 ? 'text-emerald-600' : m.quantityDelta < 0 ? 'text-rose-600' : 'text-content-muted'}`}>
                          {sign}{m.quantityDelta}
                        </span>
                      </div>
                      {m.reason && (
                        <p className="text-xs text-content-muted mb-1">{m.reason}</p>
                      )}
                      <div className="flex items-center justify-between text-[11px] text-content-subtle">
                        <span>
                          {new Date(m.changedAt).toLocaleString('en-IN', {
                            day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit',
                          })}
                        </span>
                        {m.changedByEmail && <span className="truncate ml-2">{m.changedByEmail}</span>}
                      </div>
                      {m.referenceType && m.referenceId && (
                        <p className="text-[10px] text-content-subtle mt-1 flex items-center gap-0.5">
                          <ChevronRight className="h-3 w-3" />
                          {m.referenceType} #{m.referenceId}
                        </p>
                      )}
                    </div>
                  </li>
                );
              })}
            </ol>
          )}
        </div>
      </div>
    </div>
  );
};

const AdjustModal: React.FC<{
  row: StockMatrixRow;
  onClose: () => void;
  onSuccess: () => void;
}> = ({ row, onClose, onSuccess }) => {
  const [delta, setDelta]   = useState<number>(0);
  const [reason, setReason] = useState<string>('');
  const [type, setType]     = useState<number>(2);

  const mut = useMutation({
    mutationFn: () =>
      inventoryApi.adjust({
        variantId:     row.variantId,
        warehouseId:   row.warehouseId!,
        quantityDelta: delta,
        reason:        reason || undefined,
        movementType:  type,
      }),
    onSuccess,
  });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-surface-elevated rounded-2xl shadow-2xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <header className="flex items-center justify-between px-5 py-4 border-b border-outline/60">
          <h3 className="font-semibold text-content">Adjust stock</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-surface">
            <X className="h-4 w-4 text-content-muted" />
          </button>
        </header>
        <div className="p-5 space-y-4 text-sm">
          <div className="text-content-muted">
            <span className="font-medium text-content">{row.productName}</span> · {row.variantSku}
            <br />
            Warehouse: <span className="font-medium text-content">{row.warehouseName}</span> · current on-hand <span className="font-mono">{row.onHand}</span>
          </div>

          <label className="block">
            <span className="text-xs font-medium text-content">Movement type</span>
            <select value={type} onChange={(e) => setType(Number(e.target.value))}
                    className="mt-1 w-full bg-surface-sunken border border-outline rounded-lg px-3 py-2 text-content focus:outline-none focus:ring-2 focus:ring-brand-500/30">
              <option value={1}>Receipt (inbound)</option>
              <option value={2}>Adjustment</option>
              <option value={6}>Return</option>
            </select>
          </label>

          <label className="block">
            <span className="text-xs font-medium text-content">Quantity delta (signed)</span>
            <input type="number" value={delta} onChange={(e) => setDelta(Number(e.target.value))}
                   className="mt-1 w-full bg-surface-sunken border border-outline rounded-lg px-3 py-2 text-content focus:outline-none focus:ring-2 focus:ring-brand-500/30" />
            <span className="text-[11px] text-content-subtle mt-1 block">Positive adds stock · Negative removes stock</span>
          </label>

          <label className="block">
            <span className="text-xs font-medium text-content">Reason</span>
            <input type="text" value={reason} onChange={(e) => setReason(e.target.value)}
                   placeholder="e.g. Cycle count correction"
                   className="mt-1 w-full bg-surface-sunken border border-outline rounded-lg px-3 py-2 text-content focus:outline-none focus:ring-2 focus:ring-brand-500/30" />
          </label>

          {mut.isError && (
            <p className="text-xs text-brand-600 bg-brand-50 px-3 py-2 rounded-lg">
              {(mut.error as Error)?.message ?? 'Adjustment failed.'}
            </p>
          )}
        </div>
        <footer className="px-5 py-4 border-t border-outline/60 flex justify-end gap-2">
          <button onClick={onClose} className="px-4 py-2 text-sm text-content-muted hover:bg-surface rounded-lg transition-colors">
            Cancel
          </button>
          <button onClick={() => mut.mutate()} disabled={delta === 0 || mut.isPending}
                  className="px-4 py-2 text-sm bg-brand-500 text-white rounded-lg hover:opacity-90 disabled:opacity-50 transition-opacity">
            {mut.isPending ? 'Adjusting…' : 'Apply'}
          </button>
        </footer>
      </div>
    </div>
  );
};
