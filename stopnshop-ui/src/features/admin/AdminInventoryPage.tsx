import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Package, AlertTriangle, History, X } from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { inventoryApi, MOVEMENT_TYPE_LABELS, type StockMatrixRow } from '../../api/inventoryApi';

const PAGE_SIZE = 25;

export const AdminInventoryPage: React.FC = () => {
  const qc = useQueryClient();
  const [search, setSearch]           = useState('');
  const [pageNo, setPageNo]           = useState(1);
  const [warehouseFilter, setWh]      = useState<number | undefined>();
  const [drawerVariantId, setDrawer]  = useState<number | null>(null);
  const [adjustOpen, setAdjustOpen]   = useState<StockMatrixRow | null>(null);

  const matrixQ = useQuery({
    queryKey: ['inv-matrix', { search, pageNo, warehouseFilter }],
    queryFn: () =>
      inventoryApi.getMatrix({ search: search || undefined, warehouseId: warehouseFilter, pageNo, pageSize: PAGE_SIZE })
        .then((r) => r.data.data),
    placeholderData: (prev) => prev,
  });

  const lowQ = useQuery({
    queryKey: ['inv-low-stock'],
    queryFn: () => inventoryApi.getLowStock({ pageNo: 1, pageSize: 10 }).then((r) => r.data.data),
  });

  const warehousesQ = useQuery({
    queryKey: ['inv-warehouses'],
    queryFn: () => inventoryApi.getWarehouses({ includeInactive: false }).then((r) => r.data.data),
  });

  const items = matrixQ.data?.items ?? [];
  const total = matrixQ.data?.totalCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <AdminLayout>
      <div className="mb-6 flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-display font-bold text-content">Inventory</h1>
          <p className="text-sm text-content-muted mt-1">SKU × warehouse stock matrix with live low-stock alerts</p>
        </div>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <KpiCard
          icon={Package}
          label="SKUs tracked"
          value={total}
          color="bg-blue-500"
          loading={matrixQ.isLoading}
        />
        <KpiCard
          icon={AlertTriangle}
          label="Low-stock variants"
          value={lowQ.data?.totalCount ?? 0}
          color="bg-amber-500"
          loading={lowQ.isLoading}
        />
        <KpiCard
          icon={Package}
          label="Active warehouses"
          value={warehousesQ.data?.length ?? 0}
          color="bg-emerald-500"
          loading={warehousesQ.isLoading}
        />
      </div>

      {/* Filters */}
      <div className="bg-surface-elevated rounded-xl border border-outline/60 p-4 mb-6 flex flex-wrap items-end gap-3">
        <div className="flex-1 min-w-[220px]">
          <label className="block text-xs font-medium text-content-muted mb-1">Search</label>
          <input
            type="text"
            placeholder="SKU or product name"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPageNo(1); }}
            className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/30"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-content-muted mb-1">Warehouse</label>
          <select
            value={warehouseFilter ?? ''}
            onChange={(e) => { setWh(e.target.value ? Number(e.target.value) : undefined); setPageNo(1); }}
            className="border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/30"
          >
            <option value="">All warehouses</option>
            {warehousesQ.data?.map((w) => (
              <option key={w.warehouseId} value={w.warehouseId}>{w.code} — {w.name}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Matrix table */}
      <div className="bg-surface-elevated rounded-xl border border-outline/60 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-surface text-left text-xs font-medium text-content-muted uppercase tracking-wide">
            <tr>
              <th className="px-4 py-3">SKU</th>
              <th className="px-4 py-3">Product</th>
              <th className="px-4 py-3">Seller</th>
              <th className="px-4 py-3">Warehouse</th>
              <th className="px-4 py-3 text-right">On hand</th>
              <th className="px-4 py-3 text-right">Reserved</th>
              <th className="px-4 py-3 text-right">Available</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody>
            {matrixQ.isLoading ? (
              <tr><td colSpan={8} className="px-4 py-10 text-center text-content-subtle">Loading…</td></tr>
            ) : items.length === 0 ? (
              <tr><td colSpan={8} className="px-4 py-10 text-center text-content-subtle">No stock rows found.</td></tr>
            ) : items.map((row, idx) => {
              const isLow = row.available <= row.lowStockThreshold;
              return (
                <tr key={`${row.variantId}-${row.warehouseId ?? 'none'}-${idx}`} className="border-t border-outline/60 hover:bg-surface">
                  <td className="px-4 py-3 font-mono text-xs text-content">{row.variantSku}</td>
                  <td className="px-4 py-3 text-content">
                    <div className="font-medium">{row.productName}</div>
                    <div className="text-xs text-content-muted">
                      {[row.color, row.size].filter(Boolean).join(' · ') || '—'}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-content-muted">{row.sellerName ?? '—'}</td>
                  <td className="px-4 py-3 text-content-muted">{row.warehouseName ?? '—'}</td>
                  <td className="px-4 py-3 text-right text-content">{row.onHand}</td>
                  <td className="px-4 py-3 text-right text-content-muted">{row.reserved}</td>
                  <td className={`px-4 py-3 text-right font-medium ${isLow ? 'text-brand-600' : 'text-content'}`}>
                    {row.available}
                  </td>
                  <td className="px-4 py-3 text-right whitespace-nowrap">
                    <button
                      onClick={() => setAdjustOpen(row)}
                      disabled={!row.warehouseId}
                      className="text-xs px-2 py-1 rounded text-brand-500 hover:bg-brand-50 disabled:opacity-40"
                    >
                      Adjust
                    </button>
                    <button
                      onClick={() => setDrawer(row.variantId)}
                      className="text-xs px-2 py-1 rounded text-content-muted hover:bg-surface"
                    >
                      <History className="inline h-3.5 w-3.5" />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {/* Pagination */}
        <div className="flex items-center justify-between px-4 py-3 border-t border-outline/60 text-sm">
          <span className="text-content-muted">Page {pageNo} of {totalPages} · {total} variants</span>
          <div className="space-x-2">
            <button
              onClick={() => setPageNo((p) => Math.max(1, p - 1))}
              disabled={pageNo <= 1}
              className="px-3 py-1.5 rounded border border-outline text-content disabled:opacity-40"
            >
              Prev
            </button>
            <button
              onClick={() => setPageNo((p) => Math.min(totalPages, p + 1))}
              disabled={pageNo >= totalPages}
              className="px-3 py-1.5 rounded border border-outline text-content disabled:opacity-40"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Low-stock panel */}
      <div className="bg-surface-elevated rounded-xl border border-outline/60 p-5 mt-6">
        <div className="flex items-center gap-2 mb-3">
          <AlertTriangle className="h-4 w-4 text-brand-500" />
          <h2 className="font-semibold text-content">Low stock — top 10</h2>
        </div>
        {lowQ.isLoading ? (
          <div className="text-sm text-content-subtle">Loading…</div>
        ) : (lowQ.data?.items?.length ?? 0) === 0 ? (
          <div className="text-sm text-content-subtle">All variants comfortably above threshold.</div>
        ) : (
          <ul className="divide-y divide-outline/60">
            {lowQ.data!.items.map((r) => (
              <li key={r.variantId} className="py-2 flex items-center justify-between text-sm">
                <div>
                  <div className="font-medium text-content">{r.productName}</div>
                  <div className="text-xs text-content-muted font-mono">{r.variantSku}</div>
                </div>
                <div className="text-right">
                  <div className="text-brand-600 font-semibold">{r.totalAvailable} available</div>
                  <div className="text-xs text-content-muted">threshold {r.lowStockThreshold}</div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      {drawerVariantId !== null && (
        <MovementDrawer variantId={drawerVariantId} onClose={() => setDrawer(null)} />
      )}

      {adjustOpen && adjustOpen.warehouseId && (
        <AdjustModal
          row={adjustOpen}
          onClose={() => setAdjustOpen(null)}
          onSuccess={() => {
            void qc.invalidateQueries({ queryKey: ['inv-matrix'] });
            void qc.invalidateQueries({ queryKey: ['inv-low-stock'] });
            setAdjustOpen(null);
          }}
        />
      )}
    </AdminLayout>
  );
};

// ── Subcomponents ─────────────────────────────────────────────────────────

interface KpiProps { icon: React.ComponentType<{ className?: string }>; label: string; value: number | string; color: string; loading?: boolean }

const KpiCard: React.FC<KpiProps> = ({ icon: Icon, label, value, color, loading }) => (
  <div className="bg-surface-elevated rounded-xl border border-outline/60 p-4 flex items-start gap-3">
    <div className={`${color} p-2 rounded-lg flex-shrink-0`}>
      <Icon className="h-4 w-4 text-white" />
    </div>
    <div>
      <p className="text-xs text-content-muted font-medium">{label}</p>
      <p className="text-xl font-bold text-content mt-0.5">
        {loading ? <span className="inline-block h-5 w-12 bg-surface-sunken rounded animate-pulse" /> : value}
      </p>
    </div>
  </div>
);

const MovementDrawer: React.FC<{ variantId: number; onClose: () => void }> = ({ variantId, onClose }) => {
  const { data, isLoading } = useQuery({
    queryKey: ['inv-movements', variantId],
    queryFn: () => inventoryApi.getMovements(variantId, { pageNo: 1, pageSize: 50 }).then((r) => r.data.data),
  });

  return (
    <div className="fixed inset-0 z-50 flex">
      <div className="flex-1 bg-black/30" onClick={onClose} />
      <aside className="w-[480px] bg-surface-elevated shadow-xl flex flex-col">
        <header className="flex items-center justify-between px-5 py-4 border-b border-outline/60">
          <div>
            <h3 className="font-semibold text-content">Movement history</h3>
            <p className="text-xs text-content-muted">Variant #{variantId}</p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-surface">
            <X className="h-4 w-4 text-content-muted" />
          </button>
        </header>
        <div className="flex-1 overflow-y-auto p-5">
          {isLoading ? (
            <div className="text-sm text-content-subtle">Loading…</div>
          ) : (data?.items?.length ?? 0) === 0 ? (
            <div className="text-sm text-content-subtle">No movements yet.</div>
          ) : (
            <ul className="space-y-3 text-sm">
              {data!.items.map((m) => (
                <li key={m.movementId} className="border border-outline/60 rounded-lg p-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-content">
                      {MOVEMENT_TYPE_LABELS[m.movementType] ?? `Type ${m.movementType}`}
                    </span>
                    <span className="text-xs text-content-subtle">
                      {new Date(m.changedAt).toLocaleString()}
                    </span>
                  </div>
                  <div className="mt-1 flex items-baseline gap-4">
                    {m.quantityDelta !== 0 && (
                      <span className={m.quantityDelta > 0 ? 'text-emerald-600' : 'text-brand-600'}>
                        OnHand {m.quantityDelta > 0 ? '+' : ''}{m.quantityDelta}
                      </span>
                    )}
                    {m.reservedDelta !== 0 && (
                      <span className="text-amber-600">
                        Reserved {m.reservedDelta > 0 ? '+' : ''}{m.reservedDelta}
                      </span>
                    )}
                  </div>
                  <div className="text-xs text-content-muted mt-1">
                    {m.warehouseName ?? '—'} · {m.reason ?? '—'}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </aside>
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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="bg-surface-elevated rounded-xl shadow-2xl w-full max-w-md">
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
            Warehouse: <span className="font-medium">{row.warehouseName}</span> · current on-hand {row.onHand}
          </div>

          <label className="block">
            <span className="text-xs font-medium text-content">Movement type</span>
            <select
              value={type}
              onChange={(e) => setType(Number(e.target.value))}
              className="mt-1 w-full border border-outline rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-500/30"
            >
              <option value={1}>Receipt (inbound)</option>
              <option value={2}>Adjustment</option>
              <option value={6}>Return</option>
            </select>
          </label>

          <label className="block">
            <span className="text-xs font-medium text-content">Quantity delta (signed)</span>
            <input
              type="number"
              value={delta}
              onChange={(e) => setDelta(Number(e.target.value))}
              className="mt-1 w-full border border-outline rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-500/30"
            />
          </label>

          <label className="block">
            <span className="text-xs font-medium text-content">Reason</span>
            <input
              type="text"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="e.g. Cycle count correction"
              className="mt-1 w-full border border-outline rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-500/30"
            />
          </label>

          {mut.isError && (
            <p className="text-xs text-brand-600">
              {(mut.error as Error)?.message ?? 'Adjustment failed.'}
            </p>
          )}
        </div>
        <footer className="px-5 py-4 border-t border-outline/60 flex justify-end gap-2">
          <button onClick={onClose} className="px-4 py-2 text-sm text-content hover:bg-surface rounded">
            Cancel
          </button>
          <button
            onClick={() => mut.mutate()}
            disabled={delta === 0 || mut.isPending}
            className="px-4 py-2 text-sm bg-brand-500 text-white rounded hover:opacity-90 disabled:opacity-50"
          >
            {mut.isPending ? 'Adjusting…' : 'Apply'}
          </button>
        </footer>
      </div>
    </div>
  );
};
