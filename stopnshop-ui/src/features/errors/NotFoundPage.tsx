import React from 'react';
import { Link } from 'react-router-dom';

export const NotFoundPage: React.FC = () => (
  <div className="min-h-[70vh] flex flex-col items-center justify-center text-center px-4">
    <p className="text-8xl font-display font-bold text-content-subtle">404</p>
    <h1 className="text-2xl font-semibold text-content mt-2 mb-2">Page Not Found</h1>
    <p className="text-content-muted max-w-sm mb-8">
      The page you're looking for doesn't exist or has been moved.
    </p>
    <Link
      to="/home"
      className="bg-brand-500 hover:bg-brand-600 text-white font-medium px-8 py-3 rounded-full transition-colors"
    >
      Back to Home
    </Link>
  </div>
);
