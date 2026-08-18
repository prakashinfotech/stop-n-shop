import React from 'react';
import { PremiumHeader } from './PremiumHeader';

interface AuthLayoutProps {
  children: React.ReactNode;
  variant?: 'buyer' | 'seller';
}

export const AuthLayout: React.FC<AuthLayoutProps> = ({ children, variant = 'buyer' }) => (
  <div className="min-h-screen bg-gradient-to-br from-bg via-surface to-bg">
    <PremiumHeader />

    <div className="flex items-center justify-center px-4 py-14 min-h-[calc(100vh-64px)]">
      <div className="w-full max-w-md">
        {/* Header */}
        <div className="mb-8 text-center">
          <h1 className="text-3xl md:text-4xl font-display font-bold text-content mb-2">
            {variant === 'buyer' ? 'Welcome Back' : 'Seller Portal'}
          </h1>
          <p className="text-content-muted">
            {variant === 'buyer'
              ? 'Sign in to shop premium fashion'
              : 'Manage your store and products'}
          </p>
        </div>

        {/* Content */}
        <div className="bg-surface-elevated rounded-3xl shadow-soft-md p-8 md:p-10">
          {children}
        </div>

        {/* Footer Links */}
        <div className="mt-8 text-center text-sm text-content-muted">
          {variant === 'buyer' ? (
            <>
              Are you a seller?{' '}
              <a href="/seller/login" className="text-brand-500 font-semibold hover:underline">
                Sell on StopNShop
              </a>
            </>
          ) : (
            <>
              Shopping?{' '}
              <a href="/login" className="text-brand-500 font-semibold hover:underline">
                Browse as Customer
              </a>
            </>
          )}
        </div>
      </div>
    </div>
  </div>
);
