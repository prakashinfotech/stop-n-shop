import React from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { brandsApi } from '../../api/brandsApi';
import { HorizontalScroll } from '../../components/ui/HorizontalScroll';
import { SectionHeader } from './SectionHeader';

// Themed gradient backdrops — cycled across cards so the strip reads as a
// curated rail instead of a uniform grid. Admin can override per-brand once
// we add a BackgroundUrl column; until then this keeps the row visually rich.
const CARD_BACKDROPS = [
  'from-rose-100 to-pink-200',
  'from-amber-100 to-orange-200',
  'from-violet-100 to-purple-200',
  'from-sky-100 to-blue-200',
  'from-emerald-100 to-teal-200',
  'from-stone-100 to-stone-200',
];

const OFFER_HEADLINES = [
  'Up to 50% off',
  'Min 30% off',
  'Starting ₹999',
  'Flat 25% off',
  'New arrivals',
  'Editor’s pick',
];

/**
 * Top Brands carousel — horizontal-scroll strip of branded promotion cards.
 * Each card pairs a themed gradient backdrop with the brand logo + a punchy
 * offer headline so the home page stops being a row of identical product
 * thumbnails. Admin manages the brand list in /admin/brands (Brands table).
 */
export const TopBrands: React.FC = () => {
  const { data: brands = [], isLoading, isError } = useQuery({
    queryKey: ['brands', 'top'],
    queryFn: () => brandsApi.getAll().then((r) => r.data.data ?? []),
    staleTime: 1000 * 60 * 30,
  });

  if (isError) return null;

  const top = brands.filter((b) => b.logoUrl).slice(0, 12);
  if (!isLoading && top.length === 0) return null;

  return (
    <section className="w-full px-4 sm:px-6 lg:px-8 py-8">
      <SectionHeader
        eyebrow="Brand spotlight"
        title="Shop by Brand"
        subtitle="Handpicked labels with seasonal offers — curated for the home page."
        actionHref="/home/products"
      />

      <HorizontalScroll>
        {isLoading
          ? Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="flex-shrink-0 w-56 sm:w-64">
                <div className="aspect-[4/5] rounded-2xl bg-surface-sunken animate-pulse" />
              </div>
            ))
          : top.map((brand, i) => {
              const gradient = CARD_BACKDROPS[i % CARD_BACKDROPS.length];
              const offer = OFFER_HEADLINES[i % OFFER_HEADLINES.length];
              return (
                <Link
                  key={brand.id}
                  to={`/home/products?brandIds=${brand.id}`}
                  className="group flex-shrink-0 w-56 sm:w-64"
                >
                  <div
                    className={`relative aspect-[4/5] rounded-2xl overflow-hidden bg-gradient-to-br ${gradient} border border-outline/60 shadow-soft group-hover:shadow-soft-lg transition-shadow`}
                  >
                    {/* Offer ribbon */}
                    <div className="absolute top-3 left-3 right-3 flex items-center justify-between z-10">
                      <span className="bg-white/90 backdrop-blur-sm text-content text-[10px] font-bold uppercase tracking-wider px-2.5 py-1 rounded-full">
                        {offer}
                      </span>
                    </div>

                    {/* Brand logo centered */}
                    <div className="absolute inset-0 flex items-center justify-center p-8">
                      <img
                        src={brand.logoUrl}
                        alt={brand.name}
                        className="max-w-[70%] max-h-[55%] object-contain mix-blend-multiply group-hover:scale-105 transition-transform duration-500"
                        loading="lazy"
                      />
                    </div>

                    {/* Footer band with brand name + chevron */}
                    <div className="absolute bottom-0 left-0 right-0 bg-white/95 backdrop-blur-sm px-4 py-3 flex items-center justify-between">
                      <p className="font-display text-sm font-bold text-content truncate">
                        {brand.name}
                      </p>
                      <span className="text-brand-500 text-xs font-semibold group-hover:translate-x-0.5 transition-transform">
                        Shop →
                      </span>
                    </div>
                  </div>
                </Link>
              );
            })}
      </HorizontalScroll>
    </section>
  );
};
