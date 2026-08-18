import React, { useEffect } from 'react';
import { X } from 'lucide-react';
import { clsx } from 'clsx';

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  description?: string;
  children: React.ReactNode;
  /** Tailwind max-width class (e.g. `max-w-lg`). */
  maxWidth?: string;
  /** Hide the default close (X) button in the header. */
  hideClose?: boolean;
}

export const Modal: React.FC<ModalProps> = ({
  open,
  onClose,
  title,
  description,
  children,
  maxWidth = 'max-w-lg',
  hideClose = false,
}) => {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  useEffect(() => {
    document.body.style.overflow = open ? 'hidden' : '';
    return () => { document.body.style.overflow = ''; };
  }, [open]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-modal flex items-center justify-center p-4"
      style={{ zIndex: 'var(--z-modal)' as React.CSSProperties['zIndex'] }}
      role="dialog"
      aria-modal="true"
      aria-labelledby={title ? 'modal-title' : undefined}
    >
      <div
        className="absolute inset-0 bg-stone-900/40 backdrop-blur-sm"
        onClick={onClose}
      />
      <div
        className={clsx(
          'relative bg-surface-elevated rounded-3xl shadow-soft-xl w-full z-10',
          'animate-in fade-in zoom-in-95 duration-200',
          maxWidth,
        )}
      >
        {(title || !hideClose) && (
          <div className="flex items-start justify-between px-7 pt-6 pb-3">
            <div className="flex-1 min-w-0">
              {title && (
                <h2 id="modal-title" className="font-display text-xl font-semibold text-content">
                  {title}
                </h2>
              )}
              {description && (
                <p className="text-sm text-content-muted mt-1">{description}</p>
              )}
            </div>
            {!hideClose && (
              <button
                onClick={onClose}
                aria-label="Close"
                className="p-2 -mr-2 rounded-xl text-content-subtle hover:text-content hover:bg-surface transition-colors flex-shrink-0"
              >
                <X className="h-5 w-5" />
              </button>
            )}
          </div>
        )}
        <div className="px-7 pb-7 pt-2">{children}</div>
      </div>
    </div>
  );
};
