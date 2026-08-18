import React, { useState, useRef, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search, ShoppingBag, Heart, Menu, X,
  MapPin, ChevronDown, LogOut, Package, Settings, User,
  Sparkles, Wallet, LayoutDashboard, Sun, Moon, Monitor,
} from 'lucide-react';
import { useTheme, type ThemeMode } from '../../context/ThemeContext';
import { clsx } from 'clsx';
import { catalogueApi } from '../../api/catalogueApi';
import { useAuthContext } from '../../context/AuthContext';
import { useCart } from '../../hooks/useCart';
import { usePreviewMode } from '../../hooks/usePreviewMode';
import { NotificationBell } from './NotificationBell';
import { MegaMenu } from './MegaMenu';
import { StoreLocatorDrawer } from '../../features/stores/StoreLocatorDrawer';

export const Header: React.FC = () => {
  const [mobileOpen,       setMobileOpen]       = useState(false);
  const [searchQuery,      setSearchQuery]       = useState('');
  const [searchFocused,    setSearchFocused]     = useState(false);
  const [activeCategoryId, setActiveCategoryId] = useState<number | null>(null);
  const [accountOpen,      setAccountOpen]       = useState(false);
  const [storeDrawerOpen,  setStoreDrawerOpen]   = useState(false);

  const megaMenuTimeout = useRef<ReturnType<typeof setTimeout> | null>(null);
  const accountRef      = useRef<HTMLDivElement>(null);
  const navigate        = useNavigate();

  const { isAuthenticated, user, logout } = useAuthContext();
  const { cartCount } = useCart();
  const previewMode   = usePreviewMode();

  const { data: menuCategories = [] } = useQuery({
    queryKey: ['mega-menu'],
    queryFn:  () => catalogueApi.getMegaMenu().then((r) => r.data.data),
    staleTime: 1000 * 60 * 10,
  });

  // Close account dropdown on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (accountRef.current && !accountRef.current.contains(e.target as Node)) {
        setAccountOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/home/products?search=${encodeURIComponent(searchQuery.trim())}`);
      setMobileOpen(false);
      setSearchFocused(false);
    }
  };

  const handleCategoryHover = (id: number) => {
    if (megaMenuTimeout.current) clearTimeout(megaMenuTimeout.current);
    setActiveCategoryId(id);
  };

  const handleMenuLeave = () => {
    megaMenuTimeout.current = setTimeout(() => setActiveCategoryId(null), 150);
  };

  const handleMegaMenuEnter = () => {
    if (megaMenuTimeout.current) clearTimeout(megaMenuTimeout.current);
  };

  const userInitial = user?.firstName?.[0]?.toUpperCase()
    ?? user?.name?.[0]?.toUpperCase()
    ?? user?.email?.[0]?.toUpperCase()
    ?? 'U';

  const displayName = user?.firstName
    ? `${user.firstName}${user.lastName ? ' ' + user.lastName : ''}`
    : user?.name ?? user?.mobile ?? 'My Account';

  return (
    <header className="sticky top-0 z-50 bg-surface-elevated">
      {/* ── Announcement bar ──────────────────────────────────────── */}
      <div className="bg-stone-900 text-white text-xs text-center py-2 tracking-wide">
        <span className="flex items-center justify-center gap-2">
          <Sparkles className="h-3 w-3 text-brand-300 flex-shrink-0" />
          Free shipping on orders above ₹999 &nbsp;·&nbsp; Use{' '}
          <span className="font-bold text-brand-300 bg-white/10 rounded px-1.5 py-0.5">WELCOME10</span>
          {' '}for 10% off your first order
          <Sparkles className="h-3 w-3 text-brand-300 flex-shrink-0" />
        </span>
      </div>

      {/* ── Main nav ──────────────────────────────────────────────── */}
      <div className="border-b border-outline/60">
        <div className="max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16 gap-4">

            {/* Logo */}
            <Link to="/" className="flex-shrink-0 group">
              <span className="font-display text-2xl font-black tracking-tight">
                <span className="text-brand-500 group-hover:text-brand-600 transition-colors">Stop</span>
                <span className="text-content">N</span>
                <span className="text-brand-500 group-hover:text-brand-600 transition-colors">Shop</span>
              </span>
            </Link>

            {/* Search bar — desktop */}
            <form
              onSubmit={handleSearch}
              className="hidden md:flex flex-1 max-w-2xl mx-4 relative"
            >
              <div className={`relative w-full transition-all duration-200 ${searchFocused ? 'ring-2 ring-brand-300 rounded-full' : ''}`}>
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle pointer-events-none" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onFocus={() => setSearchFocused(true)}
                  onBlur={() => setSearchFocused(false)}
                  placeholder="Search products, brands, categories…"
                  className="w-full pl-10 pr-20 py-2.5 border border-transparent rounded-full text-sm bg-surface-sunken focus:bg-surface-elevated focus:border-brand-300 focus:outline-none transition-colors"
                />
                <button
                  type="submit"
                  className="absolute right-1.5 top-1/2 -translate-y-1/2 bg-brand-500 hover:bg-brand-600 text-white text-xs font-semibold px-4 py-1.5 rounded-full transition-colors"
                >
                  Search
                </button>
              </div>
            </form>

            {/* Actions */}
            <div className="flex items-center gap-0.5 sm:gap-1">

              {/* Store finder — desktop */}
              <button
                onClick={() => setStoreDrawerOpen(true)}
                className="hidden sm:flex items-center gap-1.5 px-2 py-2 rounded-lg text-content-muted hover:text-brand-500 hover:bg-brand-50 transition-colors text-xs font-medium"
              >
                <MapPin className="h-4.5 w-4.5 h-5 w-5" />
                <span className="hidden lg:block">Find a Store</span>
              </button>

              {isAuthenticated ? (
                <>
                  {/* Wishlist — hidden in admin preview mode */}
                  {!previewMode && (
                    <Link
                      to="/user/wishlist"
                      className="relative p-2 rounded-lg text-content-muted hover:text-brand-500 hover:bg-brand-50 transition-colors"
                      aria-label="Wishlist"
                    >
                      <Heart className="h-5 w-5" />
                    </Link>
                  )}

                  {/* Account dropdown */}
                  <div ref={accountRef} className="relative hidden sm:block">
                    <button
                      onClick={() => setAccountOpen((v) => !v)}
                      className="flex items-center gap-1.5 px-2 py-1.5 rounded-lg hover:bg-surface transition-colors"
                    >
                      <div className="w-7 h-7 rounded-full bg-gradient-to-br from-brand-500 to-brand-600 flex items-center justify-center text-white text-xs font-bold shadow-sm">
                        {userInitial}
                      </div>
                      <span className="hidden lg:block text-sm font-medium text-content max-w-[80px] truncate">
                        {user?.firstName ?? 'Account'}
                      </span>
                      <ChevronDown className={`h-3.5 w-3.5 text-content-subtle transition-transform ${accountOpen ? 'rotate-180' : ''}`} />
                    </button>

                    {accountOpen && (
                      <div className="absolute right-0 top-full mt-2 w-56 bg-surface-elevated border border-outline rounded-2xl shadow-soft-lg py-2 z-50 overflow-hidden">
                        {/* User info header */}
                        <div className="px-4 py-3 border-b border-outline/60">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-brand-500 to-brand-600 flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                              {userInitial}
                            </div>
                            <div className="overflow-hidden">
                              <p className="text-sm font-semibold text-content truncate">{displayName}</p>
                              {user?.email && (
                                <p className="text-xs text-content-muted truncate">{user.email}</p>
                              )}
                            </div>
                          </div>
                        </div>

                        <div className="py-1">
                          {previewMode ? (
                            <DropdownLink to="/admin/dashboard" icon={<LayoutDashboard className="h-4 w-4" />} label="Back to Dashboard" onClick={() => setAccountOpen(false)} />
                          ) : (
                            <>
                              <DropdownLink to="/user/orders" icon={<Package className="h-4 w-4" />} label="My Orders" onClick={() => setAccountOpen(false)} />
                              <DropdownLink to="/user/wishlist" icon={<Heart className="h-4 w-4" />} label="Wishlist" onClick={() => setAccountOpen(false)} />
                              <DropdownLink to="/user/wallet" icon={<Wallet className="h-4 w-4" />} label="My Wallet" onClick={() => setAccountOpen(false)} />
                              <DropdownLink to="/user/profile" icon={<Settings className="h-4 w-4" />} label="Profile Settings" onClick={() => setAccountOpen(false)} />
                            </>
                          )}
                        </div>

                        <ThemeRow />

                        <div className="border-t border-outline/60 pt-1">
                          <button
                            onClick={() => { logout(); setAccountOpen(false); navigate('/'); }}
                            className="flex items-center gap-3 w-full px-4 py-2.5 text-sm text-red-500 hover:bg-red-50 transition-colors"
                          >
                            <LogOut className="h-4 w-4" />
                            <span className="font-medium">Sign Out</span>
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                </>
              ) : (
                <div className="hidden sm:flex items-center gap-2">
                  <Link
                    to="/user/login"
                    className="text-sm font-semibold text-content hover:text-brand-500 px-3 py-2 rounded-lg hover:bg-surface transition-colors"
                  >
                    Sign In
                  </Link>
                </div>
              )}

              {/* Notification bell + Cart — hidden in admin preview mode */}
              {!previewMode && (
                <>
                  <NotificationBell />

                  <button
                    onClick={() => navigate('/user/cart')}
                    className="relative p-2 rounded-lg text-content-muted hover:text-brand-500 hover:bg-brand-50 transition-colors"
                    aria-label={`Cart${cartCount > 0 ? ` (${cartCount})` : ''}`}
                  >
                    <ShoppingBag className="h-5 w-5" />
                    <AnimatePresence mode="popLayout">
                      {cartCount > 0 && (
                        <motion.span
                          key={cartCount}
                          initial={{ scale: 0.4, opacity: 0 }}
                          animate={{ scale: 1, opacity: 1 }}
                          exit={{ scale: 0.4, opacity: 0 }}
                          className="absolute -top-0.5 -right-0.5 bg-brand-500 text-white text-[10px] font-black rounded-full w-5 h-5 flex items-center justify-center shadow-sm"
                        >
                          {cartCount > 9 ? '9+' : cartCount}
                        </motion.span>
                      )}
                    </AnimatePresence>
                  </button>
                </>
              )}

              {/* Mobile menu toggle */}
              <button
                className="md:hidden p-2 rounded-lg text-content-muted hover:bg-surface transition-colors"
                onClick={() => setMobileOpen(!mobileOpen)}
                aria-label="Menu"
              >
                {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
              </button>
            </div>
          </div>

          {/* ── Category nav — desktop ─────────────────────────────── */}
          <nav
            className="hidden md:flex items-center gap-0.5 pb-1 relative"
            onMouseLeave={handleMenuLeave}
          >
            {menuCategories.map((cat) => (
              <Link
                key={cat.id}
                to={`/home/category/${cat.slug}`}
                onMouseEnter={() => handleCategoryHover(cat.id)}
                className={`px-3.5 py-2 text-sm font-medium rounded-lg transition-colors whitespace-nowrap ${
                  activeCategoryId === cat.id
                    ? 'text-brand-500 bg-brand-50'
                    : 'text-content-muted hover:text-brand-500 hover:bg-surface'
                }`}
              >
                {cat.name}
              </Link>
            ))}

            {activeCategoryId && (
              <div onMouseEnter={handleMegaMenuEnter}>
                <MegaMenu
                  categories={menuCategories}
                  activeCategoryId={activeCategoryId}
                  onClose={() => setActiveCategoryId(null)}
                />
              </div>
            )}
          </nav>
        </div>
      </div>

      {/* ── Mobile menu ───────────────────────────────────────────── */}
      {mobileOpen && (
        <div className="md:hidden border-t border-outline/60 bg-surface-elevated shadow-soft-lg">
          {/* Mobile search */}
          <div className="px-4 pt-3 pb-2">
            <form onSubmit={handleSearch} className="flex">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search products..."
                className="flex-1 pl-4 pr-3 py-2.5 border border-transparent rounded-l-xl text-sm bg-surface-sunken focus:bg-surface-elevated focus:outline-none focus:border-brand-400 transition-colors"
              />
              <button
                type="submit"
                className="bg-brand-500 hover:bg-brand-600 text-white px-4 rounded-r-xl transition-colors"
              >
                <Search className="h-4 w-4" />
              </button>
            </form>
          </div>

          {/* Mobile categories */}
          <div className="px-2 pb-2 space-y-0.5">
            {menuCategories.map((cat) => (
              <Link
                key={cat.id}
                to={`/home/category/${cat.slug}`}
                onClick={() => setMobileOpen(false)}
                className="flex items-center px-3 py-2.5 rounded-xl text-sm font-medium text-content hover:text-brand-500 hover:bg-brand-50 transition-colors"
              >
                {cat.name}
              </Link>
            ))}
          </div>

          <div className="mx-4 border-t border-outline/60 py-3 flex flex-col gap-2">
            {isAuthenticated ? (
              <div className="space-y-1">
                <div className="flex items-center gap-3 px-3 py-2">
                  <div className="w-8 h-8 rounded-full bg-gradient-to-br from-brand-500 to-brand-600 flex items-center justify-center text-white text-xs font-bold">
                    {userInitial}
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-content">{displayName}</p>
                    {user?.email && <p className="text-xs text-content-muted">{user.email}</p>}
                  </div>
                </div>
                {previewMode ? (
                  <Link to="/admin/dashboard" onClick={() => setMobileOpen(false)} className="flex items-center gap-2 px-3 py-2 text-sm text-content hover:bg-surface rounded-xl">
                    <LayoutDashboard className="h-4 w-4" /> Back to Dashboard
                  </Link>
                ) : (
                  <>
                    <Link to="/user/orders" onClick={() => setMobileOpen(false)} className="flex items-center gap-2 px-3 py-2 text-sm text-content hover:bg-surface rounded-xl">
                      <Package className="h-4 w-4" /> My Orders
                    </Link>
                    <Link to="/user/wishlist" onClick={() => setMobileOpen(false)} className="flex items-center gap-2 px-3 py-2 text-sm text-content hover:bg-surface rounded-xl">
                      <Heart className="h-4 w-4" /> Wishlist
                    </Link>
                    <Link to="/user/wallet" onClick={() => setMobileOpen(false)} className="flex items-center gap-2 px-3 py-2 text-sm text-content hover:bg-surface rounded-xl">
                      <Wallet className="h-4 w-4" /> My Wallet
                    </Link>
                    <Link to="/user/profile" onClick={() => setMobileOpen(false)} className="flex items-center gap-2 px-3 py-2 text-sm text-content hover:bg-surface rounded-xl">
                      <User className="h-4 w-4" /> Profile
                    </Link>
                  </>
                )}
                <button
                  onClick={() => { logout(); setMobileOpen(false); navigate('/'); }}
                  className="flex items-center gap-2 w-full px-3 py-2 text-sm text-red-500 hover:bg-red-50 rounded-xl transition-colors"
                >
                  <LogOut className="h-4 w-4" /> Sign Out
                </button>
              </div>
            ) : (
              <div className="flex gap-2">
                <Link
                  to="/user/login"
                  onClick={() => setMobileOpen(false)}
                  className="flex-1 text-center border border-outline text-sm py-2.5 rounded-xl font-semibold text-content hover:border-brand-300 hover:text-brand-500 transition-colors"
                >
                  Sign In
                </Link>
              </div>
            )}
          </div>
        
        </div>
      )}

      <StoreLocatorDrawer open={storeDrawerOpen} onClose={() => setStoreDrawerOpen(false)} />
    </header>
  );
};

/* ── Helpers ─────────────────────────────────────────────────────── */

interface DropdownLinkProps {
  to: string;
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
}

const DropdownLink: React.FC<DropdownLinkProps> = ({ to, icon, label, onClick }) => (
  <Link
    to={to}
    onClick={onClick}
    className="flex items-center gap-3 px-4 py-2.5 text-sm text-content hover:bg-surface transition-colors"
  >
    <span className="text-content-subtle">{icon}</span>
    <span className="font-medium">{label}</span>
  </Link>
);

const THEME_OPTIONS: Array<{ value: ThemeMode; label: string; Icon: React.ComponentType<{ className?: string }> }> = [
  { value: 'light',  label: 'Light',  Icon: Sun },
  { value: 'dark',   label: 'Dark',   Icon: Moon },
  { value: 'system', label: 'System', Icon: Monitor },
];

const ThemeRow: React.FC = () => {
  const { mode, setMode } = useTheme();
  return (
    <div className="px-4 py-3 border-t border-outline/60">
      <p className="text-[11px] uppercase tracking-wider font-semibold text-content-subtle mb-2">
        Theme
      </p>
      <div className="flex bg-surface-sunken rounded-xl p-1 gap-1">
        {THEME_OPTIONS.map(({ value, label, Icon }) => {
          const active = mode === value;
          return (
            <button
              key={value}
              type="button"
              role="menuitemradio"
              aria-checked={active}
              onClick={() => setMode(value)}
              title={label}
              className={clsx(
                'flex-1 flex items-center justify-center gap-1.5 py-1.5 rounded-lg text-xs font-medium transition-colors',
                active
                  ? 'bg-surface-elevated text-content shadow-soft'
                  : 'text-content-muted hover:text-content',
              )}
            >
              <Icon className="w-3.5 h-3.5" />
              <span>{label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
