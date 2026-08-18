import React from 'react';
import { useParams, Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { catalogueApi } from '../../api/catalogueApi';
import { productsApi } from '../../api/productsApi';
import { ProductCard } from '../../components/ui/ProductCard';
import { HorizontalScroll } from '../../components/ui/HorizontalScroll';

// Per-keyword image fallbacks. Matched against subcategory + product-type names
// (case-insensitive, longest match wins) so each tile shows a relevant photo
// instead of the same model cycled across every position.
const KEYWORD_IMAGES: Array<[RegExp, string]> = [
  [/saree/i,            'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&q=80'],
  [/kurt|kurta/i,       'https://images.unsplash.com/photo-1622519407650-3df9883f76a5?w=600&q=80'],
  [/dress/i,            'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=600&q=80'],
  [/ethnic/i,           'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&q=80'],
  [/jean|denim/i,       'https://images.unsplash.com/photo-1542272604-787c3835535d?w=600&q=80'],
  [/trouser|pant/i,     'https://images.unsplash.com/photo-1473966968600-fa801b3a2dd6?w=600&q=80'],
  [/t.?shirt|tee/i,     'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=600&q=80'],
  [/shirt/i,            'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=600&q=80'],
  [/top|blouse/i,       'https://images.unsplash.com/photo-1551489186-cf8726f514f8?w=600&q=80'],
  [/jacket|coat/i,      'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80'],
  [/sweater|cardigan/i, 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=600&q=80'],
  [/sneaker/i,          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80'],
  [/formal.*shoe/i,     'https://images.unsplash.com/photo-1614252369475-531eba835eb1?w=600&q=80'],
  [/sandal|slipper/i,   'https://images.unsplash.com/photo-1603487742131-4160ec999306?w=600&q=80'],
  [/heel/i,             'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=600&q=80'],
  [/boot/i,             'https://images.unsplash.com/photo-1520639888713-7851133b1ed0?w=600&q=80'],
  [/shoe|footwear/i,    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80'],
  [/watch/i,            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&q=80'],
  [/handbag|purse/i,    'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&q=80'],
  [/backpack/i,         'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&q=80'],
  [/bag|luggage/i,      'https://images.unsplash.com/photo-1591561954557-26941169b49e?w=600&q=80'],
  [/sunglass/i,         'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=600&q=80'],
  [/belt/i,             'https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=600&q=80'],
  [/jewell?ery|jewel/i, 'https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=600&q=80'],
  [/perfume|fragrance/i,'https://images.unsplash.com/photo-1541643600914-78b084683601?w=600&q=80'],
  [/makeup|cosmetic/i,  'https://images.unsplash.com/photo-1522335789203-aaa9ab6f8a04?w=600&q=80'],
  [/skincare|skin.*care/i,'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=600&q=80'],
  [/gym|fitness|sport/i,'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&q=80'],
  [/outdoor/i,          'https://images.unsplash.com/photo-1551632811-561732d1e306?w=600&q=80'],
  [/inner.*wear|underwear/i,'https://images.unsplash.com/photo-1582142306909-195724d33ffc?w=600&q=80'],
  [/kid|children|baby/i,'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4?w=600&q=80'],
  [/toy/i,              'https://images.unsplash.com/photo-1558060370-d644479cb6f7?w=600&q=80'],
  [/cookware|kitchen/i, 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600&q=80'],
  [/bedding|bed/i,      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80'],
  [/furniture/i,        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80'],
];

// Fallback per top-level slug if no keyword matches.
const SLUG_FALLBACK: Record<string, string> = {
  women:  'https://images.unsplash.com/photo-1485462537746-965f33f7f6a7?w=600&q=80',
  men:    'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=600&q=80',
  kids:   'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4?w=600&q=80',
  home:   'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80',
  beauty: 'https://images.unsplash.com/photo-1522335789203-aaa9ab6f8a04?w=600&q=80',
  watches:'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&q=80',
};

function pickImage(name: string, fallbackSlug: string): string {
  for (const [pat, url] of KEYWORD_IMAGES) {
    if (pat.test(name)) return url;
  }
  return SLUG_FALLBACK[fallbackSlug] ?? 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80';
}

export const CategoryPage: React.FC = () => {
  const { slug = '' } = useParams<{ slug: string }>();

  const { data: menuCategories = [] } = useQuery({
    queryKey: ['mega-menu'],
    queryFn: () => catalogueApi.getMegaMenu().then((r) => r.data.data),
    staleTime: 1000 * 60 * 10,
  });

  const category = menuCategories.find((c) => c.slug === slug);

  const { data: trendingData, isLoading: trendingLoading } = useQuery({
    queryKey: ['products', 'latest', category?.id],
    queryFn: () =>
      productsApi
        .getProducts({ menuId: category!.id, sortBy: 'LATEST', pageSize: 12, pageNo: 1 })
        .then((r) => r.data.data),
    enabled: !!category?.id,
  });

  // Build the tile list — one tile per subcategory (not flattened product types,
  // which generated duplicates and broken counts).
  const tiles = category?.subCategories ?? [];

  return (
    <main>
      {/* Category header */}
      <section className="bg-stone-900 text-white py-16 text-center">
        <h1 className="font-display text-4xl font-bold capitalize">{category?.name ?? slug}</h1>
      </section>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-12">
        {/* Shop by Type */}
        {tiles.length > 0 && (
          <section>
            <h2 className="font-display text-2xl font-bold text-content mb-6">
              Shop by Type
            </h2>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
              {tiles.map((sub) => {
                const img = pickImage(sub.name, slug);
                return (
                  <Link
                    key={sub.id}
                    to={`/home/products?menuId=${category!.id}&subCategoryId=${sub.id}`}
                    className="group rounded-xl overflow-hidden border border-outline/60 bg-surface-elevated hover:shadow-md transition-shadow text-center"
                  >
                    <div className="aspect-[4/5] overflow-hidden bg-surface-sunken">
                      <img
                        src={img}
                        alt={sub.name}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                        loading="lazy"
                        onError={(e) => {
                          (e.currentTarget as HTMLImageElement).src =
                            SLUG_FALLBACK[slug] ?? 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80';
                        }}
                      />
                    </div>
                    <p className="py-2 text-xs font-semibold text-content px-2">{sub.name}</p>
                  </Link>
                );
              })}
            </div>
          </section>
        )}

        {/* Latest products */}
        <section>
          <div className="flex items-center justify-between mb-6">
            <h2 className="font-display text-2xl font-bold text-content capitalize">
              Latest in {slug}
            </h2>
            <Link
              to={`/home/products?menuId=${category?.id ?? ''}&sortBy=newest`}
              className="text-sm font-medium text-brand-500 hover:underline"
            >
              View all →
            </Link>
          </div>

          {trendingLoading ? (
            <HorizontalScroll>
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="flex-shrink-0 w-44 sm:w-52">
                  <div className="aspect-[3/4] bg-surface-sunken rounded-2xl animate-pulse mb-2" />
                  <div className="h-3 bg-surface-sunken rounded animate-pulse mb-1 w-3/4" />
                  <div className="h-3 bg-surface-sunken rounded animate-pulse w-1/2" />
                </div>
              ))}
            </HorizontalScroll>
          ) : trendingData && trendingData.items.length > 0 ? (
            <HorizontalScroll>
              {trendingData.items.map((product) => (
                <div key={product.id} className="flex-shrink-0 w-44 sm:w-52">
                  <ProductCard product={product} />
                </div>
              ))}
            </HorizontalScroll>
          ) : (
            <p className="text-content-muted text-sm py-8 text-center">No products yet in this category.</p>
          )}
        </section>
      </div>
    </main>
  );
};
