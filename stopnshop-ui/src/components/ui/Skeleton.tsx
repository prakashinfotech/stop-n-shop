import React from 'react';
import { clsx } from 'clsx';

interface SkeletonProps {
  className?: string;
  count?: number;
  circle?: boolean;
  height?: string;
}

/**
 * Token-aware loading placeholder. Pulses against the page surface so it
 * blends into both the warm light theme and the stone dark theme without
 * the previous hard gray-200/gray-700 contrast jump.
 */
export const Skeleton: React.FC<SkeletonProps> = ({
  className = 'h-12 w-full',
  count = 1,
  circle = false,
  height,
}) => {
  const shape = circle ? 'rounded-full' : 'rounded-xl';
  return (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className={clsx(
            shape,
            'animate-pulse bg-surface-sunken',
            className,
            height,
          )}
        />
      ))}
    </>
  );
};

/** Convenience: row of skeleton cells for a table-like layout. */
export const SkeletonRow: React.FC<{ cols?: number; className?: string }> = ({
  cols = 4, className,
}) => (
  <div className={clsx('flex gap-4 py-3', className)}>
    {Array.from({ length: cols }).map((_, i) => (
      <Skeleton key={i} className="h-5 flex-1" />
    ))}
  </div>
);

/** Convenience: card-shaped skeleton (image + 2 text lines). */
export const SkeletonCard: React.FC<{ className?: string }> = ({ className }) => (
  <div className={clsx('bg-surface-elevated rounded-2xl p-4 shadow-soft', className)}>
    <Skeleton className="h-40 w-full mb-4" />
    <Skeleton className="h-4 w-3/4 mb-2" />
    <Skeleton className="h-4 w-1/2" />
  </div>
);
