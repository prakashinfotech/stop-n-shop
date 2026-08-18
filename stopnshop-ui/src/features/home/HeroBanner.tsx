import React, { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight, ArrowRight, Sparkles } from 'lucide-react';
import { catalogueApi } from '../../api/catalogueApi';
import type { Banner } from '../../types/catalogue.types';

/**
 * Premium hero carousel.
 *
 * Aesthetics — claude.ai-style warm surfaces, subtle dual gradient overlay,
 * refined display typography, primary + secondary CTA pair, crossfade between
 * slides with a slow Ken-Burns scale, hairline brand-coloured progress bar
 * showing time-to-next.
 *
 * Slides come from the Banners table (BannerType = 1 = Hero) — admin controls
 * what's shown. The 3-slide lifestyle fallback ships so the surface never
 * feels empty before any banners are uploaded.
 */

const FALLBACK_SLIDES: Banner[] = [
  {
    id: 1,
    imageUrl:
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1800&q=85&auto=format&fit=crop',
    title:    'The Spring Edit',
    subtitle: "Lightweight linens, breezy florals, and the sandals you'll live in.",
    linkUrl:  '/home/products?sortBy=LATEST',
    section:  1,
    sortOrder: 0,
  },
  {
    id: 2,
    imageUrl:
      'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?w=1800&q=85&auto=format&fit=crop',
    title:    'Men, refined.',
    subtitle: 'Wardrobe classics — tailored shirts, soft tees, the perfect pair of chinos.',
    linkUrl:  '/home/category/clothing?gender=1',
    section:  1,
    sortOrder: 0,
  },
  {
    id: 3,
    imageUrl:
      'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=1800&q=85&auto=format&fit=crop',
    title:    'Footwear that goes everywhere',
    subtitle: 'From boardroom loafers to weekend trainers — built for the long walk home.',
    linkUrl:  '/home/category/footwear',
    section:  1,
    sortOrder: 0,
  },
];

const DURATION_MS = 6000;

export const HeroBanner: React.FC = () => {
  const [current, setCurrent] = useState(0);
  const [paused, setPaused]   = useState(false);
  const progressKey           = useRef(0);

  const { data: apiBanners } = useQuery({
    queryKey: ['banners', 1],
    queryFn: () => catalogueApi.getBanners(1).then((r) => r.data.data),
    staleTime: 1000 * 60 * 5,
  });

  const slides = apiBanners && apiBanners.length > 0 ? apiBanners : FALLBACK_SLIDES;

  // Auto-advance, pause on hover + when the tab is hidden.
  useEffect(() => {
    if (paused || slides.length <= 1) return;
    const id = setInterval(() => setCurrent((c) => (c + 1) % slides.length), DURATION_MS);
    return () => clearInterval(id);
  }, [paused, slides.length]);

  useEffect(() => {
    const onVis = () => setPaused(document.hidden);
    document.addEventListener('visibilitychange', onVis);
    return () => document.removeEventListener('visibilitychange', onVis);
  }, []);

  // Restart the progress bar cleanly on every slide change.
  useEffect(() => { progressKey.current += 1; }, [current]);

  const slide = slides[current];
  const next  = () => setCurrent((c) => (c + 1) % slides.length);
  const prev  = () => setCurrent((c) => (c - 1 + slides.length) % slides.length);

  return (
    <section
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      className="relative w-full overflow-hidden bg-stone-950"
      // Sized so Hero (~70vh) + PromoCountdown strip (~15vh) + header (~12vh)
      // together sit within a single viewport — the offer is always
      // above-the-fold on first load.
      style={{ height: 'clamp(380px, 70vh, 700px)' }}
      aria-roledescription="carousel"
      aria-label="Featured promotions"
    >
      {/* Slides — crossfade + slow Ken-Burns */}
      <AnimatePresence initial={false}>
        <motion.div
          key={slide.id}
          initial={{ opacity: 0, scale: 1.06 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 1 }}
          transition={{ opacity: { duration: 0.9 }, scale: { duration: 7, ease: 'easeOut' } }}
          className="absolute inset-0 bg-cover bg-center"
          style={{ backgroundImage: `url(${slide.imageUrl})` }}
          aria-hidden
        />
      </AnimatePresence>

      {/* Warm dual overlay — softer than a hard black wash. Symmetric vertical
          wash keeps copy legible when centered without a horizontal pull to one side. */}
      <div className="absolute inset-0 bg-gradient-to-t from-stone-950/65 via-stone-950/20 to-stone-950/40" />
      <div className="absolute inset-0 bg-stone-950/15" />

      {/* Copy block — centered */}
      <div className="relative z-10 max-w-screen-2xl mx-auto h-full px-4 sm:px-8 lg:px-16 flex items-center justify-center">
        <div className="max-w-3xl text-white text-center space-y-6 flex flex-col items-center">
          <motion.div
            key={`eyebrow-${slide.id}`}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: 'easeOut' }}
            className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/12 backdrop-blur-sm border border-white/20 text-[11px] uppercase tracking-[0.18em] font-semibold text-white/90"
          >
            <Sparkles className="h-3 w-3 text-amber-300" />
            Curated for you
          </motion.div>

          <motion.h1
            key={`title-${slide.id}`}
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: 'easeOut', delay: 0.05 }}
            className="font-display font-bold leading-[1.02] tracking-tight"
            style={{ fontSize: 'clamp(2.25rem, 5.5vw, 4.25rem)' }}
          >
            {slide.title}
          </motion.h1>

          {slide.subtitle && (
            <motion.p
              key={`sub-${slide.id}`}
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, ease: 'easeOut', delay: 0.12 }}
              className="text-white/85 leading-relaxed max-w-xl"
              style={{ fontSize: 'clamp(1rem, 1.4vw, 1.25rem)' }}
            >
              {slide.subtitle}
            </motion.p>
          )}

          {/* CTA pair — primary brand + secondary ghost. Both legible on the warm wash. */}
          <motion.div
            key={`cta-${slide.id}`}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: 'easeOut', delay: 0.18 }}
            className="flex flex-wrap items-center justify-center gap-3 pt-2"
          >
            {slide.linkUrl && (
              <Link
                to={slide.linkUrl}
                className="group inline-flex items-center gap-2 bg-brand-500 hover:bg-brand-600 text-white font-semibold px-6 py-3 rounded-full text-sm transition-all hover:translate-x-0.5 hover:shadow-xl shadow-brand-900/20"
              >
                Shop the edit
                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
              </Link>
            )}
            <Link
              to="/home/products"
              className="inline-flex items-center gap-2 text-white/85 hover:text-white border border-white/30 hover:border-white/60 font-medium px-5 py-2.5 rounded-full text-sm transition-colors backdrop-blur-sm"
            >
              Browse all
            </Link>
          </motion.div>

          {slides.length > 1 && (
            <div className="flex items-center justify-center gap-1.5 pt-4">
              {slides.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setCurrent(i)}
                  aria-label={`Go to slide ${i + 1}`}
                  className={`rounded-full transition-all duration-300 ${
                    i === current
                      ? 'w-7 h-1.5 bg-white'
                      : 'w-1.5 h-1.5 bg-white/40 hover:bg-white/75'
                  }`}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {slides.length > 1 && (
        <>
          <button
            onClick={prev}
            aria-label="Previous slide"
            className="hidden sm:flex absolute left-4 lg:left-6 top-1/2 -translate-y-1/2 z-20 w-10 h-10 items-center justify-center rounded-full bg-white/10 hover:bg-white/25 backdrop-blur-md text-white transition-colors"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <button
            onClick={next}
            aria-label="Next slide"
            className="hidden sm:flex absolute right-4 lg:right-6 top-1/2 -translate-y-1/2 z-20 w-10 h-10 items-center justify-center rounded-full bg-white/10 hover:bg-white/25 backdrop-blur-md text-white transition-colors"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
        </>
      )}

      {/* Time-to-next progress bar — hairline at the bottom edge */}
      {slides.length > 1 && !paused && (
        <div className="absolute bottom-0 left-0 right-0 z-20 h-[3px] bg-white/8">
          <motion.div
            key={`progress-${current}-${progressKey.current}`}
            initial={{ width: 0 }}
            animate={{ width: '100%' }}
            transition={{ duration: DURATION_MS / 1000, ease: 'linear' }}
            className="h-full bg-brand-500"
          />
        </div>
      )}
    </section>
  );
};
