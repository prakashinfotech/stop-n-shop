import React from 'react';
import { Loader2 } from 'lucide-react';

type ButtonVariant = 'primary' | 'secondary' | 'ghost';
type ButtonSize = 'sm' | 'md' | 'lg';

interface PremiumButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  isLoading?: boolean;
  children: React.ReactNode;
}

const variantStyles = {
  primary:
    'bg-gradient-brand text-white hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60',
  secondary:
    'border-2 border-brand-500 text-brand-600 hover:bg-brand-50 disabled:opacity-60',
  ghost: 'text-brand-600 hover:bg-surface-sunken disabled:opacity-60',
};

const sizeStyles = {
  sm: 'px-4 py-2 text-sm font-medium rounded-lg',
  md: 'px-6 py-3 text-base font-semibold rounded-lg',
  lg: 'px-8 py-4 text-lg font-semibold rounded-lg',
};

export const PremiumButton = React.forwardRef<
  HTMLButtonElement,
  PremiumButtonProps
>(
  (
    {
      variant = 'primary',
      size = 'md',
      isLoading,
      disabled,
      children,
      className = '',
      ...props
    },
    ref
  ) => (
    <button
      ref={ref}
      disabled={disabled || isLoading}
      className={`
        inline-flex items-center justify-center gap-2
        transition-all duration-200 ease-out
        focus:ring-2 focus:ring-offset-2 focus:ring-brand-500
        ${variantStyles[variant]}
        ${sizeStyles[size]}
        ${className}
      `}
      {...props}
    >
      {isLoading && <Loader2 size={20} className="animate-spin" />}
      <span>{children}</span>
    </button>
  )
);

PremiumButton.displayName = 'PremiumButton';
