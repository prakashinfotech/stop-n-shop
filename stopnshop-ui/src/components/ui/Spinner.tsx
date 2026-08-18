import React from 'react';
import { clsx } from 'clsx';

interface SpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const Spinner: React.FC<SpinnerProps> = ({ size = 'md', className }) => {
  const sizeClass = { sm: 'h-4 w-4', md: 'h-8 w-8', lg: 'h-12 w-12' }[size];

  return (
    <div className={clsx('flex items-center justify-center', className)}>
      <div
        className={clsx(
          sizeClass,
          'animate-spin rounded-full border-2 border-outline border-t-brand-500'
        )}
      />
    </div>
  );
};
