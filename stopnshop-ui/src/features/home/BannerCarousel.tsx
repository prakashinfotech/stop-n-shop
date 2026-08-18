import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { catalogueApi } from '../../api/catalogueApi';

interface BannerCarouselProps {
  section: number;
}

export const BannerCarousel: React.FC<BannerCarouselProps> = ({ section }) => {
  const [current, setCurrent] = useState(0);
  const [paused, setPaused] = useState(false);
  const navigate = useNavigate();

  const { data: banners } = useQuery({
    queryKey: ['banners', section],
    queryFn: () => catalogueApi.getBanners(section).then((r) => r.data.data),
  });

  const slides = banners && banners.length > 0 ? banners : [];

  useEffect(() => {
    if (paused || slides.length <= 1) return;
    const timer = setInterval(() => setCurrent((p) => (p + 1) % slides.length), 5500);
    return () => clearInterval(timer);
  }, [slides.length, paused]);

  if (slides.length === 0) return null;

  const prev = () => setCurrent((c) => (c - 1 + slides.length) % slides.length);
  const next = () => setCurrent((c) => (c + 1) % slides.length);
  const slide = slides[current];

  const handleBannerClick = () => {
    if (slide.linkUrl) {
      navigate(slide.linkUrl);
    }
  };

  return (
    <section
      className="relative overflow-hidden bg-surface-sunken"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      aria-roledescription="carousel"
    >
      <div
        className={`block relative ${slide.linkUrl ? 'cursor-pointer' : ''}`}
        style={{ minHeight: '380px' }}
        onClick={handleBannerClick}
        role={slide.linkUrl ? 'button' : undefined}
        tabIndex={slide.linkUrl ? 0 : undefined}
        onKeyDown={slide.linkUrl ? (e) => e.key === 'Enter' && handleBannerClick() : undefined}
      >
        {/* Background image — crossfade between slides. */}
        <AnimatePresence initial={false}>
          <motion.div
            key={current}
            initial={{ opacity: 0, scale: 1.04 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ opacity: { duration: 0.7 }, scale: { duration: 6, ease: 'easeOut' } }}
            className="absolute inset-0 bg-cover bg-center"
            style={{ backgroundImage: `url(${slide.mobileImageUrl || slide.imageUrl})` }}
            aria-hidden
          />
        </AnimatePresence>
        <div className="absolute inset-0 bg-gradient-to-r from-black/40 via-black/20 to-transparent" />

        {/* Content */}
        <div
          className="relative z-10 max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col justify-center"
          style={{ minHeight: '380px' }}
        >
          <motion.div
            key={current}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: 'easeOut' }}
            className="max-w-md text-white space-y-3"
          >
            {slide.title && (
              <h2 className="font-display text-2xl sm:text-3xl lg:text-4xl font-bold leading-tight drop-shadow-sm">
                {slide.title}
              </h2>
            )}
            {slide.subtitle && (
              <p className="text-content-subtle text-sm sm:text-base leading-relaxed">{slide.subtitle}</p>
            )}
          </motion.div>
        </div>

        {/* Dot indicators */}
        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 z-20 flex items-center gap-1.5">
          {slides.map((_, i) => (
            <button
              key={i}
              onClick={(e) => {
                e.stopPropagation();
                setCurrent(i);
              }}
              className={`rounded-full transition-all duration-300 ${
                i === current ? 'w-4 h-2 bg-surface-elevated' : 'w-2 h-2 bg-surface-elevated/40 hover:bg-surface-elevated/70'
              }`}
              aria-label={`Slide ${i + 1}`}
            />
          ))}
        </div>
      </div>

      {/* Navigation arrows */}
      <button
        onClick={prev}
        className="absolute left-3 top-1/2 -translate-y-1/2 bg-surface-elevated/20 hover:bg-surface-elevated/40 text-white rounded-full p-2 transition-colors z-10"
        aria-label="Previous"
      >
        <ChevronLeft className="h-5 w-5" />
      </button>
      <button
        onClick={next}
        className="absolute right-3 top-1/2 -translate-y-1/2 bg-surface-elevated/20 hover:bg-surface-elevated/40 text-white rounded-full p-2 transition-colors z-10"
        aria-label="Next"
      >
        <ChevronRight className="h-5 w-5" />
      </button>
    </section>
  );
};
