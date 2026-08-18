import React, { useState, useEffect } from 'react';
import { X, Sparkles } from 'lucide-react';
import { motion, useInView } from 'framer-motion';
import { HeroBanner } from './HeroBanner';
import { CategoryShowcase } from './CategoryShowcase';
import { BannerStack } from './BannerStack';
import { TrendingNow } from './TrendingNow';
import { RecentSearches } from './RecentSearches';
import { FeaturedProducts } from './FeaturedProducts';
import { FeaturesSection } from './FeaturesSection';
import { TrendingCategories } from './TrendingCategories';
import { TopBrands } from './TopBrands';
import { PromoCountdown } from './PromoCountdown';

const WELCOME_KEY = 'sns_welcome_new';

/**
 * Home composition (top → bottom):
 *   1.  Hero carousel           (admin-controlled — BannerType=1, full-bleed 78vh)
 *   2.  Promo countdown band    (urgency / sale strip with live countdown)
 *   3.  Banner stack            (admin-controlled — BannerType 2..7 promo banners)
 *   4.  Trending Categories     (admin-controlled — SubCategories.IsFeatured)
 *   5.  Top Brands              (admin-managed Brands table — themed promo cards)
 *   6.  Trending Right Now      (data-driven — 7-day rolling view count)
 *   7.  Recently Searched       (per-user chip row, signed-in only)
 *   8.  Featured Picks          (editor-curated)
 *   9.  Shop by Department      (admin-managed — Menus table, always-visible 6-card row)
 *   10. Trust strip
 *
 * Every visible block above is either admin-CMS-controlled or
 * admin-data-driven — no hardcoded images in the layout.
 */
export const HomePage: React.FC = () => {
  const [welcomeName, setWelcomeName] = useState<string | null>(null);

  useEffect(() => {
    const name = localStorage.getItem(WELCOME_KEY);
    if (name) {
      localStorage.removeItem(WELCOME_KEY);
      setWelcomeName(name);
    }
  }, []);

  return (
    <main className="bg-bg">
      {welcomeName && <WelcomeBanner name={welcomeName} onDismiss={() => setWelcomeName(null)} />}

      {/* 1 — Hero carousel. Full-bleed edge-to-edge, ~78vh on desktop. */}
      <HeroBanner />

      {/* 2 — Limited-time promo with countdown (drives urgency above the fold) */}
      <Reveal>
        <PromoCountdown />
      </Reveal>

      {/* 3 — Promotional banner stack (admin-controlled gaps). */}
      <Reveal>
        <div className="bg-surface/40 border-y border-outline/30">
          <div className="pt-4 pb-2">
            <BannerStack />
          </div>
        </div>
      </Reveal>

      {/* 4 — Trending Categories (admin toggles SubCategory.IsFeatured) */}
      <Reveal>
        <TrendingCategories />
      </Reveal>

      {/* 5 — Top Brands carousel (themed promo cards over the brand logo) */}
      <Reveal>
        <div className="bg-surface/40 border-y border-outline/30">
          <TopBrands />
        </div>
      </Reveal>

      {/* 6 — Trending Right Now */}
      <Reveal>
        <div className="bg-surface/40 border-y border-outline/30">
          <TrendingNow />
        </div>
      </Reveal>

      {/* 7 — Recently Searched (signed-in only; component handles its own gate) */}
      <Reveal>
        <RecentSearches />
      </Reveal>

      {/* 8 — Featured Picks */}
      <Reveal>
        <FeaturedProducts />
      </Reveal>

      {/* 9 — Shop by Department (always-visible top-level menu cards) */}
      <Reveal>
        <CategoryShowcase />
      </Reveal>

      {/* 10 — Trust strip */}
      <Reveal>
        <div className="bg-surface/40 border-t border-outline/30">
          <FeaturesSection />
        </div>
      </Reveal>
    </main>
  );
};

// ── Fade-in-on-scroll wrapper ─────────────────────────────────────────────
// Animates a section once when it enters the viewport. No parallax (too much for
// an e-commerce home). Respects prefers-reduced-motion via framer-motion defaults.
const Reveal: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const ref = React.useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: '-80px' });
  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 20 }}
      animate={inView ? { opacity: 1, y: 0 } : undefined}
      transition={{ duration: 0.55, ease: 'easeOut' }}
    >
      {children}
    </motion.div>
  );
};

// ── First-session welcome strip ───────────────────────────────────────────
interface WelcomeBannerProps { name: string; onDismiss: () => void; }

const WelcomeBanner: React.FC<WelcomeBannerProps> = ({ name, onDismiss }) => (
  <div className="relative bg-gradient-to-r from-brand-600 via-brand-500 to-brand-600 text-white overflow-hidden">
    <div className="absolute -left-8 -top-8 w-32 h-32 rounded-full bg-white/5" aria-hidden />
    <div className="absolute -right-4 -bottom-6 w-24 h-24 rounded-full bg-white/5" aria-hidden />
    <div className="relative max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8 py-3 flex items-center justify-between gap-4">
      <div className="flex items-center gap-3 min-w-0">
        <div className="w-8 h-8 rounded-full bg-white/15 backdrop-blur-sm flex items-center justify-center flex-shrink-0">
          <Sparkles className="h-4 w-4 text-white" />
        </div>
        <p className="font-display font-bold text-sm sm:text-base leading-tight truncate">
          Welcome, {name}! Glad you stopped to shop.
        </p>
      </div>
      <button
        onClick={onDismiss}
        aria-label="Dismiss welcome banner"
        className="flex-shrink-0 p-1.5 rounded-full hover:bg-white/15 transition-colors"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  </div>
);
