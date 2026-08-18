import React, { useState } from 'react';
import { Gift, X, Sparkles } from 'lucide-react';
import { useAuthContext } from '../../context/AuthContext';
import { walletApi } from '../../api/walletApi';
import { useToast } from './Toast';

export const WelcomeBonusModal: React.FC = () => {
  const { user, token, setAuth } = useAuthContext();
  const { showToast } = useToast();
  const [open, setOpen] = useState(true);
  const [claiming, setClaiming] = useState(false);

  // Show only for authenticated Buyers on their very first login.
  if (!token || !user || user.role !== 'Buyer' || !user.isFirstLogin || !open) {
    return null;
  }

  const close = (claimed: boolean = false) => {
    setOpen(false);
    if (token) setAuth(token, { ...user, isFirstLogin: false });
    // If the user dismisses without claiming, tell the server too so the popup
    // doesn't reshow on the next login. Best-effort — failure is non-fatal.
    if (!claimed) {
      walletApi.dismissWelcomeBonus().catch(() => { /* ignore */ });
    }
  };

  const claim = async () => {
    setClaiming(true);
    try {
      const res = await walletApi.claimWelcomeBonus();
      const data = res.data.data;
      if (data?.claimed) {
        showToast(`₹${data.amountCredited.toFixed(0)} credited to your wallet!`, 'success');
      } else {
        showToast(data?.message ?? 'Welcome bonus already claimed.', 'info' as any);
      }
      close(true);
    } catch (err: any) {
      const msg = err?.response?.data?.message ?? 'Could not credit welcome bonus right now.';
      showToast(msg, 'error');
    } finally {
      setClaiming(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 px-4">
      <div className="bg-surface-elevated rounded-3xl max-w-sm w-full p-6 text-center space-y-5 relative shadow-2xl">
        <button
          onClick={() => close()}
          aria-label="Close"
          className="absolute top-3 right-3 text-content-subtle hover:text-content-muted"
        >
          <X className="h-5 w-5" />
        </button>

        <div className="mx-auto w-16 h-16 rounded-full bg-gradient-to-br from-brand-500 to-amber-500 flex items-center justify-center text-white">
          <Gift className="h-8 w-8" />
        </div>

        <div className="space-y-1">
          <h2 className="font-display text-2xl font-bold text-content flex items-center justify-center gap-2">
            Welcome to StopNShop!
            <Sparkles className="h-5 w-5 text-amber-400" />
          </h2>
          <p className="text-content-muted text-sm">
            You've won a <span className="font-bold text-brand-500">₹500 coupon</span>
            <br />
            on your first sign-in. Click to add it to your wallet.
          </p>
        </div>

        <button
          onClick={claim}
          disabled={claiming}
          className="w-full py-3 bg-brand-500 hover:bg-brand-600 disabled:opacity-60 text-white rounded-xl font-semibold transition-colors"
        >
          {claiming ? 'Crediting…' : 'Click to avail ₹500'}
        </button>

        <button
          onClick={() => close()}
          className="text-xs text-content-subtle hover:text-content-muted"
        >
          Maybe later
        </button>
      </div>
    </div>
  );
};
