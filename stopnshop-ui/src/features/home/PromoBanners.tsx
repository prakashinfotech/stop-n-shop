import React from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { catalogueApi } from '../../api/catalogueApi';
import type { Banner } from '../../types/catalogue.types';

const FALLBACK_BANNERS: Banner[] = [
  {
    id: 1,
    imageUrl: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=700&q=80',
    title: "Up to 50% Off",
    subtitle: "Women's Fashion",
    linkUrl: '/home/category/clothing',
    section: 1,
    sortOrder: 0,
  },
  {
    id: 2,
    imageUrl: 'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=700&q=80',
    title: 'New Season Styles',
    subtitle: "Men's Edit",
    linkUrl: '/home/category/footwear',
    section: 1,
    sortOrder: 1,
  },
];

export const PromoBanners: React.FC = () => {
  const { data: apiBanners } = useQuery({
    queryKey: ['banners', 1],
    queryFn: () => catalogueApi.getBanners(1).then((r) => r.data.data),
  });

  const banners = apiBanners && apiBanners.length >= 2
    ? apiBanners.slice(0, 2)
    : FALLBACK_BANNERS;

  return (
    <>
      <section className="max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid md:grid-cols-2 gap-4">
          {banners.map((banner) => (
            <Link
              key={banner.id}
              to={banner.linkUrl ?? '/home/products'}
              className="group relative rounded-2xl overflow-hidden h-56 sm:h-64 block"
            >
              <img
                src={banner.imageUrl}
                alt={banner.title ?? 'Promo'}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                loading="lazy"
              />
              <div className="absolute inset-0 bg-gradient-to-r from-black/60 to-transparent" />
              <div className="absolute inset-0 flex flex-col justify-center px-8">
                {banner.subtitle && (
                  <p className="text-white/80 text-xs font-semibold uppercase tracking-widest mb-1">
                    {banner.subtitle}
                  </p>
                )}
                {banner.title && (
                  <h3 className="font-display text-2xl sm:text-3xl font-bold text-white mb-3">
                    {banner.title}
                  </h3>
                )}
                <span className="inline-flex items-center text-white border border-white/60 hover:bg-surface-elevated hover:text-content text-sm font-medium px-4 py-1.5 rounded-full transition-colors w-fit">
                  Shop Now →
                </span>
              </div>
            </Link>
          ))}
        </div>
      </section>
    </>
  );
};
