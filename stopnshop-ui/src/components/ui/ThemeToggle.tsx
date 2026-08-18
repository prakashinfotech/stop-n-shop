import React, { useEffect, useRef, useState } from 'react';
import { Moon, Sun, Monitor, Check } from 'lucide-react';
import { useTheme, type ThemeMode } from '@/context/ThemeContext';

const OPTIONS: Array<{ value: ThemeMode; label: string; Icon: React.ComponentType<{ className?: string }> }> = [
  { value: 'light', label: 'Light', Icon: Sun },
  { value: 'dark', label: 'Dark', Icon: Moon },
  { value: 'system', label: 'System', Icon: Monitor },
];

export const ThemeToggle: React.FC = () => {
  const { mode, theme, setMode } = useTheme();
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  // Close menu on outside click / Escape.
  useEffect(() => {
    if (!open) return;
    const onClick = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false);
    };
    document.addEventListener('mousedown', onClick);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('mousedown', onClick);
      document.removeEventListener('keydown', onKey);
    };
  }, [open]);

  const CurrentIcon = theme === 'dark' ? Moon : Sun;
  const buttonLabel = `Theme: ${mode}. Open theme menu.`;

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="relative inline-flex items-center justify-center w-10 h-10 rounded-lg transition-colors duration-200 hover:bg-surface-sunken dark:hover:bg-stone-800 focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label={buttonLabel}
      >
        <CurrentIcon className="w-5 h-5 text-content dark:text-content-subtle" />
      </button>

      {open && (
        <div
          role="menu"
          aria-label="Theme options"
          className="absolute right-0 mt-2 w-44 rounded-lg border border-outline dark:border-stone-700 bg-surface-elevated dark:bg-stone-900 shadow-lg z-50 overflow-hidden"
        >
          {OPTIONS.map(({ value, label, Icon }) => {
            const active = mode === value;
            return (
              <button
                key={value}
                type="button"
                role="menuitemradio"
                aria-checked={active}
                onClick={() => {
                  setMode(value);
                  setOpen(false);
                }}
                className="w-full flex items-center justify-between gap-3 px-3 py-2 text-sm text-content dark:text-content-subtle hover:bg-surface-sunken dark:hover:bg-stone-800 focus:outline-none focus-visible:bg-surface-sunken dark:focus-visible:bg-stone-800"
              >
                <span className="flex items-center gap-2">
                  <Icon className="w-4 h-4" />
                  {label}
                </span>
                {active && <Check className="w-4 h-4 text-brand-500" aria-hidden="true" />}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
};
