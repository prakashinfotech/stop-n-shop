import React from 'react';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, act, renderHook } from '@testing-library/react';
import { ThemeProvider, useTheme, type ThemeMode } from '@/context/ThemeContext';

type MqlListener = (e: { matches: boolean }) => void;

const createMatchMedia = (initialDark: boolean) => {
  const listeners = new Set<MqlListener>();
  const mql = {
    matches: initialDark,
    addEventListener: (_: string, l: MqlListener) => listeners.add(l),
    removeEventListener: (_: string, l: MqlListener) => listeners.delete(l),
    addListener: (l: MqlListener) => listeners.add(l), // legacy
    removeListener: (l: MqlListener) => listeners.delete(l),
    dispatchEvent: () => true,
    media: '(prefers-color-scheme: dark)',
    onchange: null,
  };
  const fire = (next: boolean) => {
    mql.matches = next;
    listeners.forEach((l) => l({ matches: next }));
  };
  const factory = vi.fn().mockReturnValue(mql);
  return { factory, fire, mql };
};

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <ThemeProvider>{children}</ThemeProvider>
);

describe('ThemeProvider', () => {
  beforeEach(() => {
    localStorage.clear();
    document.documentElement.classList.remove('dark');
    delete document.documentElement.dataset.theme;
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('defaults to system mode and resolves to light when OS prefers light', () => {
    const { factory } = createMatchMedia(false);
    vi.stubGlobal('matchMedia', factory);

    const { result } = renderHook(() => useTheme(), { wrapper });

    expect(result.current.mode).toBe('system');
    expect(result.current.theme).toBe('light');
    expect(document.documentElement.classList.contains('dark')).toBe(false);
  });

  it('resolves system mode to dark when OS prefers dark', () => {
    const { factory } = createMatchMedia(true);
    vi.stubGlobal('matchMedia', factory);

    const { result } = renderHook(() => useTheme(), { wrapper });

    expect(result.current.mode).toBe('system');
    expect(result.current.theme).toBe('dark');
    expect(document.documentElement.classList.contains('dark')).toBe(true);
  });

  it('persists explicit mode to localStorage and applies it', () => {
    const { factory } = createMatchMedia(false);
    vi.stubGlobal('matchMedia', factory);

    const { result } = renderHook(() => useTheme(), { wrapper });

    act(() => result.current.setMode('dark'));

    expect(localStorage.getItem('theme')).toBe('dark');
    expect(result.current.mode).toBe('dark');
    expect(result.current.theme).toBe('dark');
    expect(document.documentElement.classList.contains('dark')).toBe(true);
  });

  it('reads stored preference on init', () => {
    localStorage.setItem('theme', 'dark');
    const { factory } = createMatchMedia(false); // OS prefers light — stored should win
    vi.stubGlobal('matchMedia', factory);

    const { result } = renderHook(() => useTheme(), { wrapper });

    expect(result.current.mode).toBe('dark');
    expect(result.current.theme).toBe('dark');
  });

  it('toggles cycle: light → dark → system → light', () => {
    localStorage.setItem('theme', 'light');
    const { factory } = createMatchMedia(false);
    vi.stubGlobal('matchMedia', factory);

    const { result } = renderHook(() => useTheme(), { wrapper });
    expect(result.current.mode).toBe('light');

    act(() => result.current.toggleTheme());
    expect(result.current.mode).toBe('dark');

    act(() => result.current.toggleTheme());
    expect(result.current.mode).toBe('system');

    act(() => result.current.toggleTheme());
    expect(result.current.mode).toBe('light');
  });

  it('reacts to OS preference changes while in system mode', () => {
    const { factory, fire } = createMatchMedia(false);
    vi.stubGlobal('matchMedia', factory);

    const { result } = renderHook(() => useTheme(), { wrapper });
    expect(result.current.theme).toBe('light');

    act(() => fire(true));
    expect(result.current.theme).toBe('dark');
    expect(document.documentElement.classList.contains('dark')).toBe(true);

    act(() => fire(false));
    expect(result.current.theme).toBe('light');
  });

  it('ignores OS changes when an explicit mode is set', () => {
    localStorage.setItem('theme', 'light');
    const { factory, fire } = createMatchMedia(false);
    vi.stubGlobal('matchMedia', factory);

    const { result } = renderHook(() => useTheme(), { wrapper });

    act(() => fire(true)); // OS flips to dark — but mode is 'light'
    expect(result.current.theme).toBe('light');
    expect(document.documentElement.classList.contains('dark')).toBe(false);
  });

  it('sets data-theme attribute for non-Tailwind CSS hooks', () => {
    const { factory } = createMatchMedia(true);
    vi.stubGlobal('matchMedia', factory);

    renderHook(() => useTheme(), { wrapper });
    expect(document.documentElement.dataset.theme).toBe('dark');
  });

  it('throws when used outside provider', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => renderHook(() => useTheme())).toThrow(/within ThemeProvider/);
    spy.mockRestore();
  });

  it('accepts each ThemeMode literal via setMode', () => {
    const { factory } = createMatchMedia(false);
    vi.stubGlobal('matchMedia', factory);
    const { result } = renderHook(() => useTheme(), { wrapper });

    (['light', 'dark', 'system'] satisfies ThemeMode[]).forEach((m) => {
      act(() => result.current.setMode(m));
      expect(result.current.mode).toBe(m);
    });
  });

  it('renders children', () => {
    const { factory } = createMatchMedia(false);
    vi.stubGlobal('matchMedia', factory);
    const { getByText } = render(
      <ThemeProvider>
        <span>hello</span>
      </ThemeProvider>,
    );
    expect(getByText('hello')).toBeInTheDocument();
  });
});
