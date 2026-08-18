import React from 'react';
import { clsx } from 'clsx';

type CardVariant = 'elevated' | 'flat' | 'outlined' | 'hero';
type CardPadding = 'none' | 'sm' | 'md' | 'lg';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: CardVariant;
  padding?: CardPadding;
  as?: keyof JSX.IntrinsicElements;
  children: React.ReactNode;
}

const VARIANTS: Record<CardVariant, string> = {
  elevated: 'bg-surface-elevated shadow-soft-md rounded-2xl',
  flat:     'bg-surface rounded-2xl',
  outlined: 'bg-surface-elevated border border-outline rounded-2xl',
  hero:     'bg-surface-elevated shadow-soft-lg rounded-3xl',
};

const PADDING: Record<CardPadding, string> = {
  none: '',
  sm:   'p-4',
  md:   'p-6',
  lg:   'p-8 md:p-10',
};

export const Card: React.FC<CardProps> = ({
  variant = 'elevated',
  padding = 'md',
  as: Tag = 'div',
  className,
  children,
  ...props
}) => {
  return React.createElement(
    Tag,
    { className: clsx(VARIANTS[variant], PADDING[padding], className), ...props },
    children,
  );
};

export const CardHeader: React.FC<React.HTMLAttributes<HTMLDivElement>> = ({
  className, children, ...props
}) => (
  <div className={clsx('mb-4', className)} {...props}>{children}</div>
);

export const CardTitle: React.FC<React.HTMLAttributes<HTMLHeadingElement>> = ({
  className, children, ...props
}) => (
  <h3 className={clsx('font-display text-xl font-semibold text-content', className)} {...props}>
    {children}
  </h3>
);

export const CardDescription: React.FC<React.HTMLAttributes<HTMLParagraphElement>> = ({
  className, children, ...props
}) => (
  <p className={clsx('text-sm text-content-muted mt-1', className)} {...props}>{children}</p>
);
