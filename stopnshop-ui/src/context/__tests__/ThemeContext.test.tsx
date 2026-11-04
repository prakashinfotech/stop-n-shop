import React from 'react';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, act, renderHook } from '@testing-library/react';
import { ThemeProvider, useTheme, type ThemeMode } from '@/context/ThemeContext';

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

  it('defaults to light for new visitors with nothing stored', () => {
    const { result } = renderHook(() => useTheme(), { wrapper });

    expect(result.current.mode).toBe('light');
    expect(result.current.theme).toBe('light');
    expect(document.documentElement.classList.contains('dark')).toBe(false);
  });

  it('persists explicit mode to localStorage and applies it', () => {
    const { result } = renderHook(() => useTheme(), { wrapper });

    act(() => result.current.setMode('dark'));

    expect(localStorage.getItem('theme')).toBe('dark');
    expect(result.current.mode).toBe('dark');
    expect(result.current.theme).toBe('dark');
    expect(document.documentElement.classList.contains('dark')).toBe(true);
  });

  it('reads stored preference on init', () => {
    localStorage.setItem('theme', 'dark');

    const { result } = renderHook(() => useTheme(), { wrapper });

    expect(result.current.mode).toBe('dark');
    expect(result.current.theme).toBe('dark');
  });

  it('treats a legacy stored "system" value as light (the option no longer exists)', () => {
    localStorage.setItem('theme', 'system');

    const { result } = renderHook(() => useTheme(), { wrapper });

    expect(result.current.mode).toBe('light');
  });

  it('toggles cycle: light → dark → light', () => {
    localStorage.setItem('theme', 'light');

    const { result } = renderHook(() => useTheme(), { wrapper });
    expect(result.current.mode).toBe('light');

    act(() => result.current.toggleTheme());
    expect(result.current.mode).toBe('dark');

    act(() => result.current.toggleTheme());
    expect(result.current.mode).toBe('light');
  });

  it('sets data-theme attribute for non-Tailwind CSS hooks', () => {
    localStorage.setItem('theme', 'dark');

    renderHook(() => useTheme(), { wrapper });
    expect(document.documentElement.dataset.theme).toBe('dark');
  });

  it('throws when used outside provider', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => renderHook(() => useTheme())).toThrow(/within ThemeProvider/);
    spy.mockRestore();
  });

  it('accepts each ThemeMode literal via setMode', () => {
    const { result } = renderHook(() => useTheme(), { wrapper });

    (['light', 'dark'] satisfies ThemeMode[]).forEach((m) => {
      act(() => result.current.setMode(m));
      expect(result.current.mode).toBe(m);
    });
  });

  it('renders children', () => {
    const { getByText } = render(
      <ThemeProvider>
        <span>hello</span>
      </ThemeProvider>,
    );
    expect(getByText('hello')).toBeInTheDocument();
  });
});
