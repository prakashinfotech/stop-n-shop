import { useEffect, useRef, useState } from 'react';

/**
 * useState that mirrors its value to localStorage under `key`.
 * - Reads the initial value from storage on first mount (falls back to `initial`).
 * - Writes on every change (debounced via a single useEffect).
 * - `clear()` removes the key from storage and resets state to `initial`.
 *
 * Safe with SSR / non-browser envs (guards on `typeof window`).
 */
export function useLocalStorageState<T>(key: string, initial: T): [T, (next: T) => void, () => void] {
  const initialRef = useRef(initial);
  const [value, setValue] = useState<T>(() => {
    if (typeof window === 'undefined') return initial;
    try {
      const raw = window.localStorage.getItem(key);
      if (raw == null) return initial;
      return JSON.parse(raw) as T;
    } catch {
      return initial;
    }
  });

  useEffect(() => {
    if (typeof window === 'undefined') return;
    try {
      window.localStorage.setItem(key, JSON.stringify(value));
    } catch {
      /* quota or serialization error — silently ignore */
    }
  }, [key, value]);

  const clear = () => {
    setValue(initialRef.current);
    if (typeof window !== 'undefined') {
      try { window.localStorage.removeItem(key); } catch { /* ignore */ }
    }
  };

  return [value, setValue, clear];
}
