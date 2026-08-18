import React from 'react';
import { clsx } from 'clsx';

interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: React.ReactNode;
  /** Tonal background of the icon halo. */
  tone?: 'brand' | 'neutral' | 'gold' | 'info' | 'success';
  className?: string;
}

const TONES: Record<NonNullable<EmptyStateProps['tone']>, string> = {
  brand:   'bg-brand-50 text-brand-500',
  neutral: 'bg-surface-sunken text-content-muted',
  gold:    'bg-amber-50 text-amber-600',
  info:    'bg-blue-50 text-blue-600',
  success: 'bg-green-50 text-green-600',
};

export const EmptyState: React.FC<EmptyStateProps> = ({
  icon, title, description, action, tone = 'brand', className,
}) => (
  <div className={clsx(
    'flex flex-col items-center text-center bg-surface-elevated rounded-2xl px-8 py-14',
    'shadow-soft border border-outline/60',
    className,
  )}>
    {icon && (
      <div className={clsx(
        'w-16 h-16 rounded-2xl flex items-center justify-center mb-5',
        TONES[tone],
      )}>
        {icon}
      </div>
    )}
    <h3 className="font-display text-xl font-semibold text-content mb-2">{title}</h3>
    {description && (
      <p className="text-sm text-content-muted max-w-md">{description}</p>
    )}
    {action && <div className="mt-6">{action}</div>}
  </div>
);
