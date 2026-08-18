import React from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowRight } from 'lucide-react';
import { catalogueApi } from '../../api/catalogueApi';
import { SectionHeader } from './SectionHeader';

// Slug → editorial lifestyle image used when a Menu/Category has no
// admin-uploaded IconUrl yet. The lookup is deliberately wide so unseeded
// menus still render a tile instead of a grey box. Admin can override once
// the Menus table gets an IconUrl field (or a dedicated CategoryHero CMS slot).
const MENU_IMAGE_FALLBACKS: Record<string, string> = {
  'men':       'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=1200&q=85&auto=format&fit=crop',
  'women':     'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=1200&q=85&auto=format&fit=crop',
  'kids':      'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=1200&q=85&auto=format&fit=crop',
  'beauty':    'https://images.unsplash.com/photo-1522335789203-aaa9ab6f8a04?w=1200&q=85&auto=format&fit=crop',
  'home':      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=1200&q=85&auto=format&fit=crop',
  'homestop':  'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=1200&q=85&auto=format&fit=crop',
  'watches':   'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=1200&q=85&auto=format&fit=crop',
  'perfumes':  'https://images.unsplash.com/photo-1541643600914-78b084683601?w=1200&q=85&auto=format&fit=crop',
  'gifts':     'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=1200&q=85&auto=format&fit=crop',
  'brands':    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=85&auto=format&fit=crop',
};

const DEFAULT_IMAGE =
  'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200&q=85&auto=format&fit=crop';

function imageFor(slug: string): string {
  return MENU_IMAGE_FALLBACKS[slug.toLowerCase()] ?? DEFAULT_IMAGE;
}

/**
 * Top-level "Shop by Category" hero strip. Pulls every active Menu from the
 * /menu endpoint (admin-managed Menus table) and renders each as a tall,
 * tappable card with a hover zoom and overlay copy. Always visible because
 * menu data is the same data powering the header nav — if there are zero
 * menus the header is broken anyway.
 */
export const CategoryShowcase: React.FC = () => {
  const { data: menus = [], isLoading } = useQuery({
    queryKey: ['mega-menu'],
    queryFn: () => catalogueApi.getMegaMenu().then((r) => r.data.data),
    staleTime: 1000 * 60 * 10,
  });

  // Cap at 6 cards so the row stays balanced on lg+ (3-col mobile, 6-col desktop).
  const cards = menus.slice(0, 6);

  return (
    <section className="w-full px-4 sm:px-6 lg:px-8 py-10">
      <SectionHeader
        eyebrow="Shop by department"
        title="Find what you're looking for"
        subtitle="Every department, curated and refreshed weekly by our editors."
        actionHref="/home/products"
      />

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4">
        {isLoading
          ? Array.from({ length: 6 }).map((_, i) => (
              <div
                key={i}
                className="rounded-2xl bg-surface-sunken animate-pulse"
                style={{ aspectRatio: '3 / 4' }}
              />
            ))
          : cards.map((menu) => (
              <Link
                key={menu.id}
                to={`/home/category/${menu.slug}`}
                className="group relative block rounded-2xl overflow-hidden shadow-soft hover:shadow-soft-lg transition-shadow"
                style={{ aspectRatio: '3 / 4' }}
              >
                <img
                  src={imageFor(menu.slug)}
                  alt={menu.name}
                  loading="lazy"
                  className="absolute inset-0 w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                />
                {/* Stronger bottom gradient — overlay copy is the focal point. */}
                <div className="absolute inset-0 bg-gradient-to-t from-stone-950/85 via-stone-950/30 to-transparent" />

                <div className="relative h-full flex flex-col justify-end p-4 text-white">
                  <h3 className="font-display text-lg sm:text-xl font-bold tracking-tight drop-shadow">
                    {menu.name}
                  </h3>
                  <span className="mt-1 inline-flex items-center gap-1 text-xs font-semibold text-white/85 group-hover:text-white transition-colors">
                    Shop now
                    <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-1" />
                  </span>
                </div>
              </Link>
            ))}
      </div>
    </section>
  );
};
