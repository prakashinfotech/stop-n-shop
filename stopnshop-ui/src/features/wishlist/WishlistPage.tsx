import React from 'react';
import { Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Heart, ShoppingBag } from 'lucide-react';
import { wishlistApi } from '../../api/wishlistApi';
import { cartApi } from '../../api/cartApi';
import { useToast } from '../../components/ui/Toast';

export const WishlistPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { showToast } = useToast();

  const { data: items = [], isLoading } = useQuery({
    queryKey: ['wishlist'],
    queryFn: () => wishlistApi.getWishlist().then((r) => r.data.data),
  });

  const removeMutation = useMutation({
    mutationFn: (productId: number) => wishlistApi.toggleWishlist(productId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['wishlist'] });
      showToast('Removed from wishlist');
    },
  });

  const addToCartMutation = useMutation({
    mutationFn: (productId: number) =>
      cartApi.addToCart({ productId, sizeLabel: '', colorName: '', quantity: 1 }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cart'] });
      showToast('Added to bag!');
    },
    onError: () => showToast('Could not add to bag', 'error'),
  });

  if (isLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="font-display text-2xl font-bold text-content mb-8">My Wishlist</h1>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i}>
              <div className="aspect-[3/4] bg-surface-sunken rounded-2xl animate-pulse mb-2" />
              <div className="h-3 bg-surface-sunken rounded animate-pulse mb-1" />
              <div className="h-3 bg-surface-sunken rounded animate-pulse w-2/3" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 text-center">
        <Heart className="h-16 w-16 text-content-subtle mx-auto mb-4" />
        <h2 className="font-display text-2xl font-bold text-content mb-2">Your wishlist is empty</h2>
        <p className="text-content-muted text-sm mb-6">Save items you love and shop them anytime.</p>
        <Link
          to="/products"
          className="inline-block bg-stone-900 hover:bg-brand-500 text-white font-semibold px-8 py-3 rounded-xl text-sm transition-colors"
        >
          Continue Shopping
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <div className="flex items-center justify-between mb-8">
        <h1 className="font-display text-2xl font-bold text-content">
          My Wishlist <span className="text-content-subtle font-normal text-lg">({items.length})</span>
        </h1>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
        {items.map((item) => (
          <div key={item.id} className="group bg-surface-elevated rounded-2xl overflow-hidden border border-outline/60 hover:shadow-md transition-shadow flex flex-col">
            <Link to={`/products/${item.productId}`} className="relative block">
              <div className="aspect-[3/4] bg-surface overflow-hidden">
                <img
                  src={item.primaryImage}
                  alt={item.productName}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                  loading="lazy"
                />
              </div>
              {item.discountPercent > 0 && (
                <span className="absolute top-2 left-2 bg-brand-500 text-white text-[10px] font-bold px-2 py-0.5 rounded">
                  -{item.discountPercent}%
                </span>
              )}
              <button
                onClick={(e) => {
                  e.preventDefault();
                  removeMutation.mutate(item.productId);
                }}
                className="absolute top-2 right-2 p-1.5 rounded-full bg-surface-elevated shadow-sm hover:bg-red-50 transition-colors"
              >
                <Heart className="h-4 w-4 text-brand-500 fill-brand-500" />
              </button>
            </Link>

            <div className="p-3 flex flex-col flex-1">
              <Link to={`/products/${item.productId}`} className="flex-1">
                <p className="text-[11px] text-content-subtle uppercase tracking-wide mb-0.5">{item.brand}</p>
                <p className="text-sm font-medium text-content line-clamp-2">{item.productName}</p>
              </Link>
              <div className="mt-2 flex items-center gap-2">
                <span className="text-sm font-bold text-content">
                  ₹{item.sellingPrice.toLocaleString('en-IN')}
                </span>
                {item.mrp > item.sellingPrice && (
                  <span className="text-xs text-content-subtle line-through">
                    ₹{item.mrp.toLocaleString('en-IN')}
                  </span>
                )}
              </div>
              <button
                onClick={() => addToCartMutation.mutate(item.productId)}
                disabled={addToCartMutation.isPending}
                className="mt-3 w-full flex items-center justify-center gap-1.5 bg-stone-900 hover:bg-brand-500 text-white text-xs font-semibold py-2.5 rounded-lg transition-colors disabled:opacity-60"
              >
                <ShoppingBag className="h-3.5 w-3.5" />
                Add to Bag
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
