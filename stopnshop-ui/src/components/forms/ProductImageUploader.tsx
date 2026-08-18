import React, { useState } from 'react';
import { ImagePlus, X, Loader2, AlertCircle } from 'lucide-react';
import { sellerApi } from '../../api/sellerApi';
import type { ImageSlot } from '../../api/catalogueFormSchemaApi';

const SLOT_LABELS: Record<ImageSlot, string> = {
  front:  'Front view',
  back:   'Back view',
  left:   'Left side',
  right:  'Right side',
  top:    'Top view',
  bottom: 'Bottom view',
  detail: 'Detail shots',
  single: 'Main image',
};

export interface ProductImageValue {
  /** One URL per single-image slot (front/back/left/right/top/bottom/single). */
  slots: Partial<Record<Exclude<ImageSlot, 'detail'>, string>>;
  /** Multiple URLs allowed for the overflow detail slot. */
  detail: string[];
}

export const emptyImageValue = (): ProductImageValue => ({ slots: {}, detail: [] });

interface Props {
  slots: ImageSlot[];                 // from form-schema; "detail" is optional overflow
  value: ProductImageValue;
  onChange: (next: ProductImageValue) => void;
  /** Slots that must be filled before the wizard step is considered valid. */
  requiredSlots?: Exclude<ImageSlot, 'detail' | 'single'>[];
}

/**
 * Per-slot product image uploader. Renders one labeled dropzone per slot from
 * `slots`. `detail` (if present) accepts multiple images.
 */
export const ProductImageUploader: React.FC<Props> = ({ slots, value, onChange, requiredSlots }) => {
  const [busySlot, setBusySlot] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const singleSlots = slots.filter((s): s is Exclude<ImageSlot, 'detail'> => s !== 'detail');
  const hasDetail = slots.includes('detail');

  const uploadOne = async (file: File): Promise<string | null> => {
    try {
      const res = await sellerApi.products.uploadImages([file]);
      const data = (res as any)?.data?.data;
      const url = Array.isArray(data) ? data[0]?.url : data?.url;
      return url ?? null;
    } catch (e: any) {
      setError(e?.response?.data?.message ?? 'Upload failed.');
      return null;
    }
  };

  const handleSlotChange = async (slot: Exclude<ImageSlot, 'detail'>, file: File) => {
    setError(null);
    setBusySlot(slot);
    const url = await uploadOne(file);
    setBusySlot(null);
    if (url) onChange({ ...value, slots: { ...value.slots, [slot]: url } });
  };

  const clearSlot = (slot: Exclude<ImageSlot, 'detail'>) => {
    const next = { ...value.slots };
    delete next[slot];
    onChange({ ...value, slots: next });
  };

  const handleDetailAdd = async (files: FileList) => {
    setError(null);
    setBusySlot('detail');
    const urls: string[] = [];
    for (const file of Array.from(files)) {
      const url = await uploadOne(file);
      if (url) urls.push(url);
    }
    setBusySlot(null);
    if (urls.length > 0) onChange({ ...value, detail: [...value.detail, ...urls] });
  };

  const removeDetail = (url: string) =>
    onChange({ ...value, detail: value.detail.filter((u) => u !== url) });

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {singleSlots.map((slot) => {
          const url = value.slots[slot];
          const required = requiredSlots?.includes(slot as Exclude<ImageSlot, 'detail' | 'single'>);
          const missing = required && !url;
          const busy = busySlot === slot;
          return (
            <div key={slot} className="space-y-1.5">
              <div className="flex items-center justify-between">
                <p className="text-xs font-medium text-content">
                  {SLOT_LABELS[slot]}
                  {required && <span className="text-red-500 ml-0.5">*</span>}
                </p>
                {url && (
                  <button type="button" onClick={() => clearSlot(slot)}
                          className="text-content-subtle hover:text-red-600">
                    <X size={14} />
                  </button>
                )}
              </div>
              <label className={`relative block aspect-square rounded-xl border-2 border-dashed overflow-hidden cursor-pointer transition-colors ${
                missing ? 'border-red-300 bg-red-50/30' : 'border-outline-strong hover:border-brand-400 hover:bg-red-50/20'
              } ${busy ? 'opacity-60' : ''}`}>
                {url ? (
                  <img src={url} alt={SLOT_LABELS[slot]} className="w-full h-full object-cover" />
                ) : (
                  <div className="absolute inset-0 flex flex-col items-center justify-center gap-1 text-content-subtle">
                    {busy ? <Loader2 className="h-5 w-5 animate-spin" /> : <ImagePlus className="h-5 w-5" />}
                    <span className="text-xs font-medium">
                      {busy ? 'Uploading…' : 'Drop or click'}
                    </span>
                  </div>
                )}
                <input
                  type="file"
                  accept="image/png,image/jpeg,image/jpg,image/webp"
                  className="absolute inset-0 opacity-0 cursor-pointer"
                  disabled={busy}
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (file) handleSlotChange(slot, file);
                    e.target.value = '';
                  }}
                />
              </label>
            </div>
          );
        })}
      </div>

      {hasDetail && (
        <div>
          <p className="text-xs font-medium text-content mb-2">{SLOT_LABELS.detail}</p>
          <p className="text-xs text-content-subtle mb-2">
            Optional. Add closeups, fabric texture, tags, packaging, etc.
          </p>
          <div className="flex flex-wrap gap-3">
            {value.detail.map((url) => (
              <div key={url}
                   className="relative w-20 h-20 rounded-lg overflow-hidden border border-outline bg-surface group">
                <img src={url} alt="Detail" className="w-full h-full object-cover" />
                <button
                  type="button"
                  onClick={() => removeDetail(url)}
                  className="absolute top-1 right-1 w-5 h-5 rounded-full bg-surface-elevated/90 text-content-muted hover:bg-brand-500 hover:text-white flex items-center justify-center shadow opacity-0 group-hover:opacity-100 transition"
                >
                  <X size={12} />
                </button>
              </div>
            ))}
            <label className={`w-20 h-20 rounded-lg border border-dashed border-outline-strong hover:border-brand-400 hover:bg-red-50/20 text-content-muted hover:text-brand-500 flex flex-col items-center justify-center gap-0.5 cursor-pointer transition ${
              busySlot === 'detail' ? 'opacity-60' : ''
            }`}>
              {busySlot === 'detail'
                ? <Loader2 className="h-4 w-4 animate-spin" />
                : <ImagePlus size={18} />}
              <span className="text-[10px] font-medium">Add</span>
              <input
                type="file"
                multiple
                accept="image/png,image/jpeg,image/jpg,image/webp"
                className="hidden"
                disabled={busySlot === 'detail'}
                onChange={(e) => {
                  if (e.target.files && e.target.files.length > 0) handleDetailAdd(e.target.files);
                  e.target.value = '';
                }}
              />
            </label>
          </div>
        </div>
      )}

      {error && (
        <div className="flex items-center gap-2 text-sm text-red-600">
          <AlertCircle size={14} />
          {error}
        </div>
      )}
    </div>
  );
};

/** Flattens the per-slot state into the API's slot-aware Images payload. */
export const flattenImagePayload = (value: ProductImageValue): { url: string; slot: string }[] => {
  const out: { url: string; slot: string }[] = [];
  Object.entries(value.slots).forEach(([slot, url]) => { if (url) out.push({ url, slot }); });
  value.detail.forEach((url) => out.push({ url, slot: 'detail' }));
  return out;
};
