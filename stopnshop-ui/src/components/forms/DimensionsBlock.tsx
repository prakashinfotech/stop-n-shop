import React from 'react';
import { PremiumFormInput } from './PremiumFormInput';

export interface DimensionsValue {
  lengthCm?: number | null;
  widthCm?:  number | null;
  heightCm?: number | null;
  weightGm?: number | null;
}

export const emptyDimensions = (): DimensionsValue => ({});

interface Props {
  value: DimensionsValue;
  onChange: (next: DimensionsValue) => void;
}

export const DimensionsBlock: React.FC<Props> = ({ value, onChange }) => {
  const set = (k: keyof DimensionsValue) => (e: React.ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value;
    onChange({ ...value, [k]: raw === '' ? null : Number(raw) });
  };

  return (
    <div className="rounded-xl border border-outline/60 p-6 space-y-4">
      <div>
        <label className="block text-sm font-medium text-content">Dimensions &amp; Weight</label>
        <p className="text-xs text-content-muted mt-1">
          Required for accurate shipping rates and warehousing.
        </p>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <PremiumFormInput
          label="Length (cm)"
          name="lengthCm"
          type="number"
          step="0.1"
          min={0}
          value={value.lengthCm ?? ''}
          onChange={set('lengthCm')}
        />
        <PremiumFormInput
          label="Width (cm)"
          name="widthCm"
          type="number"
          step="0.1"
          min={0}
          value={value.widthCm ?? ''}
          onChange={set('widthCm')}
        />
        <PremiumFormInput
          label="Height (cm)"
          name="heightCm"
          type="number"
          step="0.1"
          min={0}
          value={value.heightCm ?? ''}
          onChange={set('heightCm')}
        />
        <PremiumFormInput
          label="Weight (g)"
          name="weightGm"
          type="number"
          step="1"
          min={0}
          value={value.weightGm ?? ''}
          onChange={set('weightGm')}
        />
      </div>
    </div>
  );
};
