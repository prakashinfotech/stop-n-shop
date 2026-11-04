import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';

export type ThemeMode = 'light' | 'dark';
export type ResolvedTheme = 'light' | 'dark';

interface ThemeContextType {
  /** User-selected preference. */
  mode: ThemeMode;
  /** Effective theme applied to the DOM (same as mode, except forced light on auth routes). */
  theme: ResolvedTheme;
  setMode: (mode: ThemeMode) => void;
  /** Cycle: light → dark → light. */
  toggleTheme: () => void;
  /** @deprecated use `setMode` — kept for source-compatibility. */
  setTheme: (theme: ResolvedTheme) => void;
}

const STORAGE_KEY = 'theme';
const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

const readStoredMode = (): ThemeMode => {
  // Default is LIGHT for new visitors — matches the FOUC guard in index.html.
  // There is no 'system' option: it tracked the OS preference, which for most
  // visitors resolves to light anyway, so it was a second control that did
  // the same thing as the first one. Any stored legacy 'system' value (from
  // before this option was removed) falls back to light, same as unset.
  if (typeof window === 'undefined') return 'light';
  const stored = window.localStorage.getItem(STORAGE_KEY);
  return stored === 'light' || stored === 'dark' ? stored : 'light';
};

const applyThemeClass = (resolved: ResolvedTheme) => {
  const root = document.documentElement;
  root.classList.toggle('dark', resolved === 'dark');
  root.dataset.theme = resolved;
};

const AUTH_PATH_PREFIXES = [
  '/login', '/register', '/signup', '/forgot', '/reset', '/otp',
  '/user/login', '/seller/login', '/admin/login',
  '/seller/register', '/seller/signup', '/seller/onboarding',
];

const isAuthRoute = (pathname: string): boolean =>
  AUTH_PATH_PREFIXES.some((p) => pathname.startsWith(p));

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Initialize from storage synchronously so first paint matches the inline FOUC script.
  const [mode, setModeState] = useState<ThemeMode>(() => readStoredMode());

  // Track pathname so auth routes can force light without remounting the provider.
  // We can't use useLocation here (ThemeProvider sits above the Router), so we
  // listen for the browser-level locationchange via popstate + pushState patch.
  const [pathname, setPathname] = useState<string>(() =>
    typeof window === 'undefined' ? '/' : window.location.pathname,
  );

  useEffect(() => {
    const update = () => setPathname(window.location.pathname);
    window.addEventListener('popstate', update);
    // React Router uses history.pushState; patch it once to emit a synthetic event.
    const origPush = window.history.pushState;
    const origReplace = window.history.replaceState;
    window.history.pushState = function (...args) {
      const ret = origPush.apply(this, args as Parameters<typeof origPush>);
      update();
      return ret;
    };
    window.history.replaceState = function (...args) {
      const ret = origReplace.apply(this, args as Parameters<typeof origReplace>);
      update();
      return ret;
    };
    return () => {
      window.removeEventListener('popstate', update);
      window.history.pushState = origPush;
      window.history.replaceState = origReplace;
    };
  }, []);

  // Force light on auth/onboarding routes regardless of the user's stored preference.
  const resolved: ResolvedTheme = isAuthRoute(pathname) ? 'light' : mode;

  // Apply effective theme to <html> whenever the resolution changes.
  useEffect(() => {
    applyThemeClass(resolved);
  }, [resolved]);

  const setMode = useCallback((next: ThemeMode) => {
    setModeState(next);
    window.localStorage.setItem(STORAGE_KEY, next);
  }, []);

  const toggleTheme = useCallback(() => {
    setModeState((curr) => {
      const next: ThemeMode = curr === 'light' ? 'dark' : 'light';
      window.localStorage.setItem(STORAGE_KEY, next);
      return next;
    });
  }, []);

  const setTheme = useCallback((t: ResolvedTheme) => setMode(t), [setMode]);

  const value = useMemo<ThemeContextType>(
    () => ({ mode, theme: resolved, setMode, toggleTheme, setTheme }),
    [mode, resolved, setMode, toggleTheme, setTheme],
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
};

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
};
