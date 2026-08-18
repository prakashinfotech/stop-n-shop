import React from 'react';

/**
 * Maps to GenderTypes table:
 *   1 = Men, 2 = Women, 3 = Kids, 4 = Unisex.
 * (Beauty/All are catalog-level meta, not user-facing here.)
 */
export type GenderTypeId = 1 | 2 | 3 | 4;

const OPTIONS: { id: GenderTypeId; label: string }[] = [
  { id: 1, label: 'Men' },
  { id: 2, label: 'Women' },
  { id: 3, label: 'Kids' },
  { id: 4, label: 'Unisex' },
];

interface Props {
  value: GenderTypeId | undefined;
  onChange: (id: GenderTypeId) => void;
  required?: boolean;
  error?: string;
}

export const GenderPicker: React.FC<Props> = ({ value, onChange, required, error }) => (
  <div>
    <label className="block text-sm font-medium text-content mb-1.5">
      Gender{required && <span className="text-red-500 ml-0.5">*</span>}
    </label>
    <div role="radiogroup" className="flex flex-wrap gap-2">
      {OPTIONS.map((opt) => {
        const selected = value === opt.id;
        return (
          <button
            type="button"
            key={opt.id}
            role="radio"
            aria-checked={selected}
            onClick={() => onChange(opt.id)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-300 ${
              selected ? 'bg-brand-500 text-white' : 'bg-surface-sunken text-content hover:bg-surface'
            }`}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
    {error && <p className="text-xs text-red-600 mt-1">{error}</p>}
  </div>
);

/** Converts GenderTypeId back to the legacy string used by the API. */
export const genderIdToString = (id?: GenderTypeId): string | undefined => {
  if (!id) return undefined;
  return ({ 1: 'Men', 2: 'Women', 3: 'Kids', 4: 'Unisex' } as const)[id];
};

/** Best-effort parse of a legacy gender string into a GenderTypeId. */
export const stringToGenderId = (raw?: string | null): GenderTypeId | undefined => {
  if (!raw) return undefined;
  const k = raw.trim().toLowerCase();
  if (k === 'men'    || k === 'male'   || k === 'm') return 1;
  if (k === 'women'  || k === 'female' || k === 'w' || k === 'f') return 2;
  if (k === 'kids'   || k === 'kid'    || k === 'k') return 3;
  if (k === 'unisex' || k === 'u')                   return 4;
  return undefined;
};
