import React, { useState, useCallback, useMemo, useEffect } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { SlidersHorizontal, X, ChevronDown, ChevronUp, SearchX } from 'lucide-react';
import { productsApi } from '../../api/productsApi';
import { catalogueApi } from '../../api/catalogueApi';
import { brandsApi } from '../../api/brandsApi';
import { ProductCard } from '../../components/ui/ProductCard';
import type { ProductQueryParams } from '../../types/product.types';

const SORT_OPTIONS = [
  { label: 'Latest', value: 'LATEST' },
  { label: 'Price: Low to High', value: 'PRICE_ASC' },
  { label: 'Price: High to Low', value: 'PRICE_DESC' },
] as const;

// Per-scale size lists. The filter UI picks the right list based on the
// currently selected subcategory's NAME (heuristic — robust enough without
// a new DB column).
const APPAREL_SIZES   = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'] as const;
const PANT_WAIST      = ['28', '30', '32', '34', '36', '38', '40', '42'] as const;
const SHOE_SIZES_UK   = ['5', '6', '7', '8', '9', '10', '11', '12'] as const;
const KIDS_AGE        = ['0-1y', '1-2y', '2-3y', '3-4y', '5-6y', '7-8y', '9-10y', '11-12y'] as const;
const FREE_SIZE_ONLY  = ['Free Size'] as const;
// Catch-all when no subcategory is picked yet — show everything.
const ALL_SIZES = [
  ...APPAREL_SIZES,
  ...PANT_WAIST,
  ...SHOE_SIZES_UK,
  'Free Size',
] as const;

/** Heuristic mapping subcategory name → which size list to show. */
function sizesForSubCategoryName(name: string | undefined | null): readonly string[] {
  if (!name) return ALL_SIZES;
  const lc = name.toLowerCase();
  if (/shoe|sneaker|sandal|heel|boot|loafer|footwear|formal.shoe/.test(lc)) return SHOE_SIZES_UK;
  if (/trouser|pant|jean|jegging|legging|chino|short|cargo/.test(lc))       return PANT_WAIST;
  if (/kid|infant|baby|toddler/.test(lc))                                    return KIDS_AGE;
  if (/saree|dupatta|stole|scarf|tie|wallet|belt|watch|jewell?ery|bag|perfume|fragrance|cosmetic|makeup|skincare/.test(lc)) return FREE_SIZE_ONLY;
  if (/shirt|tee|tshirt|top|blouse|dress|kurta|tunic|jacket|sweater|coat|hoodie|sweatshirt|innerwear|nightwear|lingerie/.test(lc)) return APPAREL_SIZES;
  return ALL_SIZES;
}

// Color name → hex swatch. Names must match what sellers enter in the variant
// library (case-insensitive). When the swatch is selected the URL stores the
// human name (?colors=Red,Blue) so it shares the multi-select toggleMulti path.
const COLOR_OPTIONS: Array<{ name: string; hex: string }> = [
  { name: 'Black',   hex: '#111111' },
  { name: 'White',   hex: '#F5F5F5' },
  { name: 'Grey',    hex: '#6B7280' },
  { name: 'Navy',    hex: '#1E3A8A' },
  { name: 'Blue',    hex: '#2563EB' },
  { name: 'Red',     hex: '#DC2626' },
  { name: 'Maroon',  hex: '#7C2D12' },
  { name: 'Pink',    hex: '#EC4899' },
  { name: 'Purple',  hex: '#7C3AED' },
  { name: 'Green',   hex: '#16A34A' },
  { name: 'Teal',    hex: '#0D9488' },
  { name: 'Yellow',  hex: '#F59E0B' },
  { name: 'Mustard', hex: '#CA8A04' },
  { name: 'Orange',  hex: '#EA580C' },
  { name: 'Brown',   hex: '#92400E' },
  { name: 'Beige',   hex: '#D4C5A0' },
];

const PAGE_SIZE = 20;

function useCollapse(initial = true) {
  const [open, setOpen] = useState(initial);
  return { open, toggle: () => setOpen((v) => !v) };
}

export const ProductListPage: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false);
  const [page, setPage] = useState(1);

  const menuId = searchParams.get('menuId') ? Number(searchParams.get('menuId')) : undefined;
  const categoryId = searchParams.get('categoryId') ? Number(searchParams.get('categoryId')) : undefined;
  const subCategoryId = searchParams.get('subCategoryId') ? Number(searchParams.get('subCategoryId')) : undefined;
  const search = searchParams.get('search') ?? undefined;
  const sortBy = (searchParams.get('sortBy') as ProductQueryParams['sortBy']) ?? 'LATEST';
  const minPrice = searchParams.get('minPrice') ? Number(searchParams.get('minPrice')) : undefined;
  const maxPrice = searchParams.get('maxPrice') ? Number(searchParams.get('maxPrice')) : undefined;
  const selectedSizes = searchParams.get('sizes') ?? '';
  const selectedColors = searchParams.get('colors') ?? '';
  const selectedBrands = searchParams.get('brandIds') ?? '';
  const datePosted = searchParams.get('datePosted') ?? undefined;

  const queryParams: ProductQueryParams = {
    menuId, categoryId, subCategoryId, search, sortBy,
    minPrice, maxPrice,
    sizes: selectedSizes || undefined,
    colors: selectedColors || undefined,
    brandIds: selectedBrands || undefined,
    datePosted,
    pageNo: page, pageSize: PAGE_SIZE,
  };

  const { data, isLoading, isError } = useQuery({
    queryKey: ['products', queryParams],
    queryFn: () => productsApi.getProducts(queryParams).then((r) => r.data.data),
  });

  const { data: menuCategories = [] } = useQuery({
    queryKey: ['mega-menu'],
    queryFn: () => catalogueApi.getMegaMenu().then((r) => r.data.data),
    staleTime: 1000 * 60 * 10,
  });

  const { data: allBrands = [] } = useQuery({
    queryKey: ['brands'],
    queryFn: () => brandsApi.getAll().then((r) => r.data.data),
    staleTime: 1000 * 60 * 30,
  });

  const setParam = useCallback(
    (key: string, value: string | undefined) => {
      setSearchParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          if (value === undefined || value === '') next.delete(key);
          else next.set(key, value);
          return next;
        },
        // Don't snap the page back to the top — buyers lose their place in the
        // sidebar tree and the product grid every time they tick a filter.
        { preventScrollReset: true },
      );
      setPage(1);
    },
    [setSearchParams]
  );

  const toggleMulti = (key: string, value: string) => {
    const current = searchParams.get(key) ?? '';
    const parts = current ? current.split(',') : [];
    const idx = parts.indexOf(value);
    if (idx >= 0) parts.splice(idx, 1);
    else parts.push(value);
    setParam(key, parts.join(',') || undefined);
  };

  const isSelected = (key: string, value: string) =>
    (searchParams.get(key) ?? '').split(',').includes(value);

  const products = data?.items ?? [];
  const totalCount = data?.totalCount ?? 0;
  const hasMore = page * PAGE_SIZE < totalCount;

  const catFilter = useCollapse(true);
  const brandFilter = useCollapse(true);
  const priceFilter = useCollapse(true);
  const dateFilter = useCollapse(true);
  const sizeFilter = useCollapse(true);
  const colorFilter = useCollapse(true);

  // Dynamic size list — derived from whichever subcategory (or product type) is
  // currently selected. Falls back to category-level name if no leaf is picked.
  const selectedSubName = useMemo(() => {
    if (subCategoryId) {
      for (const m of menuCategories) {
        for (const c of m.subCategories) {
          const pt = c.productTypes?.find((p) => p.id === subCategoryId);
          if (pt) return pt.name;
        }
      }
    }
    if (categoryId) {
      for (const m of menuCategories) {
        const c = m.subCategories.find((x) => x.id === categoryId);
        if (c) return c.name;
      }
    }
    return null;
  }, [menuCategories, categoryId, subCategoryId]);

  const sizeOptions = useMemo(
    () => sizesForSubCategoryName(selectedSubName),
    [selectedSubName],
  );

  // Drop any size selections that don't fit the new scale (switching from
  // T-shirts to Shoes shouldn't keep "M" applied — the backend would just
  // return zero rows and confuse the buyer).
  useEffect(() => {
    if (!selectedSizes) return;
    const allowed = new Set(sizeOptions);
    const picks = selectedSizes.split(',').filter(Boolean);
    const next = picks.filter((s) => allowed.has(s));
    if (next.length !== picks.length) {
      setParam('sizes', next.length ? next.join(',') : undefined);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedSubName]);

  // Section header — reusable "+/−" expander styled to match the reference UI.
  const SectionHeader: React.FC<{ label: string; open: boolean; onToggle: () => void; count?: number }> = ({
    label, open, onToggle, count,
  }) => (
    <button
      onClick={onToggle}
      className="flex items-center justify-between w-full py-1 group"
    >
      <span className="text-sm font-semibold text-content flex items-center gap-1.5">
        {label}
        {count !== undefined && count > 0 && (
          <span className="inline-flex items-center justify-center min-w-[18px] h-[18px] px-1 bg-content text-bg text-[10px] font-bold rounded-full">
            {count}
          </span>
        )}
      </span>
      <span className="text-content-muted text-base leading-none w-5 h-5 flex items-center justify-center group-hover:text-content transition-colors">
        {open ? '−' : '+'}
      </span>
    </button>
  );

  const FiltersPanel = () => (
    <div className="space-y-6 text-sm">
      {/* Categories */}
      <div>
        <button
          onClick={catFilter.toggle}
          className="flex items-center justify-between w-full font-semibold text-content mb-3"
        >
          Categories {catFilter.open ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
        </button>
        {catFilter.open && (
          <div className="space-y-2 max-h-72 overflow-y-auto">
            {/* Scope the tree by menuId when set — buyers browsing Women shouldn't see MEN's hierarchy. */}
            {menuCategories
              .filter((menu) => menuId === undefined || menu.id === menuId)
              .map((menu) => (
              <div key={menu.id}>
                <Link
                  to={`/home/category/${menu.slug}`}
                  className="font-medium text-content hover:text-brand-500 block py-0.5"
                >
                  {menu.name}
                </Link>
                {menu.subCategories.map((cat) => (
                  <div key={cat.id}>
                    <button
                      onClick={() => {
                        const next = categoryId === cat.id ? undefined : String(cat.id);
                        setParam('categoryId', next);
                        setParam('subCategoryId', undefined);
                      }}
                      className={`block pl-4 py-0.5 text-xs text-left transition-colors ${
                        categoryId === cat.id ? 'text-brand-500 font-semibold' : 'text-content-muted hover:text-content'
                      }`}
                    >
                      {cat.name}
                    </button>
                    {cat.productTypes?.map((sub) => (
                      <button
                        key={sub.id}
                        onClick={() => {
                          setParam('categoryId', String(cat.id));
                          setParam('subCategoryId', subCategoryId === sub.id ? undefined : String(sub.id));
                        }}
                        className={`block pl-8 py-0.5 text-[11px] text-left transition-colors ${
                          subCategoryId === sub.id ? 'text-brand-500 font-semibold' : 'text-content-subtle hover:text-content'
                        }`}
                      >
                        {sub.name}
                      </button>
                    ))}
                  </div>
                ))}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Brands */}
      {allBrands.length > 0 && (
        <div>
          <button
            onClick={brandFilter.toggle}
            className="flex items-center justify-between w-full font-semibold text-content mb-3"
          >
            Brands {brandFilter.open ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
          </button>
          {brandFilter.open && (
            <div className="space-y-1.5 max-h-40 overflow-y-auto">
              {allBrands.map((brand) => (
                <label
                  key={brand.id}
                  className="flex items-center gap-2 cursor-pointer py-0.5 hover:bg-surface px-1 rounded"
                  onClick={(e) => {
                    // Make the whole row toggle the filter — not just the checkbox itself.
                    if ((e.target as HTMLElement).tagName !== 'INPUT') {
                      e.preventDefault();
                      toggleMulti('brandIds', String(brand.id));
                    }
                  }}
                >
                  <input
                    type="checkbox"
                    checked={isSelected('brandIds', String(brand.id))}
                    onChange={() => toggleMulti('brandIds', String(brand.id))}
                    className="rounded border-outline-strong text-brand-500 focus:ring-brand-300"
                  />
                  <span className="text-content hover:text-brand-500 transition-colors">{brand.name}</span>
                </label>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Size — chip grid that adapts to the selected subcategory.
          T-shirts/tops show S/M/L/XL; Trousers/Jeans show 28/30/32/34;
          Shoes show 6-12; Kids show age bands; accessories show Free Size only. */}
      <div className="border-t border-outline/60 pt-4">
        <SectionHeader
          label="Size"
          open={sizeFilter.open}
          onToggle={sizeFilter.toggle}
          count={selectedSizes ? selectedSizes.split(',').filter(Boolean).length : 0}
        />
        {sizeFilter.open && (
          <div className="mt-3">
            {selectedSubName && (
              <p className="text-[11px] text-content-subtle mb-2">
                Showing sizes for <span className="font-semibold text-content">{selectedSubName}</span>
              </p>
            )}
            <div className="flex flex-wrap gap-1.5">
              {sizeOptions.map((s) => {
                const active = isSelected('sizes', s);
                return (
                  <button
                    key={s}
                    type="button"
                    onClick={() => toggleMulti('sizes', s)}
                    className={`min-w-[40px] h-9 px-2.5 rounded-lg border text-xs font-medium transition-colors ${
                      active
                        ? 'bg-brand-500 text-white border-brand-500'
                        : 'border-outline text-content hover:border-outline-strong hover:bg-surface'
                    }`}
                    aria-pressed={active}
                  >
                    {s}
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* Color — swatch grid, multi-select. */}
      <div className="border-t border-outline/60 pt-4">
        <SectionHeader
          label="Color"
          open={colorFilter.open}
          onToggle={colorFilter.toggle}
          count={selectedColors ? selectedColors.split(',').filter(Boolean).length : 0}
        />
        {colorFilter.open && (
          <div className="mt-3 grid grid-cols-6 gap-2">
            {COLOR_OPTIONS.map(({ name, hex }) => {
              const active = isSelected('colors', name);
              return (
                <button
                  key={name}
                  type="button"
                  onClick={() => toggleMulti('colors', name)}
                  title={name}
                  aria-label={name}
                  aria-pressed={active}
                  className={`relative w-7 h-7 rounded-full border-2 transition-all ${
                    active ? 'border-brand-500 scale-110 ring-2 ring-brand-200' : 'border-outline hover:border-outline-strong'
                  }`}
                  style={{ backgroundColor: hex }}
                >
                  {active && (
                    <svg
                      viewBox="0 0 16 16"
                      className={`absolute inset-0 m-auto h-3.5 w-3.5 ${
                        ['Black', 'Navy', 'Maroon', 'Brown', 'Purple', 'Blue', 'Grey', 'Green', 'Teal'].includes(name)
                          ? 'text-white'
                          : 'text-content'
                      }`}
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.5"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M3 8l3.5 3.5L13 5" />
                    </svg>
                  )}
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Date Posted */}
      <div>
        <button
          onClick={dateFilter.toggle}
          className="flex items-center justify-between w-full font-semibold text-content mb-3"
        >
          Date Posted {dateFilter.open ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
        </button>
        {dateFilter.open && (
          <div className="space-y-1.5">
            {([
              { label: 'Today',      value: 'today' },
              { label: 'This week',  value: 'this_week' },
              { label: 'This month', value: 'this_month' },
              { label: 'Last month', value: 'last_month' },
              { label: 'Older',      value: 'older' },
            ] as const).map(({ label, value }) => (
              <label
                key={value}
                className="flex items-center gap-2 cursor-pointer py-0.5 hover:bg-surface px-1 rounded"
                onClick={(e) => {
                  if ((e.target as HTMLElement).tagName !== 'INPUT') {
                    e.preventDefault();
                    setParam('datePosted', datePosted === value ? undefined : value);
                  }
                }}
              >
                <input
                  type="checkbox"
                  checked={datePosted === value}
                  onChange={() => setParam('datePosted', datePosted === value ? undefined : value)}
                  className="rounded border-outline-strong text-brand-500 focus:ring-brand-300"
                />
                <span className={`transition-colors ${datePosted === value ? 'text-brand-500 font-medium' : 'text-content hover:text-brand-500'}`}>
                  {label}
                </span>
              </label>
            ))}
          </div>
        )}
      </div>

      {/* Price range */}
      <div>
        <button
          onClick={priceFilter.toggle}
          className="flex items-center justify-between w-full font-semibold text-content mb-3"
        >
          Price Range {priceFilter.open ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
        </button>
        {priceFilter.open && (
          <div className="space-y-3">
            <div className="flex gap-2 items-center">
              <input
                type="number"
                placeholder="Min"
                value={minPrice ?? ''}
                onChange={(e) => setParam('minPrice', e.target.value || undefined)}
                className="w-full border border-outline rounded-lg px-3 py-1.5 text-xs focus:outline-none focus:border-brand-400"
              />
              <span className="text-content-subtle">–</span>
              <input
                type="number"
                placeholder="Max"
                value={maxPrice ?? ''}
                onChange={(e) => setParam('maxPrice', e.target.value || undefined)}
                className="w-full border border-outline rounded-lg px-3 py-1.5 text-xs focus:outline-none focus:border-brand-400"
              />
            </div>
            <div className="flex flex-wrap gap-2">
              {[[0, 999], [1000, 2999], [3000, 4999], [5000, 9999]].map(([min, max]) => (
                <button
                  key={`${min}-${max}`}
                  onClick={() => { setParam('minPrice', String(min)); setParam('maxPrice', String(max)); }}
                  className={`text-xs px-3 py-1 rounded-full border transition-colors ${
                    minPrice === min && maxPrice === max
                      ? 'bg-brand-500 text-white border-brand-500'
                      : 'border-outline text-content-muted hover:border-outline-strong'
                  }`}
                >
                  ₹{min.toLocaleString('en-IN')} – ₹{max.toLocaleString('en-IN')}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

    </div>
  );

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      {/* Top bar */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h1 className="text-lg font-semibold text-content">
            {search ? `Results for "${search}"` : 'All Products'}
          </h1>
          {!isLoading && (
            <p className="text-xs text-content-muted">{totalCount.toLocaleString('en-IN')} items</p>
          )}
        </div>
        <div className="flex items-center gap-3">
          {/* Mobile filter toggle */}
          <button
            onClick={() => setMobileFiltersOpen(true)}
            className="lg:hidden flex items-center gap-2 border border-outline rounded-xl px-3 py-2 text-sm text-content"
          >
            <SlidersHorizontal className="h-4 w-4" /> Filters
          </button>

          {/* Sort */}
          <select
            value={sortBy}
            onChange={(e) => setParam('sortBy', e.target.value)}
            className="border border-outline rounded-xl px-3 py-2 text-sm text-content focus:outline-none focus:border-brand-400"
          >
            {SORT_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Active filters chips — every applied filter gets a removable chip + a Clear all shortcut. */}
      <ActiveFilters
        searchParams={searchParams}
        setParam={setParam}
        menuCategories={menuCategories}
        allBrands={allBrands}
      />

      <div className="flex gap-6">
        {/* Sidebar — desktop. Sticky so filters stay visible while the grid scrolls. */}
        <aside className="hidden lg:block w-56 flex-shrink-0">
          <div className="sticky top-20 max-h-[calc(100vh-6rem)] overflow-y-auto pr-2 -mr-2">
            <FiltersPanel />
          </div>
        </aside>

        {/* Grid */}
        <div className="flex-1 min-w-0">
          {isLoading && (
            <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-4">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i}>
                  <div className="aspect-[3/4] bg-surface-sunken rounded-2xl animate-pulse mb-2" />
                  <div className="h-3 bg-surface-sunken rounded animate-pulse mb-1" />
                  <div className="h-3 bg-surface-sunken rounded animate-pulse w-2/3" />
                </div>
              ))}
            </div>
          )}

          {isError && (
            <p className="text-center text-red-500 py-16 text-sm">Failed to load products.</p>
          )}

          {!isLoading && !isError && products.length === 0 && (
            <div className="text-center py-20 rounded-2xl border border-dashed border-outline bg-surface/40">
              <SearchX className="h-10 w-10 text-content-subtle mx-auto mb-3" />
              <p className="font-medium text-content">No products match these filters</p>
              <p className="text-sm text-content-muted mt-1">Try widening your search or clearing filters.</p>
              <button
                onClick={() => setSearchParams(new URLSearchParams())}
                className="mt-4 inline-flex items-center px-5 py-2 rounded-full bg-brand-500 hover:bg-brand-600 text-white text-sm font-semibold transition-colors"
              >
                Clear all filters
              </button>
            </div>
          )}

          {!isLoading && products.length > 0 && (
            <>
              <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-4">
                {products.map((product) => (
                  <ProductCard key={product.id} product={product} />
                ))}
              </div>

              {hasMore && (
                <div className="text-center mt-10">
                  <button
                    onClick={() => setPage((p) => p + 1)}
                    className="border border-content text-content hover:bg-stone-900 hover:text-white font-medium px-8 py-3 rounded-full text-sm transition-colors"
                  >
                    Load More
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      </div>

      {/* Mobile filter drawer — slides in from the right with a fade backdrop. */}
      <AnimatePresence>
        {mobileFiltersOpen && (
          <div className="fixed inset-0 z-50 lg:hidden">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="absolute inset-0 bg-black/50"
              onClick={() => setMobileFiltersOpen(false)}
            />
            <motion.div
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{ type: 'spring', stiffness: 320, damping: 32 }}
              className="absolute right-0 top-0 h-full w-72 bg-surface-elevated shadow-2xl overflow-y-auto"
            >
              <div className="flex items-center justify-between px-5 py-4 border-b border-outline/60 sticky top-0 bg-surface-elevated z-10">
                <h2 className="font-semibold text-content">Filters</h2>
                <button onClick={() => setMobileFiltersOpen(false)} aria-label="Close filters">
                  <X className="h-5 w-5 text-content-muted" />
                </button>
              </div>
              <div className="p-5">
                <FiltersPanel />
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

// ── Active filter chips ───────────────────────────────────────────────────
/**
 * Renders one removable chip per active query-param so buyers can see and
 * undo each filter without re-opening the sidebar. Includes a Clear all
 * when two or more filters are active.
 */
const ActiveFilters: React.FC<{
  searchParams: URLSearchParams;
  setParam: (key: string, value: string | undefined) => void;
  menuCategories: Array<{ id: number; name: string; subCategories: Array<{ id: number; name: string; productTypes?: Array<{ id: number; name: string }> }> }>;
  allBrands: Array<{ id: number; name: string }>;
}> = ({ searchParams, setParam, menuCategories, allBrands }) => {
  const chips = useMemo(() => {
    const out: Array<{ key: string; label: string; clear: () => void }> = [];

    const search = searchParams.get('search');
    if (search) out.push({ key: 's', label: `"${search}"`, clear: () => setParam('search', undefined) });

    const categoryId = searchParams.get('categoryId');
    if (categoryId) {
      const cat = menuCategories
        .flatMap((m) => m.subCategories)
        .find((c) => String(c.id) === categoryId);
      out.push({
        key: 'c',
        label: cat?.name ?? `Category #${categoryId}`,
        clear: () => { setParam('categoryId', undefined); setParam('subCategoryId', undefined); },
      });
    }

    const subCategoryId = searchParams.get('subCategoryId');
    if (subCategoryId) {
      const sub = menuCategories
        .flatMap((m) => m.subCategories.flatMap((c) => c.productTypes ?? []))
        .find((s) => String(s.id) === subCategoryId);
      out.push({
        key: 'sc',
        label: sub?.name ?? `Subcategory #${subCategoryId}`,
        clear: () => setParam('subCategoryId', undefined),
      });
    }

    const brandIds = searchParams.get('brandIds');
    if (brandIds) {
      brandIds.split(',').filter(Boolean).forEach((bid) => {
        const b = allBrands.find((x) => String(x.id) === bid);
        out.push({
          key: `b-${bid}`,
          label: b?.name ?? `Brand #${bid}`,
          clear: () => {
            const next = (searchParams.get('brandIds') ?? '').split(',').filter((x) => x !== bid).join(',');
            setParam('brandIds', next || undefined);
          },
        });
      });
    }

    const sizes = searchParams.get('sizes');
    if (sizes) {
      sizes.split(',').filter(Boolean).forEach((s) => {
        out.push({
          key: `sz-${s}`,
          label: `Size: ${s}`,
          clear: () => {
            const next = (searchParams.get('sizes') ?? '').split(',').filter((x) => x !== s).join(',');
            setParam('sizes', next || undefined);
          },
        });
      });
    }

    const colors = searchParams.get('colors');
    if (colors) {
      colors.split(',').filter(Boolean).forEach((c) => {
        out.push({
          key: `cl-${c}`,
          label: `Color: ${c}`,
          clear: () => {
            const next = (searchParams.get('colors') ?? '').split(',').filter((x) => x !== c).join(',');
            setParam('colors', next || undefined);
          },
        });
      });
    }

    const minPrice = searchParams.get('minPrice');
    const maxPrice = searchParams.get('maxPrice');
    if (minPrice || maxPrice) {
      out.push({
        key: 'p',
        label: `₹${Number(minPrice ?? 0).toLocaleString('en-IN')} – ₹${Number(maxPrice ?? 0).toLocaleString('en-IN')}`,
        clear: () => { setParam('minPrice', undefined); setParam('maxPrice', undefined); },
      });
    }

    const datePosted = searchParams.get('datePosted');
    if (datePosted) {
      out.push({
        key: 'd',
        label: datePosted.replace('_', ' '),
        clear: () => setParam('datePosted', undefined),
      });
    }

    return out;
  }, [searchParams, menuCategories, allBrands, setParam]);

  if (chips.length === 0) return null;

  return (
    <div className="flex flex-wrap gap-2 mb-4 items-center">
      {chips.map((chip) => (
        <span
          key={chip.key}
          className="inline-flex items-center gap-1 bg-surface-sunken hover:bg-surface text-content text-xs px-3 py-1 rounded-full border border-outline/60 transition-colors"
        >
          <span className="capitalize">{chip.label}</span>
          <button onClick={chip.clear} aria-label={`Remove filter ${chip.label}`} className="hover:text-red-600">
            <X className="h-3 w-3" />
          </button>
        </span>
      ))}
      {chips.length > 1 && (
        <button
          onClick={() => {
            ['search', 'categoryId', 'subCategoryId', 'brandIds', 'sizes', 'colors', 'minPrice', 'maxPrice', 'datePosted']
              .forEach((k) => setParam(k, undefined));
          }}
          className="text-xs text-content-muted hover:text-red-600 underline-offset-2 hover:underline"
        >
          Clear all
        </button>
      )}
    </div>
  );
};
