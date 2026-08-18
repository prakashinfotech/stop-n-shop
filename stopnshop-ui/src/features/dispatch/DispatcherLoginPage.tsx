import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Truck, Mail, Lock, Eye, EyeOff, AlertCircle, ArrowRight } from 'lucide-react';
import { useDispatcherAuth } from './useDispatcherAuth';

/**
 * Dispatcher login. Simpler than the seller two-panel marketing layout —
 * dispatchers log in from a phone, often outside, often in a hurry. Single
 * column, big inputs, big button. Brand strip at top instead of a side panel.
 */
export const DispatcherLoginPage: React.FC = () => {
  const navigate = useNavigate();
  const { login } = useDispatcherAuth();

  const [email,       setEmail]       = useState('');
  const [password,    setPassword]    = useState('');
  const [showPw,      setShowPw]      = useState(false);
  const [submitting,  setSubmitting]  = useState(false);
  const [apiError,    setApiError]    = useState('');

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setApiError('');
    if (!email || !password) {
      setApiError('Email and password are required.');
      return;
    }
    setSubmitting(true);
    try {
      await login(email, password);
      navigate('/dispatch/today', { replace: true });
    } catch (err: any) {
      setApiError(err.response?.data?.message ?? err.message ?? 'Login failed.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-bg flex flex-col">
      {/* Brand strip — full-width, dark, mobile-friendly */}
      <header className="bg-stone-900 text-white px-4 sm:px-6 py-4 flex items-center justify-between">
        <Link to="/" className="font-display text-xl font-bold tracking-tight">
          Stop<span className="text-brand-300">N</span>Shop
        </Link>
        <span className="inline-flex items-center gap-1.5 text-xs uppercase tracking-widest text-stone-300">
          <Truck className="h-3.5 w-3.5 text-brand-400" />
          Dispatcher Portal
        </span>
      </header>

      <main className="flex-1 flex items-center justify-center px-4 py-10">
        <div className="w-full max-w-md">
          <div className="text-center mb-6">
            <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-brand-500 text-white mb-4">
              <Truck className="h-7 w-7" />
            </div>
            <h1 className="font-display text-2xl font-bold text-content">Sign in to deliver</h1>
            <p className="text-sm text-content-muted mt-1">
              Pickup queue, active routes, and proof of delivery — all in one place.
            </p>
          </div>

          <form
            onSubmit={onSubmit}
            className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-6 space-y-4"
          >
            {apiError && (
              <div className="flex items-start gap-2 text-sm bg-red-50 border border-red-200 text-red-700 rounded-xl px-3 py-2">
                <AlertCircle className="h-4 w-4 flex-shrink-0 mt-0.5" />
                <span>{apiError}</span>
              </div>
            )}

            <label className="block">
              <span className="text-xs font-medium text-content-muted">Email</span>
              <div className="relative mt-1">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                <input
                  type="email"
                  inputMode="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="dispatch@stopnshop.com"
                  className="w-full pl-9 pr-3 py-3 border border-outline rounded-xl text-sm bg-surface-sunken focus:outline-none focus:bg-surface-elevated focus:border-brand-400 focus:ring-2 focus:ring-brand-200 transition"
                />
              </div>
            </label>

            <label className="block">
              <span className="text-xs font-medium text-content-muted">Password</span>
              <div className="relative mt-1">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                <input
                  type={showPw ? 'text' : 'password'}
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Your password"
                  className="w-full pl-9 pr-10 py-3 border border-outline rounded-xl text-sm bg-surface-sunken focus:outline-none focus:bg-surface-elevated focus:border-brand-400 focus:ring-2 focus:ring-brand-200 transition"
                />
                <button
                  type="button"
                  onClick={() => setShowPw((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content"
                  aria-label={showPw ? 'Hide password' : 'Show password'}
                >
                  {showPw ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </label>

            <button
              type="submit"
              disabled={submitting}
              className="w-full inline-flex items-center justify-center gap-2 bg-brand-500 hover:bg-brand-600 disabled:opacity-50 text-white font-semibold px-4 py-3 rounded-xl transition-colors"
            >
              {submitting ? 'Signing in…' : (<>Sign in <ArrowRight className="h-4 w-4" /></>)}
            </button>

            <p className="text-[11px] text-center text-content-subtle">
              Account managed by admin — talk to ops if your login isn't working.
            </p>
          </form>
        </div>
      </main>
    </div>
  );
};
