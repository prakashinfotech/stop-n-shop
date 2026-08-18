import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Trash2, Plus, Minus, ShoppingBag, MapPin, CreditCard, Tag, Check, X } from 'lucide-react';
import { cartApi } from '../../api/cartApi';
import { ordersApi } from '../../api/ordersApi';
import { addressesApi } from '../../api/addressesApi';
import { couponsApi } from '../../api/couponsApi';
import { paymentsApi } from '../../api/paymentsApi';
import type { CouponValidateResponse } from '../../api/couponsApi';
import { Stepper } from '../../components/ui/Stepper';
import { ProductCard } from '../../components/ui/ProductCard';
import { productsApi } from '../../api/productsApi';
import { useToast } from '../../components/ui/Toast';
import { usePreviewMode } from '../../hooks/usePreviewMode';
import type { PaymentMethod, AddAddressRequest } from '../../types/cart.types';

const STEPS = [
  { label: 'Bag' },
  { label: 'Address' },
  { label: 'Payment' },
];

const PAYMENT_METHODS: { value: PaymentMethod; label: string; icon: React.ReactNode; badge?: string }[] = [
  { value: 'RAZORPAY', label: 'Razorpay', icon: <img src="https://razorpay.com/favicon.ico" className="h-4 w-4" alt="" />, badge: 'Cards · UPI · Wallets' },
  { value: 'UPI', label: 'UPI', icon: <span className="text-lg">📱</span> },
  { value: 'CARD', label: 'Credit / Debit Card', icon: <CreditCard className="h-4 w-4" /> },
  { value: 'NETBANKING', label: 'Net Banking', icon: <span className="text-lg">🏦</span> },
  { value: 'COD', label: 'Cash on Delivery', icon: <span className="text-lg">💵</span> },
];

const BANKS = ['HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank', 'Kotak Mahindra', 'Yes Bank'];

export const CartPage: React.FC = () => {
  const [step, setStep] = useState(0);
  const [selectedAddressId, setSelectedAddressId] = useState<number | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('COD');
  const [upiId, setUpiId] = useState('');
  const [showAddressForm, setShowAddressForm] = useState(false);
  const [newAddress, setNewAddress] = useState<AddAddressRequest>({
    name: '', mobile: '', line1: '', line2: '', city: '', state: '', pincode: '', isDefault: false,
  });
  const [couponCode, setCouponCode] = useState('');
  const [appliedCoupon, setAppliedCoupon] = useState<CouponValidateResponse | null>(null);
  const [couponError, setCouponError] = useState('');
  const [couponLoading, setCouponLoading] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [processingMsg, setProcessingMsg] = useState('Processing payment…');
  const [orderSuccess, setOrderSuccess] = useState<{ orderId: number; total: number } | null>(null);

  // Active customer-facing coupons published from the admin panel.
  const { data: availableCoupons = [] } = useQuery({
    queryKey: ['coupons', 'available'],
    queryFn: () => couponsApi.available().then((r) => r.data.data ?? []),
    staleTime: 1000 * 60 * 2,
  });

  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const navigate = useNavigate();
  const previewMode = usePreviewMode();

  const { data: cart, isLoading: cartLoading } = useQuery({
    queryKey: ['cart'],
    queryFn: () => cartApi.getCart().then((r) => r.data.data),
    retry: false,
    enabled: !previewMode,          // admins don't have a buyer cart to fetch
  });

  const { data: addresses = [], isLoading: addressesLoading } = useQuery({
    queryKey: ['addresses'],
    queryFn: () => addressesApi.getAddresses().then((r) => r.data.data),
    enabled: step === 1,
    retry: false,
  });

  // Auto-select the default address when addresses load
  useEffect(() => {
    if (!addresses.length || selectedAddressId) return;
    const def = addresses.find((a) => a.isDefault) ?? addresses[0];
    setSelectedAddressId(def.id);
  }, [addresses]);

  const updateMutation = useMutation({
    mutationFn: ({ cartId, quantity }: { cartId: number; quantity: number }) =>
      cartApi.updateCart(cartId, quantity),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['cart'] }),
  });

  const deleteMutation = useMutation({
    mutationFn: (cartId: number) => cartApi.deleteCartItem(cartId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cart'] });
      showToast('Item removed from bag');
    },
  });

  const addAddressMutation = useMutation({
    mutationFn: (data: AddAddressRequest) => addressesApi.addAddress(data).then((r) => r.data.data),
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ['addresses'] });
      setSelectedAddressId(result.id);
      setShowAddressForm(false);
      showToast('Address saved');
    },
    onError: () => showToast('Could not save address', 'error'),
  });

  const placeOrderMutation = useMutation({
    mutationFn: () => {
      setIsProcessing(true);
      setProcessingMsg('Processing payment…');
      return ordersApi.placeOrder({
        addressId: selectedAddressId!,
        paymentMethod,
        couponCode: appliedCoupon?.couponCode,
      }).then((r) => r.data.data);
    },
    onSuccess: (order) => {
      setProcessingMsg('Confirming your order…');
      setTimeout(() => {
        queryClient.invalidateQueries({ queryKey: ['cart'] });
        queryClient.invalidateQueries({ queryKey: ['orders'] });
        setIsProcessing(false);
        setOrderSuccess({ orderId: order.orderId, total: finalTotal });
      }, 900);
    },
    onError: () => {
      setIsProcessing(false);
      showToast('Could not place order. Please try again.', 'error');
    },
  });

  const validateCoupon = async (overrideCode?: string) => {
    const code = (overrideCode ?? couponCode).trim();
    if (!code || !summary) return;
    if (overrideCode) setCouponCode(overrideCode);
    setCouponLoading(true);
    setCouponError('');
    try {
      const res = await couponsApi.validate(code, summary.totalMRP);
      const data = res.data.data;
      if (data.isValid) {
        setAppliedCoupon(data);
        setCouponError('');
      } else {
        setAppliedCoupon(null);
        setCouponError(data.message || 'Invalid coupon code');
      }
    } catch {
      setAppliedCoupon(null);
      setCouponError('Could not validate coupon');
    } finally {
      setCouponLoading(false);
    }
  };

  const removeCoupon = () => {
    setAppliedCoupon(null);
    setCouponCode('');
    setCouponError('');
  };

  const items = cart?.items ?? [];
  const summary = cart?.summary;
  const couponDiscount = appliedCoupon?.discountAmount ?? 0;
  const finalTotal = summary ? Math.max(0, summary.finalAmount - couponDiscount) : 0;

  const openRazorpay = async () => {
    if (!selectedAddressId) { showToast('Please select an address', 'error'); return; }
    setIsProcessing(true);
    setProcessingMsg('Opening Razorpay…');
    try {
      const res = await paymentsApi.createRazorpayOrder(finalTotal);
      const { orderId: rzpOrderId, amount, currency, keyId } = res.data.data;
      setIsProcessing(false);

      const rzp = new (window as any).Razorpay({
        key: keyId,
        amount,
        currency,
        order_id: rzpOrderId,
        name: 'StopNShop',
        description: 'Fashion & Lifestyle',
        image: '/sns-logo.svg',
        theme: { color: '#c41230' },
        handler: () => {
          // Payment succeeded in Razorpay modal — now place the order
          placeOrderMutation.mutate();
        },
        modal: {
          ondismiss: () => setIsProcessing(false),
        },
      });
      rzp.open();
    } catch {
      setIsProcessing(false);
      showToast('Could not open Razorpay. Please try again.', 'error');
    }
  };

  if (cartLoading) {
    return (
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-4">
        <div className="h-8 bg-surface-sunken rounded animate-pulse w-40 mb-6" />
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-28 bg-surface-sunken rounded-2xl animate-pulse" />
        ))}
      </div>
    );
  }

  // ── Admin preview: read-only banner + empty-state, no API calls ───────────
  if (previewMode) {
    return (
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="bg-amber-50 border border-amber-200 rounded-2xl px-4 py-3 mb-6 flex items-center justify-between gap-3">
          <p className="text-sm text-amber-800">
            <span className="font-semibold">Admin preview</span> — checkout is disabled for admin accounts.
          </p>
          <Link
            to="/admin/dashboard"
            className="text-xs font-bold tracking-widest text-amber-700 hover:text-amber-900 flex-shrink-0"
          >
            BACK TO DASHBOARD →
          </Link>
        </div>
        <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-10 text-center">
          <ShoppingBag className="h-16 w-16 text-content-subtle mx-auto mb-4" />
          <h2 className="font-display text-xl font-bold text-content mb-2">Buyer cart preview</h2>
          <p className="text-content-muted text-sm">
            You're viewing the cart as a real buyer would. Sign in as a buyer to test purchases.
          </p>
        </div>
      </div>
    );
  }

  if (items.length === 0 && step === 0) {
    return <EmptyCart />;
  }

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Stepper */}
      <div className="mb-8">
        <Stepper steps={STEPS} activeStep={step} onStepClick={(stepIndex) => setStep(stepIndex)} />
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Left panel */}
        <div className="lg:col-span-2 space-y-4">
          {/* STEP 0 — BAG */}
          {step === 0 && (
            <>
              <h2 className="font-semibold text-content">My Bag ({items.length})</h2>
              <AnimatePresence initial={false}>
                {items.map((item) => (
                  <motion.div
                    key={item.id}
                    layout
                    initial={{ opacity: 0, y: -8 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, x: 40, transition: { duration: 0.2 } }}
                    transition={{ type: 'spring', stiffness: 320, damping: 28 }}
                    className="bg-surface-elevated border border-outline/60 rounded-2xl p-4 flex gap-4 hover:border-outline-strong transition-colors"
                  >
                    <Link to={`/products/${item.productId}`}>
                      <img
                        src={item.imageUrl}
                        alt={item.productName}
                        className="w-20 h-24 object-cover rounded-xl flex-shrink-0"
                      />
                    </Link>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs text-content-subtle">{item.brand}</p>
                      <p className="text-sm font-semibold text-content line-clamp-2">{item.productName}</p>
                      <p className="text-xs text-content-subtle mt-0.5">
                        Size: {item.sizeLabel} | Color: {item.colorName}
                      </p>
                      <div className="flex items-center justify-between mt-3">
                        {/* Qty stepper — number swaps with a tiny scale pulse on change. */}
                        <div className="flex items-center border border-outline rounded-lg overflow-hidden">
                          <button
                            onClick={() => updateMutation.mutate({ cartId: item.id, quantity: item.quantity - 1 })}
                            disabled={item.quantity <= 1 || updateMutation.isPending}
                            aria-label="Decrease quantity"
                            className="px-2.5 py-1 text-content-muted hover:bg-surface disabled:opacity-40 transition-colors"
                          >
                            <Minus className="h-3.5 w-3.5" />
                          </button>
                          <div className="px-3 py-1 text-sm font-semibold text-content border-x border-outline min-w-[2.25rem] text-center overflow-hidden">
                            <AnimatePresence mode="wait" initial={false}>
                              <motion.span
                                key={item.quantity}
                                initial={{ y: 8, opacity: 0 }}
                                animate={{ y: 0, opacity: 1 }}
                                exit={{ y: -8, opacity: 0 }}
                                transition={{ duration: 0.15 }}
                                className="inline-block tabular-nums"
                              >
                                {item.quantity}
                              </motion.span>
                            </AnimatePresence>
                          </div>
                          <button
                            onClick={() => updateMutation.mutate({ cartId: item.id, quantity: item.quantity + 1 })}
                            disabled={updateMutation.isPending}
                            aria-label="Increase quantity"
                            className="px-2.5 py-1 text-content-muted hover:bg-surface disabled:opacity-40 transition-colors"
                          >
                            <Plus className="h-3.5 w-3.5" />
                          </button>
                        </div>

                        <div className="flex items-center gap-3">
                          <AnimatePresence mode="wait" initial={false}>
                            <motion.span
                              key={item.sellingPrice * item.quantity}
                              initial={{ opacity: 0, y: 4 }}
                              animate={{ opacity: 1, y: 0 }}
                              exit={{ opacity: 0, y: -4 }}
                              transition={{ duration: 0.15 }}
                              className="text-sm font-bold text-content tabular-nums"
                            >
                              ₹{(item.sellingPrice * item.quantity).toLocaleString('en-IN')}
                            </motion.span>
                          </AnimatePresence>
                          <button
                            onClick={() => deleteMutation.mutate(item.id)}
                            disabled={deleteMutation.isPending}
                            aria-label={`Remove ${item.productName}`}
                            className="text-content-subtle hover:text-red-500 transition-colors disabled:opacity-40"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </AnimatePresence>
            </>
          )}

          {/* STEP 1 — ADDRESS */}
          {step === 1 && (
            <div className="space-y-3">
              <h2 className="font-semibold text-content">Select Delivery Address</h2>

              {addressesLoading ? (
                Array.from({ length: 2 }).map((_, i) => (
                  <div key={i} className="h-20 bg-surface-sunken rounded-2xl animate-pulse" />
                ))
              ) : (
                addresses.map((addr) => {
                  const selected = selectedAddressId === addr.id;
                  return (
                    <motion.label
                      key={addr.id}
                      layout
                      whileTap={{ scale: 0.99 }}
                      className={`relative flex items-start gap-3 bg-surface-elevated border-2 rounded-2xl p-4 cursor-pointer transition-colors ${
                        selected
                          ? 'border-brand-500 ring-2 ring-brand-100 bg-brand-50/30'
                          : 'border-outline/60 hover:border-outline-strong'
                      }`}
                    >
                      <input
                        type="radio"
                        name="address"
                        value={addr.id}
                        checked={selected}
                        onChange={() => setSelectedAddressId(addr.id)}
                        className="mt-1 accent-brand-500"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <p className="text-sm font-semibold text-content">{addr.name}</p>
                          {addr.isDefault && (
                            <span className="text-[10px] bg-amber-50 text-amber-700 border border-amber-200 px-1.5 py-0.5 rounded font-semibold tracking-wide">
                              DEFAULT
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-content-muted mt-0.5">
                          {addr.line1}{addr.line2 ? `, ${addr.line2}` : ''}, {addr.city}, {addr.state} — {addr.pincode}
                        </p>
                        <p className="text-xs text-content-subtle mt-0.5">📞 {addr.mobile}</p>
                      </div>
                      {selected && (
                        <motion.span
                          layoutId="addr-check"
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          transition={{ type: 'spring', stiffness: 360, damping: 22 }}
                          className="absolute top-3 right-3 w-5 h-5 rounded-full bg-brand-500 text-white flex items-center justify-center"
                        >
                          <Check className="h-3 w-3" strokeWidth={3} />
                        </motion.span>
                      )}
                    </motion.label>
                  );
                })
              )}

              {/* Add new address toggle */}
              {!showAddressForm ? (
                <button
                  onClick={() => setShowAddressForm(true)}
                  className="flex items-center gap-2 text-sm font-semibold text-brand-500 hover:underline"
                >
                  <MapPin className="h-4 w-4" /> + Add New Address
                </button>
              ) : (
                <div className="bg-surface-elevated border border-outline rounded-2xl p-5 space-y-3">
                  <h3 className="font-semibold text-content text-sm">New Address</h3>
                  <div className="grid grid-cols-2 gap-3">
                    {[
                      { key: 'name', label: 'Full Name', colSpan: 1 },
                      { key: 'mobile', label: 'Mobile', colSpan: 1 },
                      { key: 'line1', label: 'Address Line 1', colSpan: 2 },
                      { key: 'line2', label: 'Address Line 2 (Optional)', colSpan: 2 },
                      { key: 'city', label: 'City', colSpan: 1 },
                      { key: 'state', label: 'State', colSpan: 1 },
                      { key: 'pincode', label: 'Pincode', colSpan: 1 },
                    ].map(({ key, label, colSpan }) => (
                      <div key={key} className={colSpan === 2 ? 'col-span-2' : ''}>
                        <label className="block text-xs font-medium text-content-muted mb-1">{label}</label>
                        <input
                          type="text"
                          value={String((newAddress as unknown as Record<string, unknown>)[key] ?? '')}
                          onChange={(e) => setNewAddress((prev) => ({ ...prev, [key]: e.target.value }))}
                          className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400"
                        />
                      </div>
                    ))}
                  </div>
                  <label className="flex items-center gap-2 text-sm text-content-muted cursor-pointer">
                    <input
                      type="checkbox"
                      checked={newAddress.isDefault}
                      onChange={(e) => setNewAddress((p) => ({ ...p, isDefault: e.target.checked }))}
                      className="accent-content"
                    />
                    Set as default address
                  </label>
                  <div className="flex gap-3">
                    <button
                      onClick={() => addAddressMutation.mutate(newAddress)}
                      disabled={addAddressMutation.isPending}
                      className="flex-1 bg-stone-900 hover:bg-brand-500 text-white text-sm font-semibold py-2.5 rounded-xl transition-colors disabled:opacity-60"
                    >
                      Save Address
                    </button>
                    <button
                      onClick={() => setShowAddressForm(false)}
                      className="px-4 py-2.5 border border-outline text-sm text-content-muted rounded-xl hover:bg-surface"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* STEP 2 — PAYMENT */}
          {step === 2 && (
            <div className="space-y-3">
              <h2 className="font-semibold text-content">Choose Payment Method</h2>

              {PAYMENT_METHODS.map((pm) => {
                const isDisabled = pm.value === 'CARD' || pm.value === 'NETBANKING';
                const selected = !isDisabled && paymentMethod === pm.value;
                return (
                  <div key={pm.value} className="relative group">
                    <motion.label
                      whileTap={isDisabled ? undefined : { scale: 0.99 }}
                      className={`flex items-center gap-3 bg-surface-elevated border-2 rounded-2xl p-4 transition-colors ${
                        isDisabled ? 'border-outline bg-surface cursor-not-allowed opacity-60' : 'cursor-pointer'
                      } ${
                        selected ? 'border-brand-500 ring-2 ring-brand-100 bg-brand-50/30'
                                 : !isDisabled ? 'border-outline/60 hover:border-outline-strong' : ''
                      }`}
                    >
                      <input
                        type="radio"
                        name="payment"
                        value={pm.value}
                        checked={paymentMethod === pm.value}
                        onChange={() => !isDisabled && setPaymentMethod(pm.value)}
                        disabled={isDisabled}
                        className="accent-brand-500 disabled:cursor-not-allowed"
                      />
                      <span className={`w-7 h-7 rounded-lg flex items-center justify-center bg-surface ${isDisabled ? 'opacity-50' : ''}`}>{pm.icon}</span>
                      <div className="flex-1">
                        <span className={`text-sm font-semibold ${isDisabled ? 'text-content-muted' : 'text-content'}`}>{pm.label}</span>
                        {pm.badge && !isDisabled && (
                          <span className="ml-2 text-[11px] text-content-subtle font-normal">{pm.badge}</span>
                        )}
                      </div>
                      {pm.value === 'RAZORPAY' && !isDisabled && (
                        <span className="text-[10px] font-bold text-green-600 bg-green-50 border border-green-200 px-1.5 py-0.5 rounded">LIVE</span>
                      )}
                      {selected && (
                        <motion.span
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          transition={{ type: 'spring', stiffness: 360, damping: 22 }}
                          className="w-5 h-5 rounded-full bg-brand-500 text-white flex items-center justify-center"
                        >
                          <Check className="h-3 w-3" strokeWidth={3} />
                        </motion.span>
                      )}
                    </motion.label>
                    {isDisabled && (
                      <div className="absolute bottom-full left-0 mb-2 hidden group-hover:block bg-stone-900 text-white text-xs rounded-lg px-3 py-2 whitespace-nowrap z-10">
                        Feature currently unavailable. Sorry for inconvenience.
                        <div className="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-content"></div>
                      </div>
                    )}
                  </div>
                );
              })}

              {/* UPI input */}
              {paymentMethod === 'UPI' && (
                <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-4">
                  <label className="block text-xs font-medium text-content-muted mb-1">UPI ID</label>
                  <input
                    type="text"
                    value={upiId}
                    onChange={(e) => setUpiId(e.target.value)}
                    placeholder="yourname@upi"
                    className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400"
                  />
                </div>
              )}

              {/* Net Banking bank select */}
              {paymentMethod === 'NETBANKING' && (
                <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-4">
                  <label className="block text-xs font-medium text-content-muted mb-1">Select Bank</label>
                  <select className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400">
                    <option value="">Choose bank</option>
                    {BANKS.map((b) => <option key={b} value={b}>{b}</option>)}
                  </select>
                </div>
              )}

              {/* Card inputs */}
              {paymentMethod === 'CARD' && (
                <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-4 space-y-3">
                  <div>
                    <label className="block text-xs font-medium text-content-muted mb-1">Card Number</label>
                    <input
                      type="text"
                      placeholder="1234 5678 9012 3456"
                      maxLength={19}
                      className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs font-medium text-content-muted mb-1">Expiry (MM/YY)</label>
                      <input
                        type="text"
                        placeholder="12/27"
                        maxLength={5}
                        className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-content-muted mb-1">CVV</label>
                      <input
                        type="password"
                        placeholder="•••"
                        maxLength={3}
                        className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400"
                      />
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Right — Order Summary */}
        {summary && (
          <div className="space-y-4 sticky top-24">
            {/* Coupon block (Myntra-style) */}
            <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-5">
              <p className="text-xs font-bold text-content-muted uppercase tracking-widest mb-3">Coupons</p>
              {appliedCoupon ? (
                <div className="flex items-center justify-between bg-green-50 border border-green-200 rounded-xl px-3 py-2.5">
                  <div className="flex items-center gap-2 min-w-0">
                    <Check className="h-4 w-4 text-green-600 flex-shrink-0" />
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-green-700 truncate">{appliedCoupon.couponCode}</p>
                      <p className="text-xs text-green-600">₹{appliedCoupon.discountAmount} off applied</p>
                    </div>
                  </div>
                  <button onClick={removeCoupon} className="text-content-subtle hover:text-content-muted flex-shrink-0" aria-label="Remove coupon">
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ) : (
                <>
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2 flex-1 min-w-0">
                      <Tag className="h-4 w-4 text-content-muted flex-shrink-0" />
                      <input
                        type="text"
                        value={couponCode}
                        onChange={(e) => { setCouponCode(e.target.value.toUpperCase()); setCouponError(''); }}
                        onKeyDown={(e) => e.key === 'Enter' && validateCoupon()}
                        placeholder="Apply Coupons"
                        className="flex-1 text-sm font-medium text-content placeholder:text-content-muted uppercase font-mono outline-none bg-transparent min-w-0"
                      />
                    </div>
                    <button
                      onClick={() => validateCoupon()}
                      disabled={!couponCode.trim() || couponLoading}
                      className="text-xs font-bold text-brand-500 hover:text-brand-600 tracking-widest disabled:text-content-subtle disabled:cursor-not-allowed"
                    >
                      {couponLoading ? '…' : 'APPLY'}
                    </button>
                  </div>
                  {couponError && <p className="text-xs text-red-500 mt-2">{couponError}</p>}
                  {availableCoupons.length > 0 && (
                    <div className="mt-3 pt-3 border-t border-outline/60 space-y-2">
                      <p className="text-[11px] font-bold tracking-widest text-content-muted uppercase">
                        Available coupons
                      </p>
                      <div className="space-y-1.5">
                        {availableCoupons.map((c) => {
                          const cartTotal = summary?.totalMRP ?? 0;
                          const belowMin  = cartTotal < c.minOrderValue;
                          const disabled  = c.isExhausted || belowMin || couponLoading;
                          const discountLabel = c.offerType === 1
                            ? `₹${c.discountValue} off`
                            : `${c.discountValue}% off${c.maxDiscountCap ? ` (up to ₹${c.maxDiscountCap})` : ''}`;
                          return (
                            <button
                              key={c.couponId}
                              type="button"
                              onClick={() => validateCoupon(c.couponCode)}
                              disabled={disabled}
                              className={`w-full text-left flex items-center justify-between gap-2 px-2.5 py-2 rounded-lg border transition-colors ${
                                disabled
                                  ? 'border-outline/40 bg-surface opacity-60 cursor-not-allowed'
                                  : 'border-outline hover:border-amber-300 hover:bg-amber-50/40'
                              }`}
                            >
                              <div className="min-w-0">
                                <p className="text-xs font-mono font-bold text-content tracking-wide">
                                  {c.couponCode}
                                </p>
                                <p className="text-[11px] text-content-muted truncate">
                                  {discountLabel}
                                  {c.minOrderValue > 0 && (
                                    <> · min ₹{c.minOrderValue.toLocaleString('en-IN')}</>
                                  )}
                                </p>
                                {c.isExhausted && (
                                  <p className="text-[10px] text-amber-700 mt-0.5">Already used the maximum times</p>
                                )}
                                {!c.isExhausted && belowMin && (
                                  <p className="text-[10px] text-amber-700 mt-0.5">
                                    Add ₹{(c.minOrderValue - cartTotal).toLocaleString('en-IN')} more to use
                                  </p>
                                )}
                              </div>
                              <span className="text-[11px] font-bold text-brand-500 tracking-widest flex-shrink-0">
                                APPLY
                              </span>
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  )}
                </>
              )}
            </div>

            {/* Price summary */}
            <div className="bg-surface-elevated border border-outline/60 rounded-2xl p-5">
              <h2 className="font-semibold text-content mb-4">Order Summary</h2>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between text-content-muted">
                  <span>Total MRP ({items.length} items)</span>
                  <span>₹{summary.totalMRP.toLocaleString('en-IN')}</span>
                </div>
                <div className="flex justify-between text-green-600">
                  <span>Discount</span>
                  <span>−₹{summary.totalDiscount.toLocaleString('en-IN')}</span>
                </div>
                {couponDiscount > 0 && (
                  <div className="flex justify-between text-green-600">
                    <span>Coupon ({appliedCoupon?.couponCode})</span>
                    <span>−₹{couponDiscount.toLocaleString('en-IN')}</span>
                  </div>
                )}
                <div className="flex justify-between text-content-muted">
                  <span>Delivery</span>
                  <span>
                    {summary.deliveryCharge === 0 ? (
                      <span className="text-green-600 font-medium">FREE</span>
                    ) : (
                      `₹${summary.deliveryCharge}`
                    )}
                  </span>
                </div>
                <div className="flex justify-between font-bold text-content text-base pt-3 border-t border-outline/60">
                  <span>Total Amount</span>
                  <span>₹{finalTotal.toLocaleString('en-IN')}</span>
                </div>
                {(summary.totalDiscount + couponDiscount) > 0 && (
                  <p className="text-xs text-green-600 font-medium">
                    You save ₹{(summary.totalDiscount + couponDiscount).toLocaleString('en-IN')} on this order!
                  </p>
                )}
              </div>

              {step === 0 && (
                <button
                  onClick={() => setStep(1)}
                  disabled={items.length === 0}
                  className="mt-5 w-full bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60"
                >
                  PLACE ORDER →
                </button>
              )}
              {step === 1 && (
                <button
                  onClick={() => { if (!selectedAddressId) { showToast('Please select an address', 'error'); return; } setStep(2); }}
                  className="mt-5 w-full bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors"
                >
                  CONTINUE →
                </button>
              )}
              {step === 2 && (
                <button
                  onClick={paymentMethod === 'RAZORPAY' ? openRazorpay : () => placeOrderMutation.mutate()}
                  disabled={placeOrderMutation.isPending || isProcessing}
                  className="mt-5 w-full bg-brand-500 hover:bg-brand-600 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60"
                >
                  {placeOrderMutation.isPending || isProcessing
                    ? 'Processing…'
                    : paymentMethod === 'RAZORPAY'
                    ? 'PAY WITH RAZORPAY →'
                    : 'PLACE ORDER'}
                </button>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Order Processing Overlay */}
      <AnimatePresence>
        {isProcessing && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-surface-elevated/95 backdrop-blur-sm"
          >
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
              className="w-14 h-14 border-4 border-outline/60 border-t-brand-500 rounded-full mb-6"
            />
            <AnimatePresence mode="wait">
              <motion.p
                key={processingMsg}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.3 }}
                className="text-lg font-semibold text-content"
              >
                {processingMsg}
              </motion.p>
            </AnimatePresence>
            <p className="text-sm text-content-subtle mt-2">Please don't close this page</p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Order Success Celebration */}
      <AnimatePresence>
        {orderSuccess && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-gradient-to-br from-white via-amber-50 to-brand-50 px-6 overflow-hidden"
          >
            {/* Confetti — 24 floating particles in brand red + gold */}
            {Array.from({ length: 24 }).map((_, i) => {
              const colors = ['#c41230', '#d4a017', '#10b981', '#6366f1'];
              const left = (i * 4.17) % 100;
              const delay = (i % 6) * 0.15;
              const size = 6 + (i % 3) * 3;
              return (
                <motion.div
                  key={i}
                  initial={{ y: -40, x: 0, opacity: 0, rotate: 0 }}
                  animate={{
                    y: ['-10vh', '110vh'],
                    x: [0, (i % 2 === 0 ? 30 : -30)],
                    opacity: [0, 1, 1, 0],
                    rotate: [0, 360],
                  }}
                  transition={{ duration: 2.6, delay, ease: 'easeIn' }}
                  className="absolute rounded-sm"
                  style={{
                    left: `${left}%`,
                    width: size,
                    height: size,
                    backgroundColor: colors[i % colors.length],
                  }}
                />
              );
            })}

            {/* Success card */}
            <motion.div
              initial={{ scale: 0.7, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              transition={{ type: 'spring', stiffness: 220, damping: 18 }}
              className="relative z-10 bg-surface-elevated shadow-2xl border border-outline/60 rounded-3xl px-10 py-10 text-center max-w-md w-full"
            >
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.15, type: 'spring', stiffness: 260, damping: 14 }}
                className="w-20 h-20 mx-auto mb-5 rounded-full bg-green-100 flex items-center justify-center"
              >
                <motion.div
                  initial={{ scale: 0, rotate: -45 }}
                  animate={{ scale: 1, rotate: 0 }}
                  transition={{ delay: 0.35, type: 'spring', stiffness: 300, damping: 16 }}
                >
                  <Check className="h-10 w-10 text-green-600" strokeWidth={3} />
                </motion.div>
              </motion.div>

              <h2 className="font-display text-3xl font-bold text-content mb-2">Order Placed!</h2>
              <p className="text-sm text-content-muted mb-1">Thank you for shopping with us 🎉</p>
              <p className="text-xs text-content-subtle mb-5">Order ID: #{orderSuccess.orderId}</p>

              <div className="bg-gradient-to-r from-amber-50 to-brand-50 border border-amber-200 rounded-xl px-4 py-3 mb-6">
                <p className="text-xs text-content-muted uppercase tracking-widest">
                  {paymentMethod === 'RAZORPAY' ? 'Amount paid' : 'Amount to be paid'}
                </p>
                <p className="font-display text-2xl font-bold text-content">
                  ₹{orderSuccess.total.toLocaleString('en-IN')}
                </p>
              </div>

              <div className="flex gap-3">
                <button
                  onClick={() => navigate('/home/products')}
                  className="flex-1 border border-outline hover:border-outline-strong text-content font-semibold py-3 rounded-xl text-sm transition-colors"
                >
                  Keep Shopping
                </button>
                <button
                  onClick={() => navigate(`/user/orders/${orderSuccess.orderId}`)}
                  className="flex-1 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors"
                >
                  View Order →
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

const EmptyCart: React.FC = () => {
  const { data: featured } = useQuery({
    queryKey: ['products', 'featured', 'empty-cart'],
    queryFn: () =>
      productsApi.getProducts({ sortBy: 'POPULAR', pageSize: 4, pageNo: 1 }).then((r) => r.data.data),
    staleTime: 1000 * 60 * 5,
  });

  const items = featured?.items ?? [];

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
      <div className="text-center">
        <div className="inline-flex items-center justify-center h-20 w-20 rounded-full bg-surface mb-4">
          <ShoppingBag className="h-9 w-9 text-content-subtle" />
        </div>
        <h2 className="font-display text-2xl font-bold text-content mb-2">Your bag is empty</h2>
        <p className="text-content-muted text-sm mb-6 max-w-md mx-auto">
          Looks like you haven't added anything yet. Here are some popular picks to get you started.
        </p>
        <Link
          to="/home/products"
          className="inline-block bg-stone-900 hover:bg-brand-500 text-white font-semibold px-8 py-3 rounded-xl text-sm transition-colors"
        >
          Continue Shopping
        </Link>
      </div>

      {items.length > 0 && (
        <div className="mt-14">
          <div className="flex items-end justify-between mb-5">
            <div>
              <p className="text-xs font-semibold text-brand-500 uppercase tracking-widest mb-1">
                Popular right now
              </p>
              <h3 className="font-display text-xl font-bold text-content">You might like</h3>
            </div>
            <Link to="/home/products" className="text-sm font-medium text-brand-500 hover:underline">
              View all →
            </Link>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
            {items.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
