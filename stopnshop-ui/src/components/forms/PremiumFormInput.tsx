import React from 'react';
import { AlertCircle } from 'lucide-react';

interface PremiumFormInputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
}

export const PremiumFormInput = React.forwardRef<
  HTMLInputElement,
  PremiumFormInputProps
>(({ label, error, hint, className, ...props }, ref) => (
  <div className="space-y-2">
    {label && (
      <label className="block text-sm font-medium text-content">{label}</label>
    )}

    <input
      ref={ref}
      className={`
        w-full px-4 py-3 rounded-lg
        border text-content placeholder:text-content-muted
        focus:ring-2 focus:ring-offset-0 focus:border-transparent
        transition-colors duration-200
        ${
          error
            ? 'border-red-300 focus:ring-red-200'
            : 'border-outline-strong focus:ring-brand-200'
        }
        ${className}
      `}
      {...props}
    />

    {error && (
      <div className="flex items-center gap-2 text-red-600 text-sm">
        <AlertCircle size={16} />
        <span>{error}</span>
      </div>
    )}

    {hint && !error && (
      <p className="text-xs text-content-muted">{hint}</p>
    )}
  </div>
));

PremiumFormInput.displayName = 'PremiumFormInput';
