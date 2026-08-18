import React, { useState, KeyboardEvent } from 'react';
import { X } from 'lucide-react';

interface Props {
  value: string[];
  onChange: (next: string[]) => void;
  placeholder?: string;
  maxTags?: number;
}

/**
 * Multi-chip tag input. Press Enter or comma to add; Backspace on empty
 * field removes the last chip. Duplicates are silently dropped.
 */
export const TagsInput: React.FC<Props> = ({ value, onChange, placeholder, maxTags = 12 }) => {
  const [draft, setDraft] = useState('');

  const commit = (raw: string) => {
    const t = raw.trim().replace(/^,+|,+$/g, '').trim();
    if (!t) return;
    if (value.length >= maxTags) return;
    if (value.some((v) => v.toLowerCase() === t.toLowerCase())) return;
    onChange([...value, t]);
    setDraft('');
  };

  const handleKey = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      commit(draft);
    } else if (e.key === 'Backspace' && draft === '' && value.length > 0) {
      onChange(value.slice(0, -1));
    }
  };

  return (
    <div className="flex flex-wrap items-center gap-1.5 min-h-[44px] w-full px-2 py-1.5 rounded-lg border border-outline-strong bg-surface-elevated focus-within:ring-2 focus-within:ring-brand-200 focus-within:border-transparent">
      {value.map((tag) => (
        <span
          key={tag}
          className="inline-flex items-center gap-1 pl-2 pr-1 py-0.5 rounded-full text-xs font-medium bg-brand-50 text-brand-700 border border-brand-100"
        >
          {tag}
          <button
            type="button"
            onClick={() => onChange(value.filter((v) => v !== tag))}
            className="p-0.5 rounded hover:bg-brand-100 text-brand-700"
            aria-label={`Remove ${tag}`}
          >
            <X size={12} />
          </button>
        </span>
      ))}
      <input
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={handleKey}
        onBlur={() => commit(draft)}
        placeholder={value.length === 0 ? (placeholder ?? 'Add a tag and press Enter') : ''}
        className="flex-1 min-w-[120px] py-1 text-sm bg-transparent focus:outline-none"
      />
    </div>
  );
};
