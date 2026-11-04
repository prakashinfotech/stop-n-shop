import React from 'react';
import { AlertCircle } from 'lucide-react';

interface FieldErrorProps {
  message?: string;
}

/**
 * Fixed-height slot below a form field. Always rendered at the same height
 * whether or not there's a message, so a field failing validation doesn't
 * grow the form and shift everything below/around it (centered auth cards
 * visibly jump otherwise). Never collapse this to h-0 — toggling height is
 * the bug this component exists to prevent.
 */
export const FieldError: React.FC<FieldErrorProps> = ({ message }) => (
  <p className="mt-1 min-h-4 text-xs text-red-600 flex items-center gap-1" aria-live="polite">
    {message && (
      <>
        <AlertCircle className="h-3 w-3 shrink-0" /> {message}
      </>
    )}
  </p>
);
