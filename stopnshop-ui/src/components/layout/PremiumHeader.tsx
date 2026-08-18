import React from 'react';
import { Link } from 'react-router-dom';

interface PremiumHeaderProps {
  logo?: React.ReactNode;
  rightContent?: React.ReactNode;
  className?: string;
}

export const PremiumHeader: React.FC<PremiumHeaderProps> = ({
  logo,
  rightContent,
  className = '',
}) => (
  <header className={`bg-surface-elevated border-b border-outline/60 sticky top-0 z-40 ${className}`}>
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
      {/* Logo */}
      <Link to="/" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
        {logo || (
          <>
            <div className="w-8 h-8 bg-gradient-brand rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-lg">S</span>
            </div>
            <span className="text-lg font-bold text-content">StopNShop</span>
          </>
        )}
      </Link>

      {/* Right Content */}
      <div className="flex items-center gap-4">{rightContent}</div>
    </div>
  </header>
);
