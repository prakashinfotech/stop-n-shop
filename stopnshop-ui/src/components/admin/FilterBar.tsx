import React from 'react';
import { Search, X } from 'lucide-react';

export interface FilterSelect {
  kind: 'select';
  key: string;
  label: string;
  value: string;
  options: { label: string; value: string }[];
  onChange: (value: string) => void;
}

export interface FilterDate {
  kind: 'date';
  key: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
}

export type FilterField = FilterSelect | FilterDate;

interface FilterBarProps {
  search?: { value: string; onChange: (v: string) => void; placeholder?: string };
  filters?: FilterField[];
  onReset?: () => void;
}

export const FilterBar: React.FC<FilterBarProps> = ({ search, filters = [], onReset }) => (
  <div className="flex flex-wrap items-end gap-3 rounded-lg border border-outline bg-surface-elevated p-3">
    {search && (
      <div className="flex-1 min-w-[220px]">
        <label className="block text-xs font-medium text-content-muted mb-1">Search</label>
        <div className="relative">
          <Search className="absolute left-2 top-1/2 -translate-y-1/2 w-4 h-4 text-content-subtle" />
          <input
            type="search"
            className="w-full pl-8 pr-3 py-2 text-sm border border-outline-strong rounded focus:outline-none focus:ring-2 focus:ring-[#c41230]/30"
            placeholder={search.placeholder ?? 'Search…'}
            value={search.value}
            onChange={(e) => search.onChange(e.target.value)}
          />
        </div>
      </div>
    )}
    {filters.map((f) => (
      <div key={f.key} className="min-w-[160px]">
        <label className="block text-xs font-medium text-content-muted mb-1">{f.label}</label>
        {f.kind === 'select' ? (
          <select
            className="w-full px-3 py-2 text-sm border border-outline-strong rounded bg-surface-elevated focus:outline-none focus:ring-2 focus:ring-[#c41230]/30"
            value={f.value}
            onChange={(e) => f.onChange(e.target.value)}
          >
            {f.options.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        ) : (
          <input
            type="date"
            className="w-full px-3 py-2 text-sm border border-outline-strong rounded bg-surface-elevated focus:outline-none focus:ring-2 focus:ring-[#c41230]/30"
            value={f.value}
            onChange={(e) => f.onChange(e.target.value)}
          />
        )}
      </div>
    ))}
    {onReset && (
      <button
        type="button"
        onClick={onReset}
        className="inline-flex items-center gap-1 text-sm text-content-muted hover:text-content px-2 py-2"
      >
        <X className="w-4 h-4" />
        Reset
      </button>
    )}
  </div>
);
