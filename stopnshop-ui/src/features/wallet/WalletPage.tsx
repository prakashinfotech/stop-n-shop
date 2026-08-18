import React, { useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import {
  Wallet, ArrowDownLeft, ArrowUpRight, RefreshCw, TrendingUp, TrendingDown,
  ShoppingBag, Sparkles, ExternalLink,
} from 'lucide-react';
import { walletApi } from '../../api/walletApi';
import type { WalletTransactionDto } from '../../api/walletApi';

/** Classify a transaction by its referenceType + description so we can show a meaningful chip. */
const classifyTx = (tx: WalletTransactionDto): { label: string; tone: 'refund' | 'purchase' | 'bonus' | 'other'; orderLinkId?: number } => {
  const ref  = (tx.referenceType ?? '').toUpperCase();
  const desc = (tx.description ?? '').toLowerCase();
  if (ref === 'ORDER' && tx.transactionType === 1) return { label: 'Refund',   tone: 'refund',   orderLinkId: tx.referenceId };
  if (ref === 'ORDER' && tx.transactionType === 2) return { label: 'Purchase', tone: 'purchase', orderLinkId: tx.referenceId };
  if (desc.includes('welcome') || desc.includes('bonus') || desc.includes('cashback')) return { label: 'Bonus', tone: 'bonus' };
  if (tx.transactionType === 1) return { label: 'Credit', tone: 'other' };
  return { label: 'Debit', tone: 'other' };
};

const TONE_CHIP: Record<string, string> = {
  refund:   'bg-green-50  text-green-700  border-green-200',
  purchase: 'bg-stone-100 text-stone-700  border-stone-200',
  bonus:    'bg-amber-50  text-amber-700  border-amber-200',
  other:    'bg-surface   text-content-muted border-outline',
};

export const WalletPage: React.FC = () => {
  const [page, setPage] = useState(1);
  const PAGE_SIZE = 10;

  const { data, isLoading } = useQuery({
    queryKey: ['wallet', page],
    queryFn: () => walletApi.getWallet(page, PAGE_SIZE).then((r) => r.data.data),
  });

  const wallet       = data?.wallet;
  const transactions = data?.transactions ?? [];
  const totalPages   = data?.totalPages ?? 1;

  // Roll-up: total credited / total debited across *this page* of transactions.
  // (Server-side aggregate would be ideal — keep the UI honest with the "this page" caveat.)
  const { credited, debited } = useMemo(() => {
    let c = 0, d = 0;
    transactions.forEach((t) => (t.transactionType === 1 ? c += t.amount : d += t.amount));
    return { credited: c, debited: d };
  }, [transactions]);

  const formatAmount = (amount: number) =>
    new Intl.NumberFormat('en-IN', { minimumFractionDigits: 2 }).format(amount);

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString('en-IN', {
      day: 'numeric', month: 'short', year: 'numeric',
    });

  const formatTime = (dateStr: string) =>
    new Date(dateStr).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });

  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      {/* Header */}
      <div className="mb-6">
        <h1 className="font-display text-2xl font-bold text-content">My Wallet</h1>
        <p className="text-sm text-content-muted mt-1">Balance, refunds, and transaction history in one place.</p>
      </div>

      {/* Balance card — brand-gradient with subtle decorative ring. */}
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative overflow-hidden bg-gradient-to-br from-stone-900 via-stone-900 to-brand-700 rounded-3xl p-6 sm:p-7 mb-5 text-white shadow-soft-lg"
      >
        <div className="absolute -right-10 -top-10 w-44 h-44 rounded-full bg-white/5" aria-hidden />
        <div className="absolute -right-4 -bottom-6 w-28 h-28 rounded-full bg-white/5" aria-hidden />
        <div className="relative">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-white/10 backdrop-blur rounded-xl flex items-center justify-center">
              <Wallet className="h-5 w-5 text-white" />
            </div>
            <div>
              <p className="text-[11px] text-white/70 font-semibold uppercase tracking-widest">StopNShop Wallet</p>
              <p className="text-xs text-white/60">Refunds and cashback are credited here automatically</p>
            </div>
          </div>
          <div>
            <p className="text-[11px] text-white/60 uppercase tracking-wider mb-1">Available balance</p>
            {isLoading ? (
              <div className="h-10 w-40 bg-white/10 rounded-lg animate-pulse" />
            ) : (
              <p className="text-4xl sm:text-5xl font-black tracking-tight tabular-nums">
                ₹{wallet ? formatAmount(wallet.balance) : '0.00'}
              </p>
            )}
            {wallet && (
              <p className="text-[11px] text-white/60 mt-1.5">Last updated {formatDate(wallet.updatedAt)}</p>
            )}
          </div>
        </div>
      </motion.div>

      {/* Quick stats — totals for the currently visible page. */}
      <div className="grid grid-cols-2 gap-3 mb-8">
        <StatTile
          icon={<TrendingUp className="h-4 w-4" />}
          label="Credited (this page)"
          value={`₹${formatAmount(credited)}`}
          tone="green"
        />
        <StatTile
          icon={<TrendingDown className="h-4 w-4" />}
          label="Spent (this page)"
          value={`₹${formatAmount(debited)}`}
          tone="red"
        />
      </div>

      {/* Transactions */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-base font-semibold text-content">Transaction History</h2>
          {!isLoading && transactions.length > 0 && (
            <p className="text-xs text-content-muted">Showing page {page} of {totalPages}</p>
          )}
        </div>

        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-20 bg-surface-sunken rounded-2xl animate-pulse" />
            ))}
          </div>
        ) : transactions.length === 0 ? (
          <div className="text-center py-16 bg-surface-elevated rounded-2xl border border-outline/60">
            <div className="w-14 h-14 bg-surface rounded-full flex items-center justify-center mx-auto mb-3">
              <RefreshCw className="h-6 w-6 text-content-subtle" />
            </div>
            <p className="font-semibold text-content mb-1">No transactions yet</p>
            <p className="text-sm text-content-subtle">Order refunds and welcome credits will appear here.</p>
          </div>
        ) : (
          <>
            <div className="bg-surface-elevated rounded-2xl border border-outline/60 divide-y divide-outline/60 overflow-hidden">
              {transactions.map((tx) => {
                const isCredit = tx.transactionType === 1;
                const meta = classifyTx(tx);
                const icon =
                  meta.tone === 'refund'   ? <ArrowDownLeft className="h-4 w-4 text-green-600" /> :
                  meta.tone === 'purchase' ? <ShoppingBag   className="h-4 w-4 text-stone-600" /> :
                  meta.tone === 'bonus'    ? <Sparkles      className="h-4 w-4 text-amber-600" /> :
                  isCredit                 ? <ArrowDownLeft className="h-4 w-4 text-green-600" /> :
                                             <ArrowUpRight  className="h-4 w-4 text-red-500"   />;
                return (
                  <div key={tx.transactionId} className="flex items-center gap-4 px-5 py-4 hover:bg-surface/50 transition-colors">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
                      meta.tone === 'refund'   ? 'bg-green-50' :
                      meta.tone === 'purchase' ? 'bg-stone-100' :
                      meta.tone === 'bonus'    ? 'bg-amber-50' :
                      isCredit                 ? 'bg-green-50' : 'bg-red-50'
                    }`}>
                      {icon}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className={`text-[10px] font-bold tracking-wider uppercase px-2 py-0.5 rounded-full border ${TONE_CHIP[meta.tone]}`}>
                          {meta.label}
                        </span>
                        {meta.orderLinkId && (
                          <Link
                            to={`/user/orders/${meta.orderLinkId}`}
                            className="inline-flex items-center gap-1 text-[11px] font-semibold text-brand-500 hover:text-brand-600"
                          >
                            View order <ExternalLink className="h-3 w-3" />
                          </Link>
                        )}
                      </div>
                      <p className="text-sm font-medium text-content truncate mt-1">{tx.description}</p>
                      <p className="text-xs text-content-subtle mt-0.5 tabular-nums">
                        {formatDate(tx.createdAt)} · {formatTime(tx.createdAt)}
                      </p>
                    </div>
                    <p className={`text-base font-bold flex-shrink-0 tabular-nums ${isCredit ? 'text-green-600' : 'text-red-500'}`}>
                      {isCredit ? '+' : '−'}₹{formatAmount(tx.amount)}
                    </p>
                  </div>
                );
              })}
            </div>

            {totalPages > 1 && (
              <div className="flex items-center justify-center gap-3 mt-6">
                <button
                  disabled={page <= 1}
                  onClick={() => setPage((p) => p - 1)}
                  className="px-4 py-2 border border-outline rounded-xl text-sm font-medium text-content hover:bg-surface transition-colors disabled:opacity-40"
                >
                  Previous
                </button>
                <span className="text-sm text-content-muted tabular-nums">{page} / {totalPages}</span>
                <button
                  disabled={page >= totalPages}
                  onClick={() => setPage((p) => p + 1)}
                  className="px-4 py-2 border border-outline rounded-xl text-sm font-medium text-content hover:bg-surface transition-colors disabled:opacity-40"
                >
                  Next
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

// ── Stat tile ────────────────────────────────────────────────────────────
const StatTile: React.FC<{ icon: React.ReactNode; label: string; value: string; tone: 'green' | 'red' }> = ({ icon, label, value, tone }) => (
  <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-4 flex items-center gap-3">
    <div className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 ${
      tone === 'green' ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-500'
    }`}>
      {icon}
    </div>
    <div className="min-w-0">
      <p className="text-[11px] text-content-muted uppercase tracking-wider truncate">{label}</p>
      <p className="text-lg font-bold text-content tabular-nums">{value}</p>
    </div>
  </div>
);
