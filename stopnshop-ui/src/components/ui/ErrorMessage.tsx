import React from 'react';
import { AlertCircle } from 'lucide-react';

interface ErrorMessageProps {
  message?: string;
  onRetry?: () => void;
}

export const ErrorMessage: React.FC<ErrorMessageProps> = ({
  message = 'Something went wrong. Please try again.',
  onRetry,
}) => (
  <div className="flex flex-col items-center justify-center py-16 gap-4 text-center">
    <AlertCircle className="h-12 w-12 text-red-400" />
    <p className="text-content-muted max-w-sm">{message}</p>
    {onRetry && (
      <button
        onClick={onRetry}
        className="text-brand-500 hover:underline text-sm font-medium"
      >
        Try again
      </button>
    )}
  </div>
);
