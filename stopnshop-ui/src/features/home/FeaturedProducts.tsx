import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { productsApi } from '../../api/productsApi';
import { ProductCard } from '../../components/ui/ProductCard';
import { SectionHeader } from './SectionHeader';

/**
 * Editorial "Handpicked" rail — admin-curated featured products sorted by popularity.
 * Distinct from TrendingNow (behavioural view-log) — this is what the team wants
 * to spotlight, not what the audience is currently looking at.
 *
 * Renders as a responsive grid that mirrors CategoryShowcase's 6-col rhythm on
 * lg+ so every section on the home page has the same card width. 12 products
 * fill two perfect rows; if the API returns fewer, the row wraps naturally.
 */
export const FeaturedProducts: React.FC = () => {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['products', 'featured'],
    queryFn: () =>
      productsApi.getProducts({ sortBy: 'POPULAR', pageSize: 6, pageNo: 1 }).then((r) => r.data.data),
  });

  const products = data?.items ?? [];

  if (isError) return null;

  return (
    <section className="w-full px-4 sm:px-6 lg:px-8 py-6">
      <SectionHeader
        eyebrow="Editor's pick"
        title="Featured Picks"
        subtitle="Hand-curated by our buyers — proven hits that don't go out of style."
        actionHref="/home/products"
        actionLabel="Browse all"
      />

      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3 sm:gap-4">
        {isLoading
          ? Array.from({ length: 6 }).map((_, i) => (
              <div key={i}>
                <div className="aspect-[3/4] bg-surface-sunken rounded-2xl animate-pulse mb-2" />
                <div className="h-3 bg-surface-sunken rounded animate-pulse mb-1 w-3/4" />
                <div className="h-3 bg-surface-sunken rounded animate-pulse w-1/2" />
              </div>
            ))
          : products.map((product) => (
              <ProductCard key={product.id} product={product} hidePrice />
            ))}
      </div>
    </section>
  );
};
