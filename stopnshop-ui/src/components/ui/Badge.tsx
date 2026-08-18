import React from 'react';
import { clsx } from 'clsx';

type BadgeVariant =
  | 'neutral' | 'brand' | 'gold' | 'success' | 'warning' | 'danger' | 'info'
  | 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'returned';

type BadgeSize = 'sm' | 'md';

interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant;
  size?: BadgeSize;
  dot?: boolean;
  children: React.ReactNode;
}

const VARIANTS: Record<BadgeVariant, string> = {
  neutral:    'bg-surface-sunken text-content-muted',
  brand:      'bg-brand-50 text-brand-600',
  gold:       'bg-amber-50 text-amber-700',
  success:    'bg-green-50 text-green-700',
  warning:    'bg-yellow-50 text-yellow-700',
  danger:     'bg-red-50 text-red-700',
  info:       'bg-blue-50 text-blue-700',
  // Order lifecycle — semantic mapping to the underlying palettes
  pending:    'bg-yellow-50 text-yellow-700',
  confirmed:  'bg-blue-50 text-blue-700',
  processing: 'bg-indigo-50 text-indigo-700',
  shipped:    'bg-violet-50 text-violet-700',
  delivered:  'bg-green-50 text-green-700',
  cancelled:  'bg-red-50 text-red-700',
  returned:   'bg-stone-100 text-stone-700',
};

const DOT_COLORS: Record<BadgeVariant, string> = {
  neutral: 'bg-stone-400', brand: 'bg-brand-500', gold: 'bg-amber-500',
  success: 'bg-green-500', warning: 'bg-yellow-500', danger: 'bg-red-500', info: 'bg-blue-500',
  pending: 'bg-yellow-500', confirmed: 'bg-blue-500', processing: 'bg-indigo-500',
  shipped: 'bg-violet-500', delivered: 'bg-green-500', cancelled: 'bg-red-500', returned: 'bg-stone-500',
};

const SIZES: Record<BadgeSize, string> = {
  sm: 'px-2 py-0.5 text-[11px]',
  md: 'px-2.5 py-1 text-xs',
};

export const Badge: React.FC<BadgeProps> = ({
  variant = 'neutral',
  size = 'md',
  dot = false,
  className,
  children,
  ...props
}) => (
  <span
    className={clsx(
      'inline-flex items-center gap-1.5 rounded-full font-medium',
      VARIANTS[variant],
      SIZES[size],
      className,
    )}
    {...props}
  >
    {dot && <span className={clsx('h-1.5 w-1.5 rounded-full', DOT_COLORS[variant])} />}
    {children}
  </span>
);

/** Map an order-status string (case-insensitive) to a Badge variant. */
export const orderStatusVariant = (status?: string | null): BadgeVariant => {
  switch ((status ?? '').toLowerCase()) {
    case 'pending':    return 'pending';
    case 'confirmed':  return 'confirmed';
    case 'processing': return 'processing';
    case 'shipped':    return 'shipped';
    case 'delivered':  return 'delivered';
    case 'cancelled':
    case 'canceled':   return 'cancelled';
    case 'returned':   return 'returned';
    default:           return 'neutral';
  }
};
