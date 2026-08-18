import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { Spinner } from '../ui/Spinner';

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: React.ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  tone?: 'default' | 'danger';
  requireReason?: boolean;
  reasonLabel?: string;
  isLoading?: boolean;
  onConfirm: (reason?: string) => void;
  onCancel: () => void;
}

export const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  open,
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  tone = 'default',
  requireReason = false,
  reasonLabel = 'Reason',
  isLoading = false,
  onConfirm,
  onCancel,
}) => {
  const [reason, setReason] = React.useState('');

  React.useEffect(() => {
    if (open) setReason('');
  }, [open]);

  if (!open) return null;

  const isDanger = tone === 'danger';
  const confirmDisabled = isLoading || (requireReason && reason.trim().length === 0);

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="confirm-dialog-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-md rounded-xl bg-surface-elevated shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-5 border-b border-outline/60 flex items-start gap-3">
          {isDanger && (
            <div className="mt-0.5 text-rose-500">
              <AlertTriangle className="w-5 h-5" />
            </div>
          )}
          <div>
            <h2 id="confirm-dialog-title" className="text-lg font-semibold text-content">
              {title}
            </h2>
            <div className="mt-1 text-sm text-content-muted">{message}</div>
          </div>
        </div>

        {requireReason && (
          <div className="px-5 py-4 border-b border-outline/60">
            <label htmlFor="confirm-reason" className="block text-xs font-medium text-content-muted mb-1">
              {reasonLabel} <span className="text-rose-600">*</span>
            </label>
            <textarea
              id="confirm-reason"
              className="w-full px-3 py-2 text-sm border border-outline-strong rounded focus:outline-none focus:ring-2 focus:ring-[#c41230]/30"
              rows={3}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              maxLength={500}
              autoFocus
            />
          </div>
        )}

        <div className="p-4 flex items-center justify-end gap-2">
          <button
            type="button"
            onClick={onCancel}
            disabled={isLoading}
            className="px-4 py-2 text-sm font-medium text-content rounded hover:bg-surface-sunken disabled:opacity-50"
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            onClick={() => onConfirm(requireReason ? reason : undefined)}
            disabled={confirmDisabled}
            className={`px-4 py-2 text-sm font-medium text-white rounded inline-flex items-center gap-2 disabled:opacity-50 ${
              isDanger
                ? 'bg-rose-600 hover:bg-rose-700'
                : 'bg-[#c41230] hover:bg-[#a30f29]'
            }`}
          >
            {isLoading && <Spinner size="sm" />}
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
};
