import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Eye } from 'lucide-react';
import type { ProductListItem } from '../../types/product.types';
import { useWishlist } from '../../hooks/useWishlist';
import { useToast } from './Toast';
import { ProtectedWishlistButton } from './ProtectedWishlistButton';
import { SafeImage } from './SafeImage';
import { ProductQuickView } from './ProductQuickView';

interface ProductCardProps {
  product: ProductListItem;
  onAddToCart?: (product: ProductListItem) => void;
  /** Hide price + discount % when this card is used on a surface
   *  where price isn't relevant (e.g. editorial home rails). */
  hidePrice?: boolean;
}

export const ProductCard: React.FC<ProductCardProps> = ({ product, onAddToCart, hidePrice = false }) => {
  const { isWishlisted, toggleWishlist } = useWishlist();
  const { showToast } = useToast();
  const [quickViewOpen, setQuickViewOpen] = useState(false);

  const wishlisted = isWishlisted(product.id);

  const handleWishlistToggle = async (id: number) => {
    try {
      await toggleWishlist(id);
      showToast(wishlisted ? 'Removed from wishlist' : 'Added to wishlist');
    } catch {
      showToast('Could not update wishlist', 'error');
    }
  };

  return (
    <>
    <div className="group bg-surface-elevated rounded-2xl overflow-hidden border border-outline/60 hover:shadow-md hover:border-outline-strong transition-all flex flex-col">
      <Link to={`/products/${product.id}`} className="relative block overflow-hidden">
        <div className="aspect-[3/4] bg-surface">
          <SafeImage
            src={product.primaryImage}
            alt={product.name}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            loading="lazy"
          />
        </div>

        {!hidePrice && product.discountPercent > 0 && (
          <span className="absolute top-2 left-2 bg-brand-500 text-white text-[10px] font-bold px-2 py-0.5 rounded">
            -{product.discountPercent}%
          </span>
        )}
        {product.offerCount > 0 && (
          <span className="absolute bottom-2 left-2 bg-amber-500 text-white text-[10px] font-bold px-2 py-0.5 rounded">
            {product.offerCount} offer{product.offerCount > 1 ? 's' : ''}
          </span>
        )}

        <div className="absolute top-2 right-2 p-1.5 rounded-full bg-surface-elevated/90 hover:bg-surface-elevated shadow-sm">
          <ProtectedWishlistButton
            productId={product.id}
            isWishlisted={wishlisted}
            onToggle={handleWishlistToggle}
            size="sm"
          />
        </div>

        {/* Quick-view trigger — appears on hover, opens the lightbox without leaving the listing. */}
        <button
          type="button"
          onClick={(e) => { e.preventDefault(); setQuickViewOpen(true); }}
          aria-label={`Quick view ${product.name}`}
          className="absolute inset-x-2 bottom-2 hidden group-hover:flex items-center justify-center gap-1.5 py-1.5 rounded-lg bg-surface-elevated/95 text-content text-xs font-semibold backdrop-blur shadow-sm hover:bg-surface-elevated"
        >
          <Eye className="h-3.5 w-3.5" /> Quick view
        </button>
      </Link>

      <div className="p-3 flex flex-col flex-1">
        <Link to={`/products/${product.id}`} className="flex-1">
          <p className="text-[11px] text-content-subtle uppercase tracking-wide mb-0.5">{product.brand}</p>
          <h3 className="text-sm font-medium text-content line-clamp-2 leading-snug hover:text-brand-500 transition-colors">
            {product.name}
          </h3>
        </Link>

        {!hidePrice && (
          <div className="mt-2 flex items-center gap-2 flex-wrap">
            <span className="text-base font-bold text-content">
              ₹{product.sellingPrice.toLocaleString('en-IN')}
            </span>
            {product.mrp > product.sellingPrice && (
              <>
                <span className="text-xs text-content-subtle line-through">
                  ₹{product.mrp.toLocaleString('en-IN')}
                </span>
                <span className="text-xs font-semibold text-green-600">
                  {product.discountPercent}% off
                </span>
              </>
            )}
          </div>
        )}

        {onAddToCart && (
          <button
            onClick={(e) => { e.preventDefault(); onAddToCart(product); }}
            className="mt-3 w-full bg-stone-900 hover:bg-brand-500 text-white text-xs font-semibold py-2.5 rounded-lg transition-colors opacity-0 group-hover:opacity-100 translate-y-1 group-hover:translate-y-0 duration-200"
          >
            Add to Bag
          </button>
        )}
      </div>
    </div>
    <ProductQuickView productId={quickViewOpen ? product.id : null} onClose={() => setQuickViewOpen(false)} />
    </>
  );
};
