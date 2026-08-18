import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Flame, ArrowRight } from 'lucide-react';

/**
 * Sleek limited-time promo strip. Sized to ~15vh so it pairs with the Hero
 * banner inside a single viewport — both sit above-the-fold on first load.
 *
 * Layout (single horizontal row, no wrapping on lg+):
 *   [ FLAME · Limited time · FLAT 50% OFF ]      [ DD : HH : MM : SS ]      [ Shop now → ]
 *
 * The target rolls forward to "next Sunday midnight" each week so the band
 * never goes negative — when admin CMS gains a real `promoEndsAt` field this
 * component can read it instead.
 */
const ROLLING_END = (): Date => {
  const now = new Date();
  const end = new Date(now);
  const daysToSunday = (7 - now.getDay()) % 7 || 7;
  end.setDate(now.getDate() + daysToSunday);
  end.setHours(23, 59, 59, 999);
  return end;
};

interface TimeLeft { days: number; hours: number; minutes: number; seconds: number; }

const diff = (target: Date): TimeLeft => {
  const total = Math.max(0, target.getTime() - Date.now());
  return {
    days:    Math.floor(total / 86_400_000),
    hours:   Math.floor((total / 3_600_000) % 24),
    minutes: Math.floor((total / 60_000) % 60),
    seconds: Math.floor((total / 1000) % 60),
  };
};

export const PromoCountdown: React.FC = () => {
  const [target] = useState<Date>(() => ROLLING_END());
  const [left, setLeft] = useState<TimeLeft>(() => diff(target));

  useEffect(() => {
    const id = setInterval(() => setLeft(diff(target)), 1000);
    return () => clearInterval(id);
  }, [target]);

  return (
    <section
      aria-label="Limited-time sale"
      className="relative w-full overflow-hidden bg-gradient-to-r from-brand-700 via-brand-600 to-brand-700 text-white"
      // Sleek strip — clamped so it stays visually balanced from small tablets
      // through ultra-wide monitors but never grabs more than ~15vh on a
      // standard 16:9 display.
      style={{ height: 'clamp(120px, 15vh, 180px)' }}
    >
      {/* Decorative warm orbs — tiny + edge-anchored so they don't compete
          with the centred countdown row */}
      <div className="absolute -left-12 top-1/2 -translate-y-1/2 w-32 h-32 rounded-full bg-amber-400/15 blur-2xl" aria-hidden />
      <div className="absolute -right-12 top-1/2 -translate-y-1/2 w-32 h-32 rounded-full bg-brand-300/20 blur-2xl" aria-hidden />

      <div className="relative w-full h-full px-4 sm:px-6 lg:px-10 flex items-center">
        <div className="w-full grid grid-cols-1 lg:grid-cols-[1fr_auto_1fr] items-center gap-3 lg:gap-6">

          {/* Left — headline */}
          <div className="flex items-center gap-3 min-w-0">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/15 backdrop-blur-sm border border-white/25 text-[10px] uppercase tracking-[0.18em] font-bold flex-shrink-0">
              <Flame className="h-3.5 w-3.5 text-amber-300" />
              Limited
            </span>
            <h2
              className="font-display font-bold leading-none tracking-tight truncate"
              style={{ fontSize: 'clamp(1.25rem, 2.4vw, 2rem)' }}
            >
              Flat <span className="text-amber-300">50% OFF</span>
              <span className="hidden sm:inline text-white/85 font-normal text-[0.7em] ml-2">· season&rsquo;s edit</span>
            </h2>
          </div>

          {/* Center — countdown chips. Tight, monospaced. */}
          <div className="flex items-center justify-center gap-1.5 sm:gap-2 flex-shrink-0">
            <CountdownChip value={left.days}    label="d" />
            <Colon />
            <CountdownChip value={left.hours}   label="h" />
            <Colon />
            <CountdownChip value={left.minutes} label="m" />
            <Colon />
            <CountdownChip value={left.seconds} label="s" pulse />
          </div>

          {/* Right — CTAs */}
          <div className="flex items-center justify-start lg:justify-end gap-2 flex-shrink-0">
            <Link
              to="/home/products?sortBy=DISCOUNT"
              className="group inline-flex items-center gap-1.5 bg-white hover:bg-amber-50 text-brand-700 font-bold px-4 py-2 rounded-full text-xs sm:text-sm transition-all hover:translate-x-0.5 shadow-soft"
            >
              Shop the sale
              <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" />
            </Link>
            <Link
              to="/home/products"
              className="hidden sm:inline-flex items-center gap-1 text-white/85 hover:text-white border border-white/30 hover:border-white/60 font-medium px-3 py-1.5 rounded-full text-xs transition-colors"
            >
              Browse all
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
};

interface ChipProps { value: number; label: string; pulse?: boolean; }

const CountdownChip: React.FC<ChipProps> = ({ value, label, pulse }) => (
  <div
    className={`flex items-baseline gap-0.5 px-2 sm:px-2.5 py-1 rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 ${
      pulse ? 'ring-1 ring-amber-300/40' : ''
    }`}
  >
    <span
      className="font-display font-bold leading-none tabular-nums"
      style={{ fontSize: 'clamp(1rem, 1.8vw, 1.5rem)' }}
    >
      {String(value).padStart(2, '0')}
    </span>
    <span className="text-[9px] sm:text-[10px] uppercase tracking-wider font-semibold text-white/75">
      {label}
    </span>
  </div>
);

const Colon: React.FC = () => (
  <span className="text-white/40 font-bold text-sm sm:text-base leading-none" aria-hidden>
    :
  </span>
);
