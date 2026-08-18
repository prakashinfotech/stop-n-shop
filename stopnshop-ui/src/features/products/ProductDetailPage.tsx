import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ChevronLeft, ChevronRight, Heart, Copy, Check,
  ChevronDown, ChevronUp, MapPin, ShoppingBag, Star, X, MessageSquare,
  Truck, RotateCcw, ShieldCheck, Tag,
} from 'lucide-react';
import { productsApi } from '../../api/productsApi';
import { cartApi } from '../../api/cartApi';
import { reviewsApi } from '../../api/reviewsApi';
import type { ReviewDto } from '../../api/reviewsApi';
import { ProductCard } from '../../components/ui/ProductCard';
import { HorizontalScroll } from '../../components/ui/HorizontalScroll';
import { useWishlist } from '../../hooks/useWishlist';
import { usePincode } from '../../hooks/usePincode';
import { useAuthContext } from '../../context/AuthContext';
import { usePreviewMode } from '../../hooks/usePreviewMode';
import { useToast } from '../../components/ui/Toast';
import { resolveChartKind, getSizeChart } from '../../constants/sizeCharts';

function AccordionSection({
  title, children, defaultOpen = false,
}: { title: string; children: React.ReactNode; defaultOpen?: boolean }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className="border-t border-outline/60 py-4">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex items-center justify-between w-full text-sm font-semibold text-content"
      >
        {title}
        {open ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
      </button>
      {open && <div className="mt-3 text-sm text-content-muted">{children}</div>}
    </div>
  );
}

export const ProductDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { isAuthenticated } = useAuthContext();
  const previewMode = usePreviewMode();
  const { isWishlisted, toggleWishlist } = useWishlist();
  const { showToast } = useToast();
  const queryClient = useQueryClient();

  const [mainImgIdx, setMainImgIdx] = useState(0);
  const [selectedSize, setSelectedSize] = useState<string | null>(null);
  const [showSizeChart, setShowSizeChart] = useState(false);
  const [selectedColor, setSelectedColor] = useState<string | null>(null);
  const [inCart, setInCart] = useState(false);
  const [copiedCode, setCopiedCode] = useState<string | null>(null);
  const [couponsExpanded, setCouponsExpanded] = useState(false);
  const addToBagBtnRef = useRef<HTMLButtonElement>(null);
  const [showStickyBar, setShowStickyBar] = useState(false);

  const { pincode, setPincode, result: pincodeResult, isLoading: pincodeLoading, checkPincode } =
    usePincodeWithInput();

  const productId = Number(id);

  const { data: product, isLoading, isError } = useQuery({
    queryKey: ['product', productId],
    queryFn: () => productsApi.getProductDetail(productId).then((r) => r.data.data),
    enabled: !!productId,
  });

  const { data: similarProducts = [] } = useQuery({
    queryKey: ['similar', productId],
    queryFn: () => productsApi.getSimilar(productId).then((r) => r.data.data),
    enabled: !!productId,
  });

  const { data: recommended = [] } = useQuery({
    queryKey: ['recommended', productId],
    queryFn: () => productsApi.getRecommended([productId]).then((r) => r.data.data),
    enabled: !!productId,
  });

  // Site-wide master offers — same payload on every product page; cache for 10 minutes.
  const { data: masterOffers } = useQuery({
    queryKey: ['offers', 'master'],
    queryFn: () => productsApi.getMasterOffers().then((r) => r.data.data),
    staleTime: 1000 * 60 * 10,
  });

  const [reviewPage, setReviewPage] = useState(1);
  const [writeReviewModal, setWriteReviewModal] = useState<{ rating: number; comment: string } | null>(null);

  const { data: reviewsData, refetch: refetchReviews } = useQuery({
    queryKey: ['reviews', productId],
    queryFn: () => reviewsApi.getProductReviews(productId, 1, 10).then((r) => r.data.data),
    enabled: !!productId,
  });

  const { data: moreReviews = [] } = useQuery({
    queryKey: ['reviews', productId, reviewPage],
    queryFn: () => reviewsApi.getProductReviews(productId, reviewPage, 10).then((r) => r.data.data.items),
    enabled: !!productId && reviewPage > 1,
  });

  const submitReviewMutation = useMutation({
    mutationFn: (data: { rating: number; comment: string }) =>
      reviewsApi.addReview(productId, data),
    onSuccess: () => {
      showToast('Review posted!');
      setWriteReviewModal(null);
      refetchReviews();
    },
    onError: (err: any) =>
      showToast(err?.response?.data?.message || 'Failed to submit review', 'error'),
  });

  const allReviewItems = reviewPage === 1
    ? (reviewsData?.items ?? [])
    : [...(reviewsData?.items ?? []), ...moreReviews];

  const addToCartMutation = useMutation({
    mutationFn: () =>
      cartApi.addToCart({
        productId,
        sizeLabel: selectedSize ?? '',
        colorName: selectedColor ?? '',
        quantity: 1,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cart'] });
      setInCart(true);
      showToast('Added to bag');
    },
    onError: () => showToast('Could not add to bag', 'error'),
  });

  useEffect(() => {
    if (!addToBagBtnRef.current) return;
    const observer = new IntersectionObserver(
      ([entry]) => setShowStickyBar(!entry.isIntersecting),
      { threshold: 0 }
    );
    observer.observe(addToBagBtnRef.current);
    return () => observer.disconnect();
  }, [product]);

  const handleAddToBag = () => {
    if (previewMode) return;          // admin preview — disabled
    if (!isAuthenticated) { navigate('/login'); return; }
    if (inCart) { navigate('/user/cart'); return; }
    if (product?.sizes.length && !selectedSize) { showToast('Please select a size', 'error'); return; }
    addToCartMutation.mutate();
  };

  const handleWishlist = async () => {
    if (previewMode) return;          // admin preview — disabled
    if (!isAuthenticated) { navigate('/login'); return; }
    await toggleWishlist(productId);
    showToast(isWishlisted(productId) ? 'Removed from wishlist' : 'Added to wishlist');
  };

  const copyCode = async (code: string) => {
    await navigator.clipboard.writeText(code);
    setCopiedCode(code);
    setTimeout(() => setCopiedCode(null), 2000);
  };

  if (isLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="grid md:grid-cols-2 gap-10">
          <div className="space-y-3">
            <div className="aspect-[3/4] bg-surface-sunken rounded-2xl animate-pulse" />
            <div className="flex gap-2">
              {[1, 2, 3, 4].map((i) => <div key={i} className="w-16 h-20 bg-surface-sunken rounded-lg animate-pulse" />)}
            </div>
          </div>
          <div className="space-y-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className={`h-${i === 1 ? 4 : i === 2 ? 8 : 4} bg-surface-sunken rounded animate-pulse ${i === 2 ? 'w-2/3' : 'w-full'}`} />
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (isError || !product) {
    return (
      <div className="text-center py-24">
        <p className="text-content-muted">Product not found.</p>
        <Link to="/products" className="mt-4 inline-block text-brand-500 hover:underline text-sm">
          ← Back to products
        </Link>
      </div>
    );
  }

  const images = product.images.slice(0, 4);

  return (
    <>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Breadcrumb */}
        <nav className="text-xs text-content-subtle mb-6 flex items-center gap-1">
          <Link to="/home" className="hover:text-content-muted">Home</Link>
          <span>/</span>
          <Link to="/home/products" className="hover:text-content-muted">Products</Link>
          <span>/</span>
          <span className="text-content line-clamp-1">{product.name}</span>
        </nav>

        <div className="grid md:grid-cols-2 gap-10">
          {/* LEFT — Image gallery */}
          <div className="flex gap-3">
            {/* Thumbnail strip */}
            <div className="hidden md:flex flex-col gap-2">
              {images.map((img, i) => (
                <button
                  key={img.id}
                  onClick={() => setMainImgIdx(i)}
                  className={`w-16 h-20 rounded-lg overflow-hidden border-2 transition-colors flex-shrink-0 ${
                    mainImgIdx === i ? 'border-content' : 'border-transparent'
                  }`}
                >
                  <img src={img.url} alt={img.altText ?? product.name} className="w-full h-full object-cover" />
                </button>
              ))}
            </div>

            {/* Main image with hover-to-zoom + click-to-lightbox */}
            <div className="relative flex-1">
              <ZoomImage
                src={images[mainImgIdx]?.url ?? product.images[0]?.url ?? ''}
                alt={product.name}
                onPrev={images.length > 1 ? () => setMainImgIdx((p) => (p - 1 + images.length) % images.length) : undefined}
                onNext={images.length > 1 ? () => setMainImgIdx((p) => (p + 1) % images.length) : undefined}
              />

              {/* Mobile thumbnails */}
              <div className="flex gap-2 mt-2 md:hidden overflow-x-auto">
                {images.map((img, i) => (
                  <button
                    key={img.id}
                    onClick={() => setMainImgIdx(i)}
                    className={`flex-shrink-0 w-14 h-18 rounded-lg overflow-hidden border-2 ${
                      mainImgIdx === i ? 'border-content' : 'border-transparent'
                    }`}
                  >
                    <img src={img.url} alt="" className="w-full h-full object-cover" />
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* RIGHT — Product info */}
          <div className="space-y-5">
            {/* Brand + Title */}
            <div>
              <Link
                to={`/home/products?search=${encodeURIComponent(product.brand)}`}
                className="text-sm font-semibold text-content-muted hover:text-brand-500 uppercase tracking-wide"
              >
                {product.brand}
              </Link>
              <h1 className="font-display text-2xl font-bold text-content mt-1 leading-snug">
                {product.name}
              </h1>

              {/* Live rating from reviews */}
              {reviewsData && reviewsData.totalCount > 0 && (
                <div className="flex items-center gap-2 mt-2">
                  <div className="flex items-center gap-0.5">
                    {[1, 2, 3, 4, 5].map((i) => (
                      <Star
                        key={i}
                        className={`w-4 h-4 ${i <= Math.round(reviewsData.averageRating) ? 'text-amber-400 fill-amber-400' : 'text-content-subtle fill-stone-200'}`}
                      />
                    ))}
                  </div>
                  <button
                    onClick={() => document.getElementById('reviews-section')?.scrollIntoView({ behavior: 'smooth' })}
                    className="text-xs text-content-muted hover:text-brand-500 hover:underline"
                  >
                    {reviewsData.averageRating.toFixed(1)} ({reviewsData.totalCount} {reviewsData.totalCount === 1 ? 'review' : 'reviews'})
                  </button>
                </div>
              )}
            </div>

            {/* Price */}
            <div className="flex items-baseline gap-3 flex-wrap">
              <span className="text-3xl font-bold text-content">
                ₹{product.sellingPrice.toLocaleString('en-IN')}
              </span>
              {product.mrp > product.sellingPrice && (
                <>
                  <span className="text-base text-content-subtle line-through">
                    ₹{product.mrp.toLocaleString('en-IN')}
                  </span>
                  <span className="bg-green-100 text-green-700 text-sm font-semibold px-2 py-0.5 rounded-full">
                    {product.discountPercent}% off
                  </span>
                </>
              )}
            </div>
            <p className="text-xs text-content-subtle">Inclusive of all taxes</p>

            {/* Size selector */}
            {product.sizes.length > 0 && (
              <div>
                <div className="flex items-center justify-between mb-2">
                  <p className="text-sm font-semibold text-content">
                    Select Size
                    {selectedSize && <span className="ml-2 font-normal text-content-muted">— {selectedSize}</span>}
                  </p>
                  {(() => {
                    const kind = resolveChartKind({
                      menuName: (product as any).menuName,
                      categoryName: (product as any).categoryName,
                      subCategoryName: (product as any).subCategoryName,
                    });
                    return kind ? (
                      <button
                        type="button"
                        onClick={() => setShowSizeChart(true)}
                        className="text-xs font-semibold text-brand-500 hover:text-brand-600 underline-offset-2 hover:underline"
                      >
                        Size Chart
                      </button>
                    ) : null;
                  })()}
                </div>
                <div className="flex flex-wrap gap-2">
                  {product.sizes.map((s) => (
                    <button
                      key={s.label}
                      disabled={!s.inStock}
                      onClick={() => setSelectedSize(s.label)}
                      className={`px-4 py-2 rounded-lg border text-sm font-medium transition-colors ${
                        !s.inStock
                          ? 'border-outline text-content-subtle line-through cursor-not-allowed'
                          : selectedSize === s.label
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

            {/* Color selector */}
            {product.colors.length > 0 && (
              <div>
                <p className="text-sm font-semibold text-content mb-2">
                  Color
                  {selectedColor && <span className="ml-2 font-normal text-content-muted">— {selectedColor}</span>}
                </p>
                <div className="flex gap-2 flex-wrap">
                  {product.colors.map((c) =>
                    c.hex ? (
                      // Swatch circle when hex code is available
                      <button
                        key={c.name}
                        title={c.name}
                        disabled={!c.inStock}
                        onClick={() => setSelectedColor(c.name)}
                        className={`w-8 h-8 rounded-full border-2 transition-all ${
                          !c.inStock ? 'opacity-30 cursor-not-allowed' :
                          selectedColor === c.name ? 'border-content scale-110' : 'border-transparent hover:border-outline-strong'
                        }`}
                        style={{ backgroundColor: c.hex }}
                      />
                    ) : (
                      // Text chip fallback when no hex code
                      <button
                        key={c.name}
                        disabled={!c.inStock}
                        onClick={() => setSelectedColor(c.name)}
                        className={`px-4 py-2 rounded-lg border text-sm font-medium transition-colors ${
                          !c.inStock
                            ? 'border-outline text-content-subtle line-through cursor-not-allowed'
                            : selectedColor === c.name
                            ? 'border-brand-500 text-brand-500 bg-brand-50'
                            : 'border-outline text-content hover:border-outline-strong'
                        }`}
                      >
                        {c.name}
                      </button>
                    )
                  )}
                </div>
              </div>
            )}

            {/* Add to Bag */}
            <div className="flex gap-3">
              <motion.button
                ref={addToBagBtnRef}
                onClick={handleAddToBag}
                disabled={addToCartMutation.isPending || previewMode}
                title={previewMode ? 'Preview mode — not available for admins' : undefined}
                whileTap={previewMode ? undefined : { scale: 0.97 }}
                className={`flex-1 flex items-center justify-center gap-2 py-3.5 rounded-xl font-semibold text-sm transition-colors ${
                  inCart && !previewMode
                    ? 'bg-green-600 hover:bg-green-700 text-white'
                    : 'bg-stone-900 hover:bg-brand-500 text-white'
                } disabled:opacity-60 ${previewMode ? 'cursor-not-allowed' : ''} relative overflow-hidden`}
              >
                <AnimatePresence mode="wait" initial={false}>
                  {addToCartMutation.isPending ? (
                    <motion.span
                      key="loading"
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -8 }}
                      className="flex items-center gap-2"
                    >
                      <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
                      </svg>
                      Adding…
                    </motion.span>
                  ) : inCart && !previewMode ? (
                    <motion.span
                      key="added"
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0 }}
                      className="flex items-center gap-2"
                    >
                      <Check className="h-4 w-4" /> GO TO BAG
                    </motion.span>
                  ) : (
                    <motion.span
                      key="add"
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -8 }}
                      className="flex items-center gap-2"
                    >
                      <ShoppingBag className="h-4 w-4" /> ADD TO BAG
                    </motion.span>
                  )}
                </AnimatePresence>
              </motion.button>
              <motion.button
                onClick={handleWishlist}
                disabled={previewMode}
                title={previewMode ? 'Preview mode — not available for admins' : undefined}
                whileTap={previewMode ? undefined : { scale: 0.9 }}
                className={`p-3.5 rounded-xl border-2 transition-colors ${
                  isWishlisted(productId) && !previewMode
                    ? 'border-brand-500 text-brand-500 bg-brand-50'
                    : 'border-outline text-content-muted hover:border-outline-strong'
                } ${previewMode ? 'opacity-50 cursor-not-allowed' : ''}`}
              >
                <Heart className={`h-5 w-5 ${isWishlisted(productId) && !previewMode ? 'fill-brand-500' : ''}`} />
              </motion.button>
            </div>

            {/* Trust strip — compact horizontal row */}
            <div className="flex items-center justify-between gap-2 px-1 py-2 text-[11px] text-content-muted">
              <span className="inline-flex items-center gap-1.5">
                <Truck className="h-3.5 w-3.5 text-brand-500" />
                <span className="font-medium text-content">Free shipping</span>
                <span className="hidden sm:inline text-content-subtle">on ₹499+</span>
              </span>
              <span className="text-outline">·</span>
              <span className="inline-flex items-center gap-1.5">
                <RotateCcw className="h-3.5 w-3.5 text-brand-500" />
                <span className="font-medium text-content">14-day returns</span>
              </span>
              <span className="text-outline">·</span>
              <span className="inline-flex items-center gap-1.5">
                <ShieldCheck className="h-3.5 w-3.5 text-brand-500" />
                <span className="font-medium text-content">Secure payment</span>
              </span>
            </div>

            {/* Offers + Coupons — unified compact strip */}
            {(() => {
              const allCoupons: Array<{
                code: string;
                label: string;
                meta?: string;
              }> = [
                ...product.offers.map((o) => ({
                  code: o.code,
                  label: o.description,
                  meta: undefined as string | undefined,
                })),
                ...(masterOffers?.coupons ?? []).map((c) => ({
                  code: c.code,
                  label: c.offerType === 1
                    ? `Flat ₹${c.discountValue} off`
                    : `${c.discountValue}% off`,
                  meta: [
                    c.minOrderValue > 0 ? `on ₹${c.minOrderValue.toLocaleString('en-IN')}+` : null,
                    c.maxDiscount ? `Max ₹${c.maxDiscount.toLocaleString('en-IN')}` : null,
                  ].filter(Boolean).join(' · '),
                })),
              ];
              if (allCoupons.length === 0) return null;

              const COLLAPSED_COUNT = 2;
              const visible = couponsExpanded ? allCoupons : allCoupons.slice(0, COLLAPSED_COUNT);
              const hiddenCount = allCoupons.length - COLLAPSED_COUNT;

              return (
                <div className="rounded-2xl border border-amber-200/70 bg-gradient-to-br from-amber-50/80 via-amber-50/40 to-transparent p-3">
                  <div className="flex items-center justify-between mb-2.5 px-1">
                    <div className="flex items-center gap-1.5">
                      <Tag className="h-3.5 w-3.5 text-amber-700" />
                      <p className="text-[11px] font-bold uppercase tracking-wider text-amber-800">
                        Available offers · {allCoupons.length}
                      </p>
                    </div>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    {visible.map((c) => (
                      <div
                        key={c.code}
                        className="bg-surface-elevated border border-amber-200/60 rounded-xl p-2.5 flex flex-col gap-1.5"
                      >
                        <p className="text-[12px] font-semibold text-content leading-snug line-clamp-2">{c.label}</p>
                        {c.meta && <p className="text-[10px] text-content-muted">{c.meta}</p>}
                        <button
                          onClick={() => copyCode(c.code)}
                          className="mt-auto inline-flex items-center justify-between gap-1.5 bg-amber-50 hover:bg-amber-100 border border-dashed border-amber-500 text-amber-800 text-[11px] font-mono font-bold px-2 py-1 rounded-md transition-colors"
                          aria-label={`Copy coupon ${c.code}`}
                        >
                          <span>{c.code}</span>
                          {copiedCode === c.code ? (
                            <Check className="h-3 w-3 text-emerald-600" />
                          ) : (
                            <Copy className="h-3 w-3 opacity-60" />
                          )}
                        </button>
                      </div>
                    ))}
                  </div>
                  {hiddenCount > 0 && (
                    <button
                      onClick={() => setCouponsExpanded((v) => !v)}
                      className="w-full mt-2.5 text-center text-[11px] font-semibold text-amber-800 hover:text-amber-900 py-1 transition-colors"
                    >
                      {couponsExpanded ? '↑ Show less' : `View ${hiddenCount} more offer${hiddenCount > 1 ? 's' : ''} →`}
                    </button>
                  )}
                </div>
              );
            })()}

            {/* Bank / payment offers — informational, denser two-column layout */}
            {masterOffers && masterOffers.bankOffers.length > 0 && (
              <AccordionSection title={`Bank Offers (${masterOffers.bankOffers.length})`}>
                <ul className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {masterOffers.bankOffers.map((b) => (
                    <li key={b.id} className="text-xs text-content bg-surface border border-outline/60 rounded-lg px-3 py-2">
                      <p className="font-semibold text-content leading-snug">{b.title}</p>
                      {(b.minSpend || b.maxDiscount) && (
                        <p className="text-[10px] text-content-muted mt-0.5">
                          {b.minSpend ? `Min ₹${b.minSpend.toLocaleString('en-IN')}` : ''}
                          {b.minSpend && b.maxDiscount ? ' · ' : ''}
                          {b.maxDiscount ? `Max ₹${b.maxDiscount.toLocaleString('en-IN')}` : ''}
                        </p>
                      )}
                      {b.termsUrl && (
                        <a href={b.termsUrl} target="_blank" rel="noreferrer" className="text-[10px] text-brand-500 hover:underline mt-0.5 inline-block">
                          T&amp;C
                        </a>
                      )}
                    </li>
                  ))}
                </ul>
              </AccordionSection>
            )}

            {/* Pincode checker */}
            <AccordionSection title="Delivery & Availability" defaultOpen>
              <div className="flex gap-2">
                <div className="relative flex-1">
                  <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                  <input
                    type="text"
                    value={pincode}
                    onChange={(e) => setPincode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                    placeholder="Enter pincode"
                    maxLength={6}
                    className="w-full pl-9 pr-4 py-2 border border-outline rounded-lg text-sm focus:outline-none focus:border-brand-400"
                  />
                </div>
                <button
                  onClick={() => checkPincode(pincode)}
                  disabled={pincode.length !== 6 || pincodeLoading}
                  className="px-4 py-2 bg-stone-900 text-white text-sm font-semibold rounded-lg disabled:opacity-50 hover:bg-brand-500 transition-colors"
                >
                  {pincodeLoading ? '…' : 'CHECK'}
                </button>
              </div>
              {pincodeResult && (
                <p className={`mt-2 text-xs font-medium ${pincodeResult.isDeliverable ? 'text-green-600' : 'text-red-500'}`}>
                  {pincodeResult.isDeliverable
                    ? `✓ Delivery available in ${pincodeResult.estimatedDays} day(s) — ${pincodeResult.city}, ${pincodeResult.state}`
                    : '✗ Not deliverable to this pincode'}
                </p>
              )}
            </AccordionSection>

            {/* Product highlights — keeps full-width because the description text is wider than one column */}
            <AccordionSection title="Product Highlights" defaultOpen>
              <p className="text-content-muted text-sm leading-relaxed mb-3">{product.description}</p>
              {product.highlights && product.highlights.length > 0 && (
                <ul className="space-y-1">
                  {product.highlights.map((h, i) => (
                    <li key={i} className="flex items-start gap-2 text-xs text-content-muted">
                      <span className="text-brand-500 mt-0.5">•</span> {h}
                    </li>
                  ))}
                </ul>
              )}
            </AccordionSection>

            {/* Details cluster — two-column on lg+ for denser layout */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-x-4 -mx-0.5">
              {(product.material || product.careInstructions) && (
                <AccordionSection title="Material & Care">
                  <dl className="text-xs text-content-muted leading-relaxed space-y-1.5">
                    {product.material && (
                      <div className="flex gap-2">
                        <dt className="font-semibold text-content min-w-[80px]">Material</dt>
                        <dd>{product.material}</dd>
                      </div>
                    )}
                    {product.careInstructions && (
                      <div className="flex gap-2">
                        <dt className="font-semibold text-content min-w-[80px]">Care</dt>
                        <dd>{product.careInstructions}</dd>
                      </div>
                    )}
                  </dl>
                </AccordionSection>
              )}

              {product.fitType && (
                <AccordionSection title="Size & Fit">
                  <p className="text-xs text-content-muted leading-relaxed">{product.fitType}</p>
                </AccordionSection>
              )}

              {product.deliveryInfo && (
                <AccordionSection title="Delivery Options">
                  <p className="text-xs text-content-muted leading-relaxed">{product.deliveryInfo}</p>
                </AccordionSection>
              )}

              <AccordionSection title="Exchange & Returns">
                <p className="text-xs text-content-muted leading-relaxed">
                  {product.returnPolicyDays
                    ? `Easy ${product.returnPolicyDays}-day returns. Items must be in original condition with tags intact.`
                    : 'Easy 30-day returns. Exchange available within 7 days of delivery. Items must be in original condition with tags intact.'}
                </p>
              </AccordionSection>
            </div>

            {/* Specifications — full width since it's a key/value table */}
            {product.specifications && product.specifications.length > 0 && (
              <AccordionSection title="Specifications">
                <dl className="text-xs text-content-muted leading-relaxed grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-1.5">
                  {product.specifications.map((s, i) => (
                    <div key={i} className="flex gap-2">
                      <dt className="font-semibold text-content min-w-[120px]">{s.key}</dt>
                      <dd>{s.value}</dd>
                    </div>
                  ))}
                  {product.countryOfOrigin && (
                    <div className="flex gap-2">
                      <dt className="font-semibold text-content min-w-[120px]">Country of Origin</dt>
                      <dd>{product.countryOfOrigin}</dd>
                    </div>
                  )}
                  {product.warrantyInfo && (
                    <div className="flex gap-2">
                      <dt className="font-semibold text-content min-w-[120px]">Warranty</dt>
                      <dd>{product.warrantyInfo}</dd>
                    </div>
                  )}
                </dl>
              </AccordionSection>
            )}

            {/* Seller Information */}
            {product.seller && (
              <AccordionSection title="Seller Information">
                <p className="text-xs font-semibold text-content">{product.seller.name}</p>
                {product.seller.description && (
                  <p className="text-xs text-content-muted mt-1 leading-relaxed">{product.seller.description}</p>
                )}
              </AccordionSection>
            )}

            {/* About brand */}
            {product.aboutBrand && (
              <AccordionSection title={`About ${product.brand}`}>
                <p className="text-xs text-content-muted leading-relaxed">{product.aboutBrand}</p>
              </AccordionSection>
            )}
          </div>
        </div>

        {/* Similar products */}
        {similarProducts.length > 0 && (
          <section className="mt-16">
            <h2 className="font-display text-2xl font-bold text-content mb-6">Similar Products</h2>
            <HorizontalScroll>
              {similarProducts.map((p) => (
                <div key={p.id} className="flex-shrink-0 w-44 sm:w-52">
                  <ProductCard product={p} />
                </div>
              ))}
            </HorizontalScroll>
          </section>
        )}

        {/* Recommended */}
        {recommended.length > 0 && (
          <section className="mt-12">
            <h2 className="font-display text-2xl font-bold text-content mb-6">Users also bought</h2>
            <HorizontalScroll>
              {recommended.map((p) => (
                <div key={p.id} className="flex-shrink-0 w-44 sm:w-52">
                  <ProductCard product={p} />
                </div>
              ))}
            </HorizontalScroll>
          </section>
        )}

        {/* ── Customer Reviews Section ── */}
        <section id="reviews-section" className="mt-16 pb-8">
          <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
            <div>
              <h2 className="font-display text-2xl font-bold text-content">Customer Reviews</h2>
              {reviewsData && reviewsData.totalCount > 0 && (
                <div className="flex items-center gap-2 mt-1">
                  <div className="flex items-center gap-0.5">
                    {[1, 2, 3, 4, 5].map((i) => (
                      <Star key={i} className={`w-5 h-5 ${i <= Math.round(reviewsData.averageRating) ? 'text-amber-400 fill-amber-400' : 'text-content-subtle fill-stone-200'}`} />
                    ))}
                  </div>
                  <span className="text-sm font-semibold text-content">{reviewsData.averageRating.toFixed(1)}</span>
                  <span className="text-sm text-content-subtle">({reviewsData.totalCount} {reviewsData.totalCount === 1 ? 'review' : 'reviews'})</span>
                </div>
              )}
            </div>
            {isAuthenticated && (
              <button
                onClick={() => setWriteReviewModal({ rating: 5, comment: '' })}
                className="flex items-center gap-2 px-4 py-2 bg-stone-900 hover:bg-brand-500 text-white text-sm font-semibold rounded-xl transition-colors"
              >
                <MessageSquare className="h-4 w-4" /> Write a Review
              </button>
            )}
          </div>

          {(!reviewsData || reviewsData.totalCount === 0) ? (
            <div className="text-center py-12 border border-dashed border-outline rounded-2xl">
              <Star className="h-8 w-8 text-content-subtle mx-auto mb-3" />
              <p className="text-sm text-content-subtle">No reviews yet. Be the first to review this product!</p>
              {isAuthenticated && (
                <button
                  onClick={() => setWriteReviewModal({ rating: 5, comment: '' })}
                  className="mt-4 text-sm text-brand-500 font-semibold hover:underline"
                >
                  Write a Review
                </button>
              )}
            </div>
          ) : (
            <div className="space-y-4">
              {allReviewItems.map((review: ReviewDto) => (
                <div key={review.reviewId} className="bg-surface-elevated border border-outline/60 rounded-2xl p-5">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 bg-surface-sunken rounded-full flex items-center justify-center text-sm font-bold text-content-muted flex-shrink-0">
                        {review.reviewerName.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-content">{review.reviewerName}</p>
                        <p className="text-xs text-content-subtle">
                          {new Date(review.createdAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-0.5 flex-shrink-0">
                      {[1, 2, 3, 4, 5].map((i) => (
                        <Star key={i} className={`w-3.5 h-3.5 ${i <= review.rating ? 'text-amber-400 fill-amber-400' : 'text-content-subtle fill-stone-200'}`} />
                      ))}
                    </div>
                  </div>
                  {review.title && (
                    <p className="mt-3 text-sm font-semibold text-content">{review.title}</p>
                  )}
                  {review.body && (
                    <p className="mt-1.5 text-sm text-content-muted leading-relaxed">{review.body}</p>
                  )}
                  {review.helpfulCount > 0 && (
                    <p className="mt-3 text-xs text-content-subtle">{review.helpfulCount} people found this helpful</p>
                  )}
                </div>
              ))}

              {reviewsData.totalCount > allReviewItems.length && (
                <div className="text-center pt-2">
                  <button
                    onClick={() => setReviewPage((p) => p + 1)}
                    className="text-sm text-brand-500 font-semibold hover:underline"
                  >
                    Load more reviews
                  </button>
                </div>
              )}
            </div>
          )}
        </section>
      </div>

      {/* Size Chart Modal */}
      <AnimatePresence>
        {showSizeChart && (() => {
          const kind = resolveChartKind({
            menuName: null,
            categoryName: product.categoryName,
            subCategoryName: product.subCategoryName,
          });
          if (!kind) return null;
          const chart = getSizeChart(kind);
          return (
            <>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                onClick={() => setShowSizeChart(false)}
                className="fixed inset-0 z-[80] bg-black/40 backdrop-blur-sm"
              />
              <motion.div
                initial={{ opacity: 0, scale: 0.95, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: 20 }}
                className="fixed inset-x-4 top-1/2 -translate-y-1/2 z-[90] max-w-2xl mx-auto bg-surface-elevated rounded-2xl shadow-2xl overflow-hidden"
              >
                <div className="flex items-center justify-between px-6 py-4 border-b border-outline/60">
                  <h3 className="font-display font-bold text-content">{chart.title}</h3>
                  <button
                    onClick={() => setShowSizeChart(false)}
                    className="p-1 text-content-subtle hover:text-content-muted"
                    aria-label="Close size chart"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>
                <div className="p-6 overflow-x-auto">
                  <table className="w-full text-left text-sm">
                    <thead>
                      <tr className="border-b border-outline/60">
                        <th className="py-2 pr-4 font-semibold text-content">Size</th>
                        {chart.columns.map((c) => (
                          <th key={c} className="py-2 pr-4 font-semibold text-content">
                            {c}{chart.unit ? ` (${chart.unit})` : ''}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {chart.rows.map((row) => (
                        <tr
                          key={row.label}
                          className={`border-b border-outline/60 ${
                            selectedSize === row.label ? 'bg-brand-50 font-semibold text-brand-600' : 'text-content'
                          }`}
                        >
                          <td className="py-2 pr-4">{row.label}</td>
                          {chart.columns.map((c) => (
                            <td key={c} className="py-2 pr-4">{row.measurements[c] ?? '—'}</td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {chart.note && (
                    <p className="text-xs text-content-muted mt-4">{chart.note}</p>
                  )}
                </div>
              </motion.div>
            </>
          );
        })()}
      </AnimatePresence>

      {/* Write Review Modal */}
      <AnimatePresence>
        {writeReviewModal && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setWriteReviewModal(null)}
              className="fixed inset-0 z-[80] bg-black/40 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="fixed inset-x-4 top-1/2 -translate-y-1/2 z-[90] max-w-md mx-auto bg-surface-elevated rounded-2xl shadow-2xl overflow-hidden"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-outline/60">
                <h3 className="font-display font-bold text-content">Write a Review</h3>
                <button onClick={() => setWriteReviewModal(null)} className="p-1 text-content-subtle hover:text-content-muted">
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="p-6 space-y-5">
                <div>
                  <label className="block text-xs font-semibold text-content-muted mb-2">Rating</label>
                  <div className="flex gap-1">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        onClick={() => setWriteReviewModal((m) => m ? { ...m, rating: star } : m)}
                        className="transition-transform hover:scale-110"
                      >
                        <Star className={`h-7 w-7 transition-colors ${star <= writeReviewModal.rating ? 'text-amber-400 fill-amber-400' : 'text-content-subtle fill-stone-200'}`} />
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-content-muted mb-2">Your Review</label>
                  <textarea
                    value={writeReviewModal.comment}
                    onChange={(e) => setWriteReviewModal((m) => m ? { ...m, comment: e.target.value } : m)}
                    rows={4}
                    placeholder="Share your experience with this product…"
                    className="w-full border border-outline rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-brand-400 resize-none"
                  />
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={() => setWriteReviewModal(null)}
                    className="flex-1 py-2.5 border border-outline rounded-xl text-sm font-semibold text-content hover:bg-surface transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => submitReviewMutation.mutate({ rating: writeReviewModal.rating, comment: writeReviewModal.comment })}
                    disabled={!writeReviewModal.comment.trim() || submitReviewMutation.isPending}
                    className="flex-1 py-2.5 bg-brand-500 text-white rounded-xl text-sm font-semibold hover:bg-brand-600 transition-colors disabled:opacity-60"
                  >
                    {submitReviewMutation.isPending ? 'Submitting…' : 'Submit Review'}
                  </button>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Sticky bottom bar */}
      {showStickyBar && product && (
        <div className="fixed bottom-0 left-0 right-0 z-50 bg-surface-elevated border-t border-outline shadow-lg px-4 py-3">
          <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
            <div className="flex items-center gap-3 min-w-0">
              <img
                src={product.images[0]?.url}
                alt={product.name}
                className="w-12 h-14 object-cover rounded-lg flex-shrink-0"
              />
              <div className="min-w-0">
                <p className="text-xs text-content-muted truncate">{product.brand}</p>
                <p className="text-sm font-semibold text-content line-clamp-1">{product.name}</p>
                {selectedSize && <p className="text-xs text-content-subtle">Size: {selectedSize}</p>}
              </div>
            </div>
            <div className="flex items-center gap-4 flex-shrink-0">
              <span className="font-bold text-content">₹{product.sellingPrice.toLocaleString('en-IN')}</span>
              <button
                onClick={handleAddToBag}
                disabled={addToCartMutation.isPending || previewMode}
                title={previewMode ? 'Preview mode — not available for admins' : undefined}
                className={`px-6 py-2.5 rounded-xl font-semibold text-sm transition-colors disabled:opacity-60 ${
                  inCart && !previewMode ? 'bg-green-600 text-white' : 'bg-stone-900 hover:bg-brand-500 text-white'
                } ${previewMode ? 'cursor-not-allowed' : ''}`}
              >
                {inCart && !previewMode ? 'GO TO BAG' : 'ADD TO BAG'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

function usePincodeWithInput() {
  const [pincode, setPincode] = useState('');
  const { result, isLoading, error, checkPincode: check } = usePincode();
  return { pincode, setPincode, result, isLoading, error, checkPincode: check };
}

// ── ZoomImage ────────────────────────────────────────────────────────────
// Hover-to-zoom on desktop (mouse position drives background-position);
// click anywhere on the image to open a fullscreen lightbox.
interface ZoomImageProps {
  src: string;
  alt: string;
  onPrev?: () => void;
  onNext?: () => void;
}

const ZoomImage: React.FC<ZoomImageProps> = ({ src, alt, onPrev, onNext }) => {
  const [hovering, setHovering] = useState(false);
  const [pos, setPos] = useState({ x: 50, y: 50 });
  const [lightbox, setLightbox] = useState(false);

  const handleMove = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;
    setPos({ x: Math.max(0, Math.min(100, x)), y: Math.max(0, Math.min(100, y)) });
  };

  return (
    <>
      <div
        className="aspect-[3/4] rounded-2xl overflow-hidden bg-surface relative cursor-zoom-in"
        onMouseEnter={() => setHovering(true)}
        onMouseLeave={() => setHovering(false)}
        onMouseMove={handleMove}
        onClick={() => setLightbox(true)}
        role="button"
        tabIndex={0}
        aria-label="Click to zoom"
      >
        {/* Static base image keeps layout stable while zoom layer fades in. */}
        <img
          src={src}
          alt={alt}
          className={`w-full h-full object-cover transition-opacity duration-200 ${hovering ? 'opacity-0' : 'opacity-100'}`}
          draggable={false}
        />
        {/* Zoom layer — 2× via background-size, position follows the cursor. */}
        <div
          className={`absolute inset-0 transition-opacity duration-200 ${hovering ? 'opacity-100' : 'opacity-0'}`}
          style={{
            backgroundImage: `url(${src})`,
            backgroundSize: '200%',
            backgroundPosition: `${pos.x}% ${pos.y}%`,
            backgroundRepeat: 'no-repeat',
          }}
          aria-hidden
        />

        {/* Subtle "zoom" badge corner-hint, only when not hovering. */}
        {!hovering && (
          <div className="absolute bottom-3 right-3 bg-surface-elevated/90 border border-outline/60 text-content-muted text-[10px] uppercase tracking-wider px-2 py-1 rounded-full font-medium pointer-events-none">
            Hover to zoom
          </div>
        )}

        {onPrev && (
          <button
            onClick={(e) => { e.stopPropagation(); onPrev(); }}
            className="absolute left-2 top-1/2 -translate-y-1/2 bg-surface-elevated/90 hover:bg-surface-elevated rounded-full p-2 shadow border border-outline/60 z-10"
            aria-label="Previous image"
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
        )}
        {onNext && (
          <button
            onClick={(e) => { e.stopPropagation(); onNext(); }}
            className="absolute right-2 top-1/2 -translate-y-1/2 bg-surface-elevated/90 hover:bg-surface-elevated rounded-full p-2 shadow border border-outline/60 z-10"
            aria-label="Next image"
          >
            <ChevronRight className="h-4 w-4" />
          </button>
        )}
      </div>

      {/* Lightbox modal */}
      {lightbox && (
        <div
          className="fixed inset-0 z-[100] bg-black/90 flex items-center justify-center p-4 cursor-zoom-out"
          onClick={() => setLightbox(false)}
          role="dialog"
          aria-label="Image lightbox"
        >
          <button
            onClick={() => setLightbox(false)}
            className="absolute top-4 right-4 text-white/80 hover:text-white p-2 rounded-full bg-white/10 hover:bg-white/20"
            aria-label="Close lightbox"
          >
            <X className="h-5 w-5" />
          </button>
          <img
            src={src}
            alt={alt}
            className="max-w-full max-h-full object-contain"
            onClick={(e) => e.stopPropagation()}
            draggable={false}
          />
          {onPrev && (
            <button
              onClick={(e) => { e.stopPropagation(); onPrev(); }}
              className="absolute left-4 top-1/2 -translate-y-1/2 text-white/80 hover:text-white p-3 rounded-full bg-white/10 hover:bg-white/20"
              aria-label="Previous image"
            >
              <ChevronLeft className="h-6 w-6" />
            </button>
          )}
          {onNext && (
            <button
              onClick={(e) => { e.stopPropagation(); onNext(); }}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-white/80 hover:text-white p-3 rounded-full bg-white/10 hover:bg-white/20"
              aria-label="Next image"
            >
              <ChevronRight className="h-6 w-6" />
            </button>
          )}
        </div>
      )}
    </>
  );
};
