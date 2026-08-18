import React from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { catalogueApi } from '../../api/catalogueApi';
import { SectionHeader } from './SectionHeader';

// Slug → high-quality lifestyle image fallback. Admin can override by uploading
// an IconUrl on the SubCategory (AdminCategoriesPage). The lookup is intentionally
// generous so unseeded categories still render a tile instead of a grey placeholder.
const SLUG_IMAGE_FALLBACKS: Record<string, string> = {
  // Apparel
  'shirts':          'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=800&q=80',
  't-shirts':        'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=800&q=80',
  'tshirts':         'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=800&q=80',
  'dresses':         'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=800&q=80',
  'jeans':           'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800&q=80',
  'denims':          'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800&q=80',
  'trousers':        'https://images.unsplash.com/photo-1473966968600-fa801b3a2dd6?w=800&q=80',
  'sarees':          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&q=80',
  'kurtas':          'https://images.unsplash.com/photo-1622519407650-3df9883f76a5?w=800&q=80',
  'jackets':         'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800&q=80',
  // Footwear
  'shoes':           'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
  'sneakers':        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
  'sandals':         'https://images.unsplash.com/photo-1603487742131-4160ec999306?w=800&q=80',
  'heels':           'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=800&q=80',
  // Accessories
  'watches':         'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
  'handbags':        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80',
  'bags':            'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80',
  'sunglasses':      'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=800&q=80',
  'belts':           'https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=800&q=80',
  'jewellery':       'https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=800&q=80',
  // Beauty
  'perfume':         'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800&q=80',
  'perfumes':        'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800&q=80',
  'fragrance':       'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800&q=80',
  'makeup':          'https://images.unsplash.com/photo-1522335789203-aaa9ab6f8a04?w=800&q=80',
  'skincare':        'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80',
  // Home
  'cookware':        'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800&q=80',
  'bedding':         'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=80',
  'furniture':       'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=80',
  // Kids
  'kids':            'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4?w=800&q=80',
  'toys':            'https://images.unsplash.com/photo-1558060370-d644479cb6f7?w=800&q=80',
};

function imageFor(slug: string): string {
  return SLUG_IMAGE_FALLBACKS[slug.toLowerCase()] ??
    `https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80`;
}

/**
 * Trending Categories tile grid — driven by SubCategories.IsFeatured (admin toggles it
 * in /admin/categories). Admin can upload an IconUrl to override the slug-based fallback.
 */
export const TrendingCategories: React.FC = () => {
  const { data: items = [], isLoading, isError } = useQuery({
    queryKey: ['featured-subcategories'],
    queryFn: () => catalogueApi.getFeaturedSubCategories(10).then((r) => r.data.data ?? []),
    staleTime: 1000 * 60 * 10,
  });

  if (isError) return null;
  // Hide the entire section when there's nothing to feature — no point
  // showing a "no trending categories yet" empty state on the buyer home.
  if (!isLoading && items.length === 0) return null;

  const skeletons = Array.from({ length: 10 });

  return (
    <section className="w-full px-4 sm:px-6 lg:px-8 py-8">
      <SectionHeader
        eyebrow="Most loved"
        title="Trending Categories"
        subtitle="What our buyers can't stop browsing right now."
        actionHref="/home/products"
      />

      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3 sm:gap-4">
        {isLoading
          ? skeletons.map((_, i) => (
              <div key={i} className="rounded-2xl bg-surface-sunken animate-pulse aspect-square" />
            ))
          : items.length === 0
            ? (
                <div className="col-span-full text-center py-8 text-sm text-content-muted">
                  No trending categories yet. Admin can feature subcategories from{' '}
                  <Link to="/admin/categories" className="text-brand-500 hover:underline">/admin/categories</Link>.
                </div>
              )
            : items.map((cat) => {
                const image = cat.iconUrl || imageFor(cat.slugUrl);
                return (
                  <Link
                    key={cat.subCategoryId}
                    to={`/home/products?subCategoryId=${cat.subCategoryId}`}
                    className="group block"
                  >
                    <div className="relative rounded-2xl overflow-hidden aspect-square bg-surface-sunken">
                      <img
                        src={image}
                        alt={cat.subCategoryName}
                        loading="lazy"
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-stone-900/30 via-transparent to-transparent" />
                    </div>
                    <p className="mt-2 text-center text-sm font-medium text-content group-hover:text-brand-500 transition-colors">
                      {cat.subCategoryName}
                    </p>
                  </Link>
                );
              })}
      </div>
    </section>
  );
};
