import React, { useMemo, useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { catalogueApi } from '../../api/catalogueApi';
import type { Banner } from '../../types/catalogue.types';

/**
 * Renders every promotional banner (BannerType 2..7) in a single ordered stack.
 * Banners with the same `section` collapse into a single auto-rotating carousel
 * (so admins can publish several variants of the same slot). Each block respects
 * its `gapBelowPx` so the home rhythm is admin-controlled, not hard-coded.
 */
export const BannerStack: React.FC = () => {
  const { data: banners = [], isLoading } = useQuery({
    queryKey: ['banner-stack'],
    queryFn: () => catalogueApi.getBannerStack().then((r) => r.data.data ?? []),
    staleTime: 1000 * 60 * 5,
  });

  // Group consecutive banners with the same section so multi-slide slots still rotate.
  const groups = useMemo(() => groupBySection(banners), [banners]);

  if (isLoading) {
    return (
      <div className="w-full py-4 space-y-4">
        {Array.from({ length: 2 }).map((_, i) => (
          <div
            key={i}
            className="w-full bg-surface-sunken animate-pulse"
            style={{ height: 'clamp(180px, 22vw, 320px)' }}
          />
        ))}
      </div>
    );
  }

  if (groups.length === 0) return null;

  return (
    <div className="w-full">
      {groups.map((group, idx) => (
        <BannerGroup
          key={`grp-${idx}-${group[0].id}`}
          banners={group}
          gapBelowPx={group[group.length - 1].gapBelowPx ?? 16}
        />
      ))}
    </div>
  );
};

// ── One carousel block (one or many banners that share a section) ─────────
const BannerGroup: React.FC<{ banners: Banner[]; gapBelowPx: number }> = ({ banners, gapBelowPx }) => {
  const [current, setCurrent] = useState(0);
  const [paused, setPaused]   = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    if (paused || banners.length <= 1) return;
    const timer = setInterval(() => setCurrent((p) => (p + 1) % banners.length), 5500);
    return () => clearInterval(timer);
  }, [banners.length, paused]);

  const slide = banners[current];
  const surfaceBg = slide.backgroundColor || undefined;

  const go = (offset: number) =>
    setCurrent((c) => (c + offset + banners.length) % banners.length);

  const handleClick = () => {
    if (slide.linkUrl) navigate(slide.linkUrl);
  };

  return (
    <section
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      style={{
        marginBottom: `${gapBelowPx}px`,
        backgroundColor: surfaceBg,
      }}
      className="relative"
      aria-roledescription="carousel"
    >
      <div className="w-full">
        <div
          onClick={handleClick}
          role={slide.linkUrl ? 'button' : undefined}
          tabIndex={slide.linkUrl ? 0 : undefined}
          onKeyDown={slide.linkUrl ? (e) => e.key === 'Enter' && handleClick() : undefined}
          className={`relative w-full overflow-hidden ${
            slide.linkUrl ? 'cursor-pointer' : ''
          }`}
          // Full-bleed banner — responsive height clamp keeps the strip readable
          // on tablets (180px floor) without dominating the page on ultra-wide
          // monitors (320px ceiling). No aspect-ratio: CSS aspect-ratio + max-
          // height clips WIDTH to maintain the ratio, which left the banner
          // narrower than the viewport on >1280px screens. Width is now 100%.
          style={{ height: 'clamp(180px, 22vw, 320px)' }}
        >
          {/* Fallback surface — visible when the banner has no imageUrl or while the
              image is still loading. Prevents the giant white empty box from earlier. */}
          <div className="absolute inset-0 bg-gradient-to-br from-stone-100 via-stone-50 to-brand-50" aria-hidden />

          {/* Crossfade between slides within the same group. */}
          <AnimatePresence initial={false}>
            {(slide.imageUrl || slide.mobileImageUrl) && (
              <motion.div
                key={slide.id}
                initial={{ opacity: 0, scale: 1.04 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0 }}
                transition={{ opacity: { duration: 0.7 }, scale: { duration: 6, ease: 'easeOut' } }}
                className="absolute inset-0 bg-cover bg-center"
                style={{ backgroundImage: `url(${slide.mobileImageUrl || slide.imageUrl})` }}
                aria-hidden
              />
            )}
          </AnimatePresence>
          {/* Symmetric warm wash — keeps centered copy legible without pulling
              focal weight to one side. Softer than a hard black overlay so the
              underlying photography keeps its richness (Claude-style). */}
          {(slide.imageUrl || slide.mobileImageUrl) && (
            <>
              <div className="absolute inset-0 bg-gradient-to-t from-stone-950/55 via-stone-950/15 to-stone-950/40" />
              <div className="absolute inset-0 bg-stone-950/10" />
            </>
          )}

          {/* Copy block — refined display type, eyebrow chip, branded CTA pill. */}
          {(() => {
            const hasImage = !!(slide.imageUrl || slide.mobileImageUrl);
            return (
              <motion.div
                key={`copy-${slide.id}`}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, ease: 'easeOut' }}
                className={`relative z-10 h-full flex flex-col items-center justify-center text-center px-6 sm:px-10 md:px-16 mx-auto max-w-2xl ${
                  hasImage ? 'text-white' : 'text-content'
                }`}
              >
                <span
                  className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] uppercase tracking-[0.18em] font-bold mb-2.5 ${
                    hasImage
                      ? 'bg-white/15 backdrop-blur-sm border border-white/20 text-white/90'
                      : 'bg-brand-50 border border-brand-200 text-brand-600'
                  }`}
                >
                  Featured
                </span>
                {slide.title && (
                  <h2
                    className={`font-display font-bold leading-[1.05] tracking-tight ${
                      hasImage ? 'drop-shadow' : ''
                    }`}
                    style={{ fontSize: 'clamp(1.4rem, 2.8vw, 2.4rem)' }}
                  >
                    {slide.title}
                  </h2>
                )}
                {slide.subtitle && (
                  <p
                    className={`mt-1.5 leading-relaxed line-clamp-2 max-w-md ${
                      hasImage ? 'text-white/85' : 'text-content-muted'
                    }`}
                    style={{ fontSize: 'clamp(0.8rem, 1vw, 0.95rem)' }}
                  >
                    {slide.subtitle}
                  </p>
                )}
                {slide.linkUrl && (
                  <span
                    className={`mt-3 inline-flex items-center gap-1.5 font-semibold text-xs px-4 py-2 rounded-full transition-all group ${
                      hasImage
                        ? 'bg-white/95 text-content hover:bg-white shadow-soft'
                        : 'bg-stone-900 text-white hover:bg-brand-500'
                    }`}
                  >
                    Shop now
                    <span className="transition-transform group-hover:translate-x-0.5">→</span>
                  </span>
                )}
              </motion.div>
            );
          })()}

          {/* Carousel controls — only when multiple slides in this group. */}
          {banners.length > 1 && (
            <>
              <button
                aria-label="Previous slide"
                onClick={(e) => { e.stopPropagation(); go(-1); }}
                className="absolute left-3 top-1/2 -translate-y-1/2 z-20 bg-surface-elevated/85 hover:bg-surface-elevated text-content rounded-full p-2 shadow-soft"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <button
                aria-label="Next slide"
                onClick={(e) => { e.stopPropagation(); go(1); }}
                className="absolute right-3 top-1/2 -translate-y-1/2 z-20 bg-surface-elevated/85 hover:bg-surface-elevated text-content rounded-full p-2 shadow-soft"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
              {/* Dots */}
              <div className="absolute bottom-3 left-1/2 -translate-x-1/2 z-20 flex items-center gap-1.5">
                {banners.map((_, i) => (
                  <button
                    key={i}
                    onClick={(e) => { e.stopPropagation(); setCurrent(i); }}
                    aria-label={`Show slide ${i + 1}`}
                    className={`rounded-full transition-all ${
                      i === current ? 'w-5 h-1.5 bg-white' : 'w-1.5 h-1.5 bg-white/55 hover:bg-white/80'
                    }`}
                  />
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    </section>
  );
};

/** Groups banners by `section` while preserving order. Banners with the same section
 *  appearing consecutively become one carousel; the same section reappearing later
 *  becomes a second carousel — admins can interleave sections deliberately via SortOrder. */
function groupBySection(banners: Banner[]): Banner[][] {
  const groups: Banner[][] = [];
  for (const b of banners) {
    const last = groups[groups.length - 1];
    if (last && last[0].section === b.section) last.push(b);
    else groups.push([b]);
  }
  return groups;
}
