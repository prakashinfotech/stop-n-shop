import React from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { X, ShoppingBag, Plus, Minus, Trash2, ArrowRight } from 'lucide-react';
import { useCartDrawer } from './CartDrawerContext';
import { useCart } from '../../hooks/useCart';

export const CartDrawer: React.FC = () => {
  const navigate = useNavigate();
  const { isOpen, closeDrawer } = useCartDrawer();
  const { cart, cartCount, isLoading, updateCart, deleteCartItem } = useCart();

  const handleCheckout = (e: React.MouseEvent) => {
    e.stopPropagation();
    closeDrawer();
    // Small delay to ensure drawer animation completes before navigation
    setTimeout(() => {
      navigate('/cart');
    }, 100);
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={closeDrawer}
            className="fixed inset-0 z-40 bg-black/40 backdrop-blur-sm"
          />

          <motion.div
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', damping: 28, stiffness: 280 }}
            className="fixed right-0 top-0 h-full w-full max-w-md bg-surface-elevated z-50 shadow-2xl flex flex-col"
          >
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-outline/60 bg-surface-elevated">
              <div className="flex items-center gap-2.5">
                <ShoppingBag className="h-5 w-5 text-brand-500" />
                <h2 className="font-display text-lg font-bold text-content">My Bag</h2>
                <AnimatePresence mode="popLayout">
                  {cartCount > 0 && (
                    <motion.span
                      key={cartCount}
                      initial={{ scale: 0.5, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      exit={{ scale: 0.5, opacity: 0 }}
                      className="bg-brand-500 text-white text-[11px] font-black rounded-full w-5 h-5 flex items-center justify-center"
                    >
                      {cartCount > 9 ? '9+' : cartCount}
                    </motion.span>
                  )}
                </AnimatePresence>
              </div>
              <button
                onClick={closeDrawer}
                className="p-2 hover:bg-surface-sunken rounded-full transition-colors"
                aria-label="Close"
              >
                <X className="h-5 w-5 text-content-muted" />
              </button>
            </div>

            {/* Items list */}
            <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4">
              {isLoading ? (
                <>
                  {[1, 2].map((i) => (
                    <div key={i} className="flex gap-3 animate-pulse">
                      <div className="w-16 h-20 bg-surface-sunken rounded-xl flex-shrink-0" />
                      <div className="flex-1 space-y-2 pt-1">
                        <div className="h-3 bg-surface-sunken rounded w-1/3" />
                        <div className="h-4 bg-surface-sunken rounded w-3/4" />
                        <div className="h-3 bg-surface-sunken rounded w-1/2" />
                        <div className="h-5 bg-surface-sunken rounded w-1/4 mt-2" />
                      </div>
                    </div>
                  ))}
                </>
              ) : !cart || cart.items.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full py-20 text-center">
                  <motion.div
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    className="w-20 h-20 bg-brand-50 rounded-full flex items-center justify-center mb-4"
                  >
                    <ShoppingBag className="h-8 w-8 text-brand-300" />
                  </motion.div>
                  <p className="font-semibold text-content text-lg mb-1">Your bag is empty</p>
                  <p className="text-sm text-content-muted mb-6">Add items to get started</p>
                  <button
                    onClick={closeDrawer}
                    className="px-6 py-2.5 bg-brand-500 text-white rounded-full text-sm font-semibold hover:bg-brand-600 transition-colors"
                  >
                    Continue Shopping
                  </button>
                </div>
              ) : (
                <AnimatePresence initial={false}>
                  {cart.items.map((item) => (
                    <motion.div
                      key={item.id}
                      layout
                      initial={{ opacity: 0, y: -12 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, x: 60, transition: { duration: 0.2 } }}
                      className="flex gap-3 pb-4 border-b border-outline/60 last:border-0"
                    >
                      <img
                        src={item.imageUrl}
                        alt={item.productName}
                        className="w-16 h-20 object-cover rounded-xl flex-shrink-0 bg-surface"
                      />
                      <div className="flex-1 min-w-0">
                        <p className="text-xs text-content-subtle font-medium truncate">{item.brand}</p>
                        <p className="text-sm font-semibold text-content line-clamp-2 leading-snug mt-0.5">
                          {item.productName}
                        </p>
                        <div className="flex items-center gap-1.5 mt-0.5 text-xs text-content-subtle">
                          {item.sizeLabel && <span>Size: {item.sizeLabel}</span>}
                          {item.colorName && <span>· {item.colorName}</span>}
                        </div>
                        <div className="flex items-center justify-between mt-2">
                          <div>
                            <span className="font-bold text-content text-sm">
                              ₹{item.sellingPrice.toLocaleString('en-IN')}
                            </span>
                            {item.mrp > item.sellingPrice && (
                              <span className="text-xs text-content-subtle line-through ml-1.5">
                                ₹{item.mrp.toLocaleString('en-IN')}
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-1.5">
                            <div className="flex items-center border border-outline rounded-lg overflow-hidden">
                              <button
                                onClick={() =>
                                  item.quantity > 1
                                    ? updateCart({ cartId: item.id, quantity: item.quantity - 1 })
                                    : deleteCartItem(item.id)
                                }
                                className="px-2 py-1 hover:bg-surface transition-colors text-content-muted"
                              >
                                <Minus className="h-3 w-3" />
                              </button>
                              <span className="px-2 text-sm font-semibold text-content min-w-[20px] text-center">
                                {item.quantity}
                              </span>
                              <button
                                onClick={() => updateCart({ cartId: item.id, quantity: item.quantity + 1 })}
                                className="px-2 py-1 hover:bg-surface transition-colors text-content-muted"
                              >
                                <Plus className="h-3 w-3" />
                              </button>
                            </div>
                            <button
                              onClick={() => deleteCartItem(item.id)}
                              className="p-1.5 text-content-subtle hover:text-red-400 transition-colors"
                              aria-label="Remove"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              )}
            </div>

            {/* Footer */}
            <AnimatePresence>
              {cart && cart.items.length > 0 && (
                <motion.div
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  className="border-t border-outline/60 px-6 pt-4 pb-6 bg-surface-elevated space-y-3"
                >
                  <div className="space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-content-muted">MRP Total</span>
                      <span className="text-content">₹{cart.summary.totalMRP.toLocaleString('en-IN')}</span>
                    </div>
                    {cart.summary.totalDiscount > 0 && (
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-green-600 font-medium">Discount</span>
                        <span className="text-green-600 font-semibold">
                          −₹{cart.summary.totalDiscount.toLocaleString('en-IN')}
                        </span>
                      </div>
                    )}
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-content-muted">Delivery</span>
                      <span className={cart.summary.deliveryCharge === 0 ? 'text-green-600 font-medium' : 'text-content'}>
                        {cart.summary.deliveryCharge === 0 ? 'FREE' : `₹${cart.summary.deliveryCharge}`}
                      </span>
                    </div>
                    <div className="flex items-center justify-between font-bold border-t border-outline/60 pt-2">
                      <span className="text-content">Total</span>
                      <span className="text-content text-base">
                        ₹{cart.summary.finalAmount.toLocaleString('en-IN')}
                      </span>
                    </div>
                  </div>

                  <button
                    onClick={handleCheckout}
                    className="flex items-center justify-center gap-2 w-full bg-brand-500 hover:bg-brand-600 text-white py-3.5 rounded-xl font-semibold transition-colors text-sm"
                  >
                    Proceed to Checkout
                    <ArrowRight className="h-4 w-4" />
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
