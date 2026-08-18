import React from 'react';
import { Link } from 'react-router-dom';

interface SellerHeaderProps {
  /** Role badge text — e.g. "Seller Center", "Admin Console". */
  badge?: string;
  /** Right-aligned slot — typically a UserMenu. */
  rightContent?: React.ReactNode;
  className?: string;
}

/**
 * Unified app header — same wordmark as buyer storefront so seller/admin
 * feel like the same product, just a different role.
 */
export const SellerHeader: React.FC<SellerHeaderProps> = ({
  badge = 'Seller Center',
  rightContent,
  className = '',
}) => (
  <header
    className={`bg-surface-elevated border-b border-outline/60 sticky top-0 z-40 ${className}`}
  >
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
      <div className="flex items-center gap-3">
        <Link
          to="/seller/dashboard"
          className="group flex-shrink-0"
          aria-label="StopNShop"
        >
          <span className="font-display text-2xl font-black tracking-tight">
            <span className="text-brand-500 group-hover:text-brand-600 transition-colors">Stop</span>
            <span className="text-content">N</span>
            <span className="text-brand-500 group-hover:text-brand-600 transition-colors">Shop</span>
          </span>
        </Link>
        {badge && (
          <span className="hidden sm:inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-brand-50 text-brand-600">
            {badge}
          </span>
        )}
      </div>

      <div className="flex items-center gap-2">{rightContent}</div>
    </div>
  </header>
);
