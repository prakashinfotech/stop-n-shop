import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { ChevronDown, LogOut, Sun, Moon, Monitor } from 'lucide-react';
import { clsx } from 'clsx';
import { useTheme, type ThemeMode } from '../../context/ThemeContext';

export interface UserMenuItem {
  to: string;
  label: string;
  icon: React.ReactNode;
  external?: boolean;
}

interface UserMenuProps {
  name: string;
  email?: string;
  initial?: string;
  items?: UserMenuItem[];
  onLogout: () => void;
}

const THEME_OPTIONS: Array<{ value: ThemeMode; label: string; Icon: React.ComponentType<{ className?: string }> }> = [
  { value: 'light',  label: 'Light',  Icon: Sun },
  { value: 'dark',   label: 'Dark',   Icon: Moon },
  { value: 'system', label: 'System', Icon: Monitor },
];

export const UserMenu: React.FC<UserMenuProps> = ({
  name,
  email,
  initial,
  items = [],
  onLogout,
}) => {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const { mode, setMode } = useTheme();

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const avatarChar = (initial ?? name ?? email ?? 'U').charAt(0).toUpperCase();

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-surface transition-colors"
        aria-haspopup="menu"
        aria-expanded={open}
      >
        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-brand-500 to-brand-600 flex items-center justify-center text-white text-xs font-bold shadow-sm">
          {avatarChar}
        </div>
        <span className="hidden md:block text-sm font-medium text-content max-w-[120px] truncate">
          {name}
        </span>
        <ChevronDown
          className={`h-3.5 w-3.5 text-content-subtle transition-transform ${open ? 'rotate-180' : ''}`}
        />
      </button>

      {open && (
        <div
          role="menu"
          className="absolute right-0 top-full mt-2 w-64 bg-surface-elevated border border-outline/60 rounded-2xl shadow-soft-lg py-2 z-50 overflow-hidden"
        >
          <div className="px-4 py-3 border-b border-outline/60">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-gradient-to-br from-brand-500 to-brand-600 flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                {avatarChar}
              </div>
              <div className="overflow-hidden">
                <p className="text-sm font-semibold text-content truncate">{name}</p>
                {email && <p className="text-xs text-content-muted truncate">{email}</p>}
              </div>
            </div>
          </div>

          {items.length > 0 && (
            <div className="py-1">
              {items.map((item) =>
                item.external ? (
                  <a
                    key={item.to}
                    href={item.to}
                    target="_blank"
                    rel="noreferrer"
                    onClick={() => setOpen(false)}
                    className="flex items-center gap-3 px-4 py-2.5 text-sm text-content hover:bg-surface transition-colors"
                  >
                    <span className="text-content-subtle">{item.icon}</span>
                    <span className="font-medium">{item.label}</span>
                  </a>
                ) : (
                  <Link
                    key={item.to}
                    to={item.to}
                    onClick={() => setOpen(false)}
                    className="flex items-center gap-3 px-4 py-2.5 text-sm text-content hover:bg-surface transition-colors"
                  >
                    <span className="text-content-subtle">{item.icon}</span>
                    <span className="font-medium">{item.label}</span>
                  </Link>
                )
              )}
            </div>
          )}

          {/* Theme picker */}
          <div className="px-4 py-3 border-t border-outline/60">
            <p className="text-[11px] uppercase tracking-wider font-semibold text-content-subtle mb-2">
              Theme
            </p>
            <div className="flex bg-surface-sunken rounded-xl p-1 gap-1">
              {THEME_OPTIONS.map(({ value, label, Icon }) => {
                const active = mode === value;
                return (
                  <button
                    key={value}
                    type="button"
                    role="menuitemradio"
                    aria-checked={active}
                    onClick={() => setMode(value)}
                    title={label}
                    className={clsx(
                      'flex-1 flex items-center justify-center gap-1.5 py-1.5 rounded-lg text-xs font-medium transition-colors',
                      active
                        ? 'bg-surface-elevated text-content shadow-soft'
                        : 'text-content-muted hover:text-content',
                    )}
                  >
                    <Icon className="w-3.5 h-3.5" />
                    <span>{label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          <div className="border-t border-outline/60 pt-1">
            <button
              type="button"
              onClick={() => {
                setOpen(false);
                onLogout();
              }}
              className="flex items-center gap-3 w-full px-4 py-2.5 text-sm text-red-500 hover:bg-red-50 transition-colors"
            >
              <LogOut className="h-4 w-4" />
              <span className="font-medium">Sign Out</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
