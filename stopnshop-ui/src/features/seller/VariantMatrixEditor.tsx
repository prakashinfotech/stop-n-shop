import React, { useMemo, useState } from 'react';

export interface VariantOption {
  value: string;
  hex?: string | null;
}

export interface VariantCell {
  color: string | null;
  size: string | null;
  stockQuantity: number;
  additionalPrice?: number;
}

interface Props {
  colors: VariantOption[];
  sizes:  VariantOption[];
  value:  VariantCell[];
  onChange: (next: VariantCell[]) => void;
}

const keyFor = (color: string | null, size: string | null) => `${color ?? ''}|${size ?? ''}`;

/**
 * Color × Size stock grid. Sellers enter a per-cell quantity; the parent
 * persists the resulting cells alongside the product on save.
 *
 * If only colors OR only sizes are provided, renders a single-axis list.
 * If both are empty the parent should fall back to the legacy single-variant flow.
 */
export const VariantMatrixEditor: React.FC<Props> = ({ colors, sizes, value, onChange }) => {
  const [bulkQty, setBulkQty] = useState<string>('');

  const cellMap = useMemo(() => {
    const m = new Map<string, VariantCell>();
    value.forEach((c) => m.set(keyFor(c.color, c.size), c));
    return m;
  }, [value]);

  const getCell = (color: string | null, size: string | null): VariantCell =>
    cellMap.get(keyFor(color, size)) ?? { color, size, stockQuantity: 0 };

  const setCell = (next: VariantCell) => {
    const k = keyFor(next.color, next.size);
    const others = value.filter((c) => keyFor(c.color, c.size) !== k);
    onChange([...others, next]);
  };

  const applyBulkToAll = () => {
    const qty = Math.max(0, Math.floor(Number(bulkQty) || 0));
    const colorAxis = colors.length > 0 ? colors.map((c) => c.value) : [null];
    const sizeAxis  = sizes.length  > 0 ? sizes.map((s) => s.value)  : [null];
    const next: VariantCell[] = [];
    for (const c of colorAxis) {
      for (const s of sizeAxis) {
        next.push({ color: c, size: s, stockQuantity: qty });
      }
    }
    onChange(next);
  };

  const applyToRow = (color: string | null, qty: number) => {
    const q = Math.max(0, Math.floor(qty || 0));
    const sizeAxis = sizes.length > 0 ? sizes.map((s) => s.value) : [null];
    const others = value.filter((c) => c.color !== color);
    const rowCells: VariantCell[] = sizeAxis.map((s) => ({ color, size: s, stockQuantity: q }));
    onChange([...others, ...rowCells]);
  };

  const applyToColumn = (size: string | null, qty: number) => {
    const q = Math.max(0, Math.floor(qty || 0));
    const colorAxis = colors.length > 0 ? colors.map((c) => c.value) : [null];
    const others = value.filter((c) => c.size !== size);
    const colCells: VariantCell[] = colorAxis.map((c) => ({ color: c, size, stockQuantity: q }));
    onChange([...others, ...colCells]);
  };

  if (colors.length === 0 && sizes.length === 0) return null;

  const totalUnits = value.reduce((acc, c) => acc + (c.stockQuantity || 0), 0);
  const filledCells = value.filter((c) => c.stockQuantity > 0).length;
  const totalCells  = Math.max(colors.length, 1) * Math.max(sizes.length, 1);

  // Single-axis fallback: render a compact list instead of a grid.
  const isSingleAxis = colors.length === 0 || sizes.length === 0;

  return (
    <div className="rounded-xl border border-outline/60 p-5 space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-sm font-medium text-content">Stock by variant</p>
          <p className="text-xs text-content-muted mt-0.5">
            Enter how many units you have of each combination. Empty cells are treated as 0.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <input
            type="number"
            min={0}
            placeholder="Qty"
            value={bulkQty}
            onChange={(e) => setBulkQty(e.target.value)}
            className="w-20 px-2 py-1.5 text-sm rounded-md border border-outline-strong bg-surface-sunken focus:ring-2 focus:ring-brand-200 focus:border-transparent"
          />
          <button
            type="button"
            onClick={applyBulkToAll}
            className="px-3 py-1.5 text-xs font-medium rounded-md bg-surface text-content hover:bg-surface-sunken border border-outline"
          >
            Apply to all
          </button>
        </div>
      </div>

      {isSingleAxis ? (
        <SingleAxisGrid
          axisOptions={colors.length > 0 ? colors : sizes}
          axisIsColor={colors.length > 0}
          getCell={getCell}
          setCell={setCell}
        />
      ) : (
        <MatrixGrid
          colors={colors}
          sizes={sizes}
          getCell={getCell}
          setCell={setCell}
          onApplyRow={applyToRow}
          onApplyCol={applyToColumn}
        />
      )}

      <div className="flex items-center justify-between border-t border-outline/60 pt-3 text-xs text-content-muted">
        <span>{filledCells} of {totalCells} cell(s) stocked</span>
        <span className="font-medium text-content">Total units: {totalUnits.toLocaleString()}</span>
      </div>
    </div>
  );
};

// ── Grid (color rows × size cols) ──────────────────────────────────────────
const MatrixGrid: React.FC<{
  colors: VariantOption[];
  sizes:  VariantOption[];
  getCell: (c: string | null, s: string | null) => VariantCell;
  setCell: (cell: VariantCell) => void;
  onApplyRow: (color: string | null, qty: number) => void;
  onApplyCol: (size:  string | null, qty: number) => void;
}> = ({ colors, sizes, getCell, setCell, onApplyRow, onApplyCol }) => (
  <div className="overflow-x-auto">
    <table className="min-w-full text-sm">
      <thead>
        <tr>
          <th className="text-left text-xs uppercase tracking-wide text-content-muted px-2 py-1.5 w-32">
            Color \ Size
          </th>
          {sizes.map((s) => (
            <th key={s.value} className="text-center text-xs font-medium text-content px-2 py-1.5">
              <div>{s.value}</div>
              <ColApply onApply={(q) => onApplyCol(s.value, q)} />
            </th>
          ))}
          <th className="text-center text-xs text-content-muted px-2 py-1.5 w-20">Row total</th>
        </tr>
      </thead>
      <tbody className="divide-y divide-outline/60">
        {colors.map((c) => {
          const rowTotal = sizes.reduce(
            (acc, s) => acc + (getCell(c.value, s.value).stockQuantity || 0), 0,
          );
          return (
            <tr key={c.value}>
              <td className="px-2 py-2">
                <div className="flex items-center gap-2">
                  {c.hex && (
                    <span
                      className="inline-block w-3 h-3 rounded-full border border-black/10 shrink-0"
                      style={{ backgroundColor: c.hex }}
                    />
                  )}
                  <span className="font-medium text-content">{c.value}</span>
                </div>
                <RowApply onApply={(q) => onApplyRow(c.value, q)} />
              </td>
              {sizes.map((s) => {
                const cell = getCell(c.value, s.value);
                return (
                  <td key={s.value} className="px-1.5 py-2 text-center">
                    <QtyInput
                      value={cell.stockQuantity}
                      onChange={(qty) => setCell({ ...cell, color: c.value, size: s.value, stockQuantity: qty })}
                    />
                  </td>
                );
              })}
              <td className="px-2 py-2 text-center text-xs text-content-muted">{rowTotal}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  </div>
);

// ── Single axis (only sizes or only colors) ───────────────────────────────
const SingleAxisGrid: React.FC<{
  axisOptions: VariantOption[];
  axisIsColor: boolean;
  getCell: (c: string | null, s: string | null) => VariantCell;
  setCell: (cell: VariantCell) => void;
}> = ({ axisOptions, axisIsColor, getCell, setCell }) => (
  <div className="space-y-2">
    {axisOptions.map((o) => {
      const color = axisIsColor ? o.value : null;
      const size  = axisIsColor ? null    : o.value;
      const cell  = getCell(color, size);
      return (
        <div key={o.value} className="flex items-center justify-between gap-3 rounded-lg bg-surface-sunken px-3 py-2">
          <div className="flex items-center gap-2 text-sm">
            {axisIsColor && o.hex && (
              <span
                className="inline-block w-3 h-3 rounded-full border border-black/10"
                style={{ backgroundColor: o.hex }}
              />
            )}
            <span className="font-medium text-content">{o.value}</span>
          </div>
          <QtyInput
            value={cell.stockQuantity}
            onChange={(qty) => setCell({ ...cell, color, size, stockQuantity: qty })}
          />
        </div>
      );
    })}
  </div>
);

// ── Tiny editor primitives ────────────────────────────────────────────────
const QtyInput: React.FC<{ value: number; onChange: (n: number) => void }> = ({ value, onChange }) => (
  <input
    type="number"
    min={0}
    value={value === 0 ? '' : value}
    onChange={(e) => onChange(Math.max(0, Math.floor(Number(e.target.value) || 0)))}
    placeholder="0"
    className="w-20 px-2 py-1 text-sm text-center rounded-md border border-outline bg-surface-elevated focus:ring-2 focus:ring-brand-200 focus:border-transparent"
  />
);

const RowApply: React.FC<{ onApply: (qty: number) => void }> = ({ onApply }) => {
  const [v, setV] = useState('');
  return (
    <div className="mt-1.5 flex items-center gap-1">
      <input
        type="number"
        min={0}
        placeholder="fill"
        value={v}
        onChange={(e) => setV(e.target.value)}
        className="w-14 px-1.5 py-0.5 text-xs rounded border border-outline bg-surface-sunken"
      />
      <button
        type="button"
        onClick={() => { onApply(Number(v) || 0); setV(''); }}
        className="text-xs text-brand-600 hover:text-brand-700"
        title="Apply to entire row"
      >
        →
      </button>
    </div>
  );
};

const ColApply: React.FC<{ onApply: (qty: number) => void }> = ({ onApply }) => {
  const [v, setV] = useState('');
  return (
    <div className="mt-1 flex items-center gap-1 justify-center">
      <input
        type="number"
        min={0}
        placeholder="fill"
        value={v}
        onChange={(e) => setV(e.target.value)}
        className="w-14 px-1.5 py-0.5 text-xs rounded border border-outline bg-surface-sunken"
      />
      <button
        type="button"
        onClick={() => { onApply(Number(v) || 0); setV(''); }}
        className="text-xs text-brand-600 hover:text-brand-700"
        title="Apply to entire column"
      >
        ↓
      </button>
    </div>
  );
};
