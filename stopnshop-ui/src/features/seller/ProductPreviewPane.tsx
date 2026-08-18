import React from 'react';
import { ImageIcon } from 'lucide-react';
import type { ProductImageValue } from '../../components/forms/ProductImageUploader';
import type { VariantCell } from './VariantMatrixEditor';

interface Props {
  name: string;
  brandName?: string;
  categoryPath?: string;
  gender?: string;
  mrp: number;
  sellingPrice: number;
  stockTotal: number;
  images: ProductImageValue;
  variantMatrix: VariantCell[];
  enabledColorsWithHex: Array<{ value: string; hex?: string | null }>;
  enabledSizes: string[];
}

/**
 * Live PDP-style preview rendered alongside the seller wizard. Mirrors the
 * buyer-facing product card so sellers see exactly what shoppers will see as
 * they fill in the form.
 */
export const ProductPreviewPane: React.FC<Props> = ({
  name, brandName, categoryPath, gender, mrp, sellingPrice, stockTotal,
  images, variantMatrix, enabledColorsWithHex, enabledSizes,
}) => {
  const heroImage =
    images.slots.front ??
    images.slots.single ??
    Object.values(images.slots).find(Boolean) ??
    images.detail[0];

  const hasPrice = mrp > 0 || sellingPrice > 0;
  const showDiscount = mrp > 0 && sellingPrice > 0 && sellingPrice < mrp;
  const discountPct = showDiscount ? Math.round(((mrp - sellingPrice) / mrp) * 100) : 0;

  const inStock = variantMatrix.length > 0
    ? variantMatrix.some((c) => c.stockQuantity > 0)
    : stockTotal > 0;

  return (
    <div className="rounded-2xl border border-outline/60 bg-surface-elevated shadow-soft overflow-hidden">
      <div className="px-4 py-2 border-b border-outline/60 bg-surface flex items-center justify-between">
        <p className="text-xs uppercase tracking-wider text-content-subtle">Live preview</p>
        <span className={`text-[11px] font-medium px-2 py-0.5 rounded-full ${
          inStock ? 'bg-green-50 text-green-700' : 'bg-stone-100 text-stone-600'
        }`}>
          {inStock ? 'In stock' : 'Draft'}
        </span>
      </div>

      <div className="aspect-square bg-surface-sunken flex items-center justify-center relative">
        {heroImage ? (
          <img src={heroImage} alt={name || 'Product preview'} className="w-full h-full object-cover" />
        ) : (
          <div className="text-content-subtle flex flex-col items-center gap-1">
            <ImageIcon size={32} />
            <span className="text-xs">No image yet</span>
          </div>
        )}
        {showDiscount && (
          <span className="absolute top-2 left-2 px-2 py-0.5 rounded text-[11px] font-bold bg-brand-500 text-white">
            {discountPct}% OFF
          </span>
        )}
      </div>

      <div className="p-4 space-y-3">
        {brandName && (
          <p className="text-[11px] uppercase tracking-wider text-content-muted">{brandName}</p>
        )}
        <h3 className="text-sm font-semibold text-content leading-snug line-clamp-2 min-h-[2.5rem]">
          {name?.trim() || 'Product name appears here'}
        </h3>

        {(categoryPath || gender) && (
          <p className="text-xs text-content-subtle">
            {[categoryPath, gender].filter(Boolean).join(' · ')}
          </p>
        )}

        <div className="flex items-baseline gap-2">
          {hasPrice ? (
            <>
              <span className="text-lg font-bold text-content tabular-nums">
                ₹{(sellingPrice || mrp).toLocaleString()}
              </span>
              {showDiscount && (
                <span className="text-xs text-content-subtle line-through tabular-nums">
                  ₹{mrp.toLocaleString()}
                </span>
              )}
              {showDiscount && (
                <span className="text-xs font-medium text-green-600">{discountPct}% off</span>
              )}
            </>
          ) : (
            <span className="text-sm text-content-subtle">Add price to preview</span>
          )}
        </div>

        {enabledColorsWithHex.length > 0 && (
          <div>
            <p className="text-[11px] text-content-muted mb-1">Colors</p>
            <div className="flex flex-wrap gap-1.5">
              {enabledColorsWithHex.slice(0, 8).map((c) => (
                <span
                  key={c.value}
                  title={c.value}
                  className="w-5 h-5 rounded-full border border-black/10"
                  style={{ backgroundColor: c.hex ?? '#ccc' }}
                />
              ))}
              {enabledColorsWithHex.length > 8 && (
                <span className="text-[11px] text-content-subtle self-center">
                  +{enabledColorsWithHex.length - 8}
                </span>
              )}
            </div>
          </div>
        )}

        {enabledSizes.length > 0 && (
          <div>
            <p className="text-[11px] text-content-muted mb-1">Sizes</p>
            <div className="flex flex-wrap gap-1">
              {enabledSizes.slice(0, 10).map((s) => (
                <span
                  key={s}
                  className="px-2 py-0.5 text-[11px] rounded border border-outline-strong text-content"
                >
                  {s}
                </span>
              ))}
            </div>
          </div>
        )}

        <button
          type="button"
          disabled
          className="w-full mt-2 py-2 rounded-lg bg-brand-500 text-white text-sm font-medium opacity-60 cursor-not-allowed"
        >
          Add to bag (preview)
        </button>
      </div>
    </div>
  );
};
