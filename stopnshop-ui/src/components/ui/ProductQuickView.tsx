import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { X, ShoppingBag, ExternalLink, Loader2 } from 'lucide-react';
import { productsApi } from '../../api/productsApi';
import { cartApi } from '../../api/cartApi';
import { useAuthContext } from '../../context/AuthContext';
import { useToast } from './Toast';

interface Props {
  productId: number | null;
  onClose: () => void;
}

/**
 * Lightweight "quick view" lightbox — opens from a ProductCard hover button,
 * fetches the full product detail on demand (cached by React Query), and lets
 * the buyer pick a size + color and add to bag without navigating off the
 * listing page.
 */
export const ProductQuickView: React.FC<Props> = ({ productId, onClose }) => {
  const { isAuthenticated } = useAuthContext();
  const { showToast } = useToast();
  const qc = useQueryClient();

  const [size, setSize]   = useState<string | null>(null);
  const [color, setColor] = useState<string | null>(null);

  const { data: product, isLoading } = useQuery({
    queryKey: ['product', productId],
    queryFn: () => productsApi.getProductDetail(productId!).then((r) => r.data.data),
    enabled: productId != null,
  });

  // Reset selections when the product changes (open → close → reopen new card)
  React.useEffect(() => { setSize(null); setColor(null); }, [productId]);

  const addToCart = useMutation({
    mutationFn: () => cartApi.addToCart({
      productId: productId!,
      sizeLabel: size ?? '',
      colorName: color ?? '',
      quantity: 1,
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['cart'] });
      showToast('Added to bag');
      onClose();
    },
    onError: () => showToast('Could not add to bag', 'error'),
  });

  const handleAddToBag = () => {
    if (!isAuthenticated) { showToast('Please sign in to continue', 'error'); return; }
    if (product?.sizes.length && !size) { showToast('Please select a size', 'error'); return; }
    addToCart.mutate();
  };

  return (
    <AnimatePresence>
      {productId != null && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={onClose}
            className="fixed inset-0 z-[90] bg-black/45 backdrop-blur-sm"
          />
          {/* Centering wrapper — framer-motion's inline transform on the dialog
              clashes with -translate-x/y Tailwind classes, so we let flexbox handle
              the centering and let motion.div freely apply its scale/translate animation. */}
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 pointer-events-none">
          <motion.div
            initial={{ opacity: 0, scale: 0.96, y: 16 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.96, y: 16 }}
            transition={{ type: 'spring', stiffness: 280, damping: 26 }}
            role="dialog"
            aria-modal="true"
            className="pointer-events-auto w-full max-w-3xl bg-surface-elevated rounded-2xl shadow-2xl overflow-hidden flex flex-col sm:flex-row sm:items-stretch sm:h-[min(560px,80vh)] max-h-[90vh]"
          >
            {isLoading || !product ? (
              <div className="flex-1 min-h-[400px] flex items-center justify-center">
                <Loader2 className="h-6 w-6 animate-spin text-content-subtle" />
              </div>
            ) : (
              <>
                {/* Image side — explicit width AND height on sm+ so it always matches
                    the content panel exactly (no colour seam, no floating disconnect). */}
                <div className="relative flex-shrink-0 sm:w-1/2 h-72 sm:h-full bg-surface-elevated overflow-hidden">
                  <img
                    src={product.images[0]?.url}
                    alt={product.name}
                    className="absolute inset-0 w-full h-full object-cover"
                  />
                  {product.discountPercent > 0 && (
                    <span className="absolute top-3 left-3 bg-brand-500 text-white text-[11px] font-bold px-2 py-0.5 rounded shadow">
                      −{product.discountPercent}%
                    </span>
                  )}
                </div>

                {/* Hairline divider between image + content on sm+ */}
                <div className="hidden sm:block w-px bg-outline/60" aria-hidden />

                <div className="p-6 flex flex-col flex-1 overflow-y-auto min-w-0">
                  <div className="flex items-start justify-between gap-3 mb-3">
                    <div>
                      <p className="text-[11px] uppercase tracking-wider text-content-muted">{product.brand}</p>
                      <h2 className="font-display text-lg font-bold text-content leading-snug">{product.name}</h2>
                    </div>
                    <button onClick={onClose} aria-label="Close quick view" className="p-1 text-content-subtle hover:text-content-muted">
                      <X className="h-5 w-5" />
                    </button>
                  </div>

                  <div className="flex items-baseline gap-2 mb-4">
                    <span className="text-xl font-bold text-content tabular-nums">
                      ₹{product.sellingPrice.toLocaleString('en-IN')}
                    </span>
                    {product.mrp > product.sellingPrice && (
                      <>
                        <span className="text-sm text-content-subtle line-through tabular-nums">
                          ₹{product.mrp.toLocaleString('en-IN')}
                        </span>
                        <span className="text-xs font-semibold text-green-600">
                          {product.discountPercent}% off
                        </span>
                      </>
                    )}
                  </div>

                  {product.sizes.length > 0 && (
                    <div className="mb-4">
                      <p className="text-xs font-semibold text-content mb-2">
                        Size {size && <span className="font-normal text-content-muted">— {size}</span>}
                      </p>
                      <div className="flex flex-wrap gap-1.5">
                        {product.sizes.map((s) => (
                          <button
                            key={s.label}
                            disabled={!s.inStock}
                            onClick={() => setSize(s.label)}
                            className={`px-3 py-1 rounded-md border text-xs font-medium transition-colors ${
                              !s.inStock
                                ? 'border-outline text-content-subtle line-through cursor-not-allowed'
                                : size === s.label
                                ? 'border-brand-500 text-brand-500 bg-brand-50'
                                : 'border-outline text-content hover:border-outline-strong'
                            }`}
                          >
                            {s.label}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}

                  {product.colors.length > 0 && (
                    <div className="mb-4">
                      <p className="text-xs font-semibold text-content mb-2">
                        Color {color && <span className="font-normal text-content-muted">— {color}</span>}
                      </p>
                      <div className="flex flex-wrap gap-1.5">
                        {product.colors.map((c) => c.hex ? (
                          <button
                            key={c.name}
                            title={c.name}
                            disabled={!c.inStock}
                            onClick={() => setColor(c.name)}
                            className={`w-7 h-7 rounded-full border-2 transition-all ${
                              !c.inStock ? 'opacity-30 cursor-not-allowed' :
                              color === c.name ? 'border-content scale-110' : 'border-transparent hover:border-outline-strong'
                            }`}
                            style={{ backgroundColor: c.hex }}
                          />
                        ) : (
                          <button
                            key={c.name}
                            disabled={!c.inStock}
                            onClick={() => setColor(c.name)}
                            className={`px-3 py-1 rounded-md border text-xs font-medium transition-colors ${
                              !c.inStock
                                ? 'border-outline text-content-subtle line-through cursor-not-allowed'
                                : color === c.name
                                ? 'border-brand-500 text-brand-500 bg-brand-50'
                                : 'border-outline text-content hover:border-outline-strong'
                            }`}
                          >
                            {c.name}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}

                  {product.description && (
                    <p className="text-xs text-content-muted leading-relaxed line-clamp-4 mb-4">
                      {product.description}
                    </p>
                  )}

                  <div className="mt-auto flex gap-2 pt-3">
                    <button
                      onClick={handleAddToBag}
                      disabled={addToCart.isPending}
                      className="flex-1 flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white text-sm font-semibold py-2.5 rounded-xl transition-colors disabled:opacity-60"
                    >
                      {addToCart.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <ShoppingBag className="h-4 w-4" />}
                      Add to Bag
                    </button>
                    <Link
                      to={`/products/${productId}`}
                      onClick={onClose}
                      className="flex items-center justify-center gap-1.5 px-4 py-2.5 border border-outline-strong text-content text-sm font-semibold rounded-xl hover:bg-surface transition-colors"
                    >
                      Details <ExternalLink className="h-3.5 w-3.5" />
                    </Link>
                  </div>
                </div>
              </>
            )}
          </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
};
