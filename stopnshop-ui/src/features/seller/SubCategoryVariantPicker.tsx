import React, { useEffect, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Check, X, Loader2 } from 'lucide-react';
import { variantLibraryApi, type SellerVariantOption } from '../../api/variantLibraryApi';

interface Props {
  subCategoryId: number | undefined;
  productId?: number;
  disabledOptionIds: number[];
  onChange: (next: number[]) => void;
}

export const SubCategoryVariantPicker: React.FC<Props> = ({
  subCategoryId, productId, disabledOptionIds, onChange,
}) => {
  const enabled = !!subCategoryId;

  const { data: options = [], isLoading } = useQuery({
    queryKey: ['seller-variant-options', subCategoryId, productId ?? null],
    queryFn: () =>
      productId
        ? variantLibraryApi.getForSellerProduct(productId, subCategoryId!)
        : variantLibraryApi.getForSubCategory(subCategoryId!),
    enabled,
  });

  // Seed disabled set from server (edit flow) once on first load
  const seededKey = `${productId ?? 'new'}:${subCategoryId ?? 0}`;
  const seededRef = React.useRef<string | null>(null);
  useEffect(() => {
    if (!options.length || seededRef.current === seededKey) return;
    seededRef.current = seededKey;
    if (productId) {
      const serverDisabled = options.filter((o) => o.isDisabledForProduct).map((o) => o.optionId);
      onChange(serverDisabled);
    }
    // For new-product flow keep whatever the parent has (default []).
  }, [options, seededKey, productId, onChange]);

  const grouped = useMemo(() => {
    const m = new Map<number, { name: string; inputType: string; opts: SellerVariantOption[] }>();
    options.forEach((o) => {
      const slot = m.get(o.attributeId) ?? { name: o.attributeName, inputType: o.inputType, opts: [] };
      slot.opts.push(o);
      m.set(o.attributeId, slot);
    });
    m.forEach((v) => v.opts.sort((a, b) => a.sortOrder - b.sortOrder || a.optionValue.localeCompare(b.optionValue)));
    return Array.from(m.entries());
  }, [options]);

  if (!enabled) return null;

  if (isLoading) {
    return (
      <div className="md:col-span-2 rounded-xl border border-outline/60 p-6 flex items-center gap-3">
        <Loader2 className="h-4 w-4 animate-spin text-content-muted" />
        <p className="text-sm text-content-muted">Loading variant options…</p>
      </div>
    );
  }

  if (options.length === 0) {
    return (
      <div className="md:col-span-2 rounded-xl border border-outline/60 p-6">
        <p className="text-sm font-medium text-content">Variant options</p>
        <p className="text-xs text-content-muted mt-1">
          No variant library defined for this subcategory yet. Admin can add Size / Color / Material values
          from the admin panel; until then, use the free-form variant editor below.
        </p>
      </div>
    );
  }

  const isDisabled = (id: number) => disabledOptionIds.includes(id);
  const toggle = (id: number) =>
    onChange(isDisabled(id) ? disabledOptionIds.filter((x) => x !== id) : [...disabledOptionIds, id]);
  const setAll = (groupOpts: SellerVariantOption[], enable: boolean) => {
    const ids = groupOpts.map((o) => o.optionId);
    if (enable) onChange(disabledOptionIds.filter((id) => !ids.includes(id)));
    else        onChange(Array.from(new Set([...disabledOptionIds, ...ids])));
  };

  return (
    <div className="md:col-span-2 rounded-xl border border-outline/60 p-6 space-y-6">
      <div>
        <p className="text-sm font-medium text-content">Available variant options</p>
        <p className="text-xs text-content-muted mt-1">
          Admin has pre-defined these values for this subcategory. Untick anything that does not apply to your product —
          buyers will only see the ticked options.
        </p>
      </div>

      {grouped.map(([attrId, group]) => {
        const allEnabled = group.opts.every((o) => !isDisabled(o.optionId));
        const allDisabled = group.opts.every((o) => isDisabled(o.optionId));
        return (
          <div key={attrId}>
            <div className="flex items-center justify-between mb-2">
              <p className="text-xs uppercase tracking-wide text-content-muted">{group.name}</p>
              <div className="flex items-center gap-2 text-xs">
                <button type="button" onClick={() => setAll(group.opts, true)} disabled={allEnabled}
                  className="text-brand-600 hover:text-brand-700 disabled:opacity-40">All</button>
                <span className="text-content-subtle">·</span>
                <button type="button" onClick={() => setAll(group.opts, false)} disabled={allDisabled}
                  className="text-content-muted hover:text-content disabled:opacity-40">None</button>
              </div>
            </div>
            <div className="flex flex-wrap gap-2">
              {group.opts.map((o) => {
                const off = isDisabled(o.optionId);
                return (
                  <button
                    type="button"
                    key={o.optionId}
                    aria-pressed={!off}
                    onClick={() => toggle(o.optionId)}
                    className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                      off
                        ? 'bg-surface-sunken text-content-muted line-through opacity-60'
                        : 'bg-brand-500 text-white'
                    }`}
                  >
                    {group.inputType === 'swatch' && (
                      <span className="inline-block w-3 h-3 rounded-full border border-black/10"
                            style={{ backgroundColor: o.optionMetadata ?? '#ccc' }} />
                    )}
                    {o.optionValue}
                    {off ? <X size={14} /> : <Check size={14} />}
                  </button>
                );
              })}
            </div>
          </div>
        );
      })}
    </div>
  );
};
