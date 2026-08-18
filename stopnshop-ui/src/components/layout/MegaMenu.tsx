import React, { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { ChevronRight, Sparkles } from 'lucide-react';
import type { MegaMenuCategory } from '../../types/catalogue.types';

interface MegaMenuProps {
  categories: MegaMenuCategory[];
  activeCategoryId: number | null;
  onClose: () => void;
}

/**
 * Hover-revealed mega-menu. Composition:
 *   • Up to N subcategory columns (each = one DB Category, e.g. "Clothing").
 *   • Inside each column: link list of product-types with the category icon at
 *     the top — falls back to a tinted initial badge when there's no image.
 *   • Footer bar with a "View all in {Menu}" deep-link.
 *
 * Hover-delay (150 ms close timeout) lives in Header.tsx so this component
 * stays declarative — it just renders when activeCategoryId matches.
 */
export const MegaMenu: React.FC<MegaMenuProps> = ({ categories, activeCategoryId, onClose }) => {
  const activeCategory = categories.find((c) => c.id === activeCategoryId);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [onClose]);

  if (!activeCategory) return null;

  // Cycled tint for the icon-fallback badge.
  const tints = [
    'bg-rose-50 text-rose-700',
    'bg-amber-50 text-amber-700',
    'bg-emerald-50 text-emerald-700',
    'bg-sky-50 text-sky-700',
    'bg-violet-50 text-violet-700',
    'bg-stone-100 text-stone-700',
  ];

  return (
    <div
      className="absolute left-0 right-0 top-full z-40 bg-surface-elevated border-t border-outline/60 shadow-2xl"
      onMouseLeave={onClose}
    >
      <div className="max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-x-8 gap-y-6">
          {activeCategory.subCategories.map((sub, i) => (
            <div key={sub.id} className="min-w-0">
              {/* Section heading row */}
              <div className="flex items-center gap-2 mb-3 pb-2 border-b border-outline/50">
                {sub.iconUrl ? (
                  <img
                    src={sub.iconUrl}
                    alt=""
                    className="w-7 h-7 rounded-lg object-cover flex-shrink-0"
                    onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                  />
                ) : (
                  <span
                    aria-hidden
                    className={`w-7 h-7 rounded-lg flex items-center justify-center text-[11px] font-bold flex-shrink-0 ${tints[i % tints.length]}`}
                  >
                    {sub.name[0]?.toUpperCase() ?? '·'}
                  </span>
                )}
                <Link
                  to={`/home/products?menuId=${activeCategory.id}&categoryId=${sub.id}`}
                  onClick={onClose}
                  className="text-xs font-bold uppercase tracking-[0.14em] text-content hover:text-brand-600 transition-colors truncate"
                >
                  {sub.name}
                </Link>
              </div>

              {/* Product-type links */}
              <ul className="space-y-1.5">
                {sub.productTypes.slice(0, 7).map((pt) => (
                  <li key={pt.id}>
                    <Link
                      to={`/home/products?menuId=${activeCategory.id}&categoryId=${sub.id}&subCategoryId=${pt.id}`}
                      onClick={onClose}
                      className="group text-sm text-content-muted hover:text-brand-600 transition-colors inline-flex items-center gap-1"
                    >
                      {pt.name}
                      <ChevronRight className="h-3 w-3 opacity-0 -ml-0.5 group-hover:opacity-60 group-hover:ml-0 transition-all" />
                    </Link>
                  </li>
                ))}
                {sub.productTypes.length > 7 && (
                  <li>
                    <Link
                      to={`/home/products?menuId=${activeCategory.id}&categoryId=${sub.id}`}
                      onClick={onClose}
                      className="text-xs font-semibold text-brand-600 hover:text-brand-700 transition-colors"
                    >
                      +{sub.productTypes.length - 7} more →
                    </Link>
                  </li>
                )}
              </ul>
            </div>
          ))}
        </div>

        {/* Footer bar — "View all in {Menu}" deep-link */}
        <div className="mt-7 pt-4 border-t border-outline/60 flex items-center justify-between">
          <p className="inline-flex items-center gap-1.5 text-[11px] uppercase tracking-[0.18em] text-content-subtle">
            <Sparkles className="h-3 w-3 text-amber-500" />
            All in {activeCategory.name}
          </p>
          <Link
            to={`/home/products?menuId=${activeCategory.id}`}
            onClick={onClose}
            className="group inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-stone-900 hover:bg-brand-500 text-white text-xs font-semibold transition-colors"
          >
            View all in {activeCategory.name}
            <ChevronRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" />
          </Link>
        </div>
      </div>
    </div>
  );
};
