import React, { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useLocation, useParams } from 'react-router-dom';
import { Header } from '../components/layout/Header';
import { Footer } from '../components/layout/Footer';
import { CartDrawer } from '../components/cart/CartDrawer';
import { Spinner } from '../components/ui/Spinner';
import { ErrorBoundary } from '../components/ErrorBoundary';
import { AIAgentDrawer } from '../components/ai/AIAgentDrawer';
import { CommandPalette } from '../components/ui/CommandPalette';
import { useAuthContext } from '../context/AuthContext';
import { useToast } from '../components/ui/Toast';
import { WelcomeBonusModal } from '../components/ui/WelcomeBonusModal';

// Param-preserving redirects (Navigate's `to` prop doesn't expand `:slug` style placeholders).
const CategorySlugRedirect: React.FC = () => {
  const { slug } = useParams<{ slug: string }>();
  return <Navigate to={`/home/category/${slug ?? ''}`} replace />;
};

const OrderRedirect: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  return <Navigate to={`/user/orders/${id ?? ''}`} replace />;
};

// ── Customer pages ───────────────────────────────────────────────
const HomePage          = lazy(() => import('../features/home/HomePage').then(m => ({ default: m.HomePage })));
const LoginPage         = lazy(() => import('../features/auth/LoginPage').then(m => ({ default: m.LoginPage })));
const SignupPage        = lazy(() => import('../features/auth/SignupPage').then(m => ({ default: m.SignupPage })));
const CategoryPage      = lazy(() => import('../features/category/CategoryPage').then(m => ({ default: m.CategoryPage })));
const ProductListPage   = lazy(() => import('../features/products/ProductListPage').then(m => ({ default: m.ProductListPage })));
const ProductDetailPage = lazy(() => import('../features/products/ProductDetailPage').then(m => ({ default: m.ProductDetailPage })));
const WishlistPage      = lazy(() => import('../features/wishlist/WishlistPage').then(m => ({ default: m.WishlistPage })));
const CartPage          = lazy(() => import('../features/cart/CartPage').then(m => ({ default: m.CartPage })));
const OrdersListPage    = lazy(() => import('../features/orders/OrdersListPage').then(m => ({ default: m.OrdersListPage })));
const OrderDetailPage   = lazy(() => import('../features/orders/OrderDetailPage').then(m => ({ default: m.OrderDetailPage })));
const NotFoundPage      = lazy(() => import('../features/errors/NotFoundPage').then(m => ({ default: m.NotFoundPage })));

// ── Account pages ────────────────────────────────────────────────
const ProfilePage       = lazy(() => import('../features/account/ProfilePage').then(m => ({ default: m.ProfilePage })));
const AddressesPage     = lazy(() => import('../features/account/AddressesPage').then(m => ({ default: m.AddressesPage })));
const NotificationPage  = lazy(() => import('../features/notifications/NotificationPage').then(m => ({ default: m.NotificationPage })));
const WalletPage        = lazy(() => import('../features/wallet/WalletPage').then(m => ({ default: m.WalletPage })));

// ── Seller pages ─────────────────────────────────────────────────
const SellerLoginPage        = lazy(() => import('../features/seller/SellerLoginPage').then(m => ({ default: m.SellerLoginPage })));
const SellerSignupPage       = lazy(() => import('../features/seller/SellerSignupPage').then(m => ({ default: m.SellerSignupPage })));
const SellerOnboardingPage   = lazy(() => import('../features/seller/SellerOnboardingPage').then(m => ({ default: m.SellerOnboardingPage })));
const SellerDashboardPage    = lazy(() => import('../features/seller/SellerDashboardPage').then(m => ({ default: m.SellerDashboardPage })));
const SellerProductsPage     = lazy(() => import('../features/seller/SellerProductsPage').then(m => ({ default: m.SellerProductsPage })));
const SellerAddProductPage   = lazy(() => import('../features/seller/SellerAddProductPage').then(m => ({ default: m.SellerAddProductPage })));
const SellerEditProductPage  = lazy(() => import('../features/seller/SellerEditProductPage').then(m => ({ default: m.SellerEditProductPage })));
const SellerOrdersPage       = lazy(() => import('../features/seller/SellerOrdersPage').then(m => ({ default: m.SellerOrdersPage })));
const SellerOrderQueuePage   = lazy(() => import('../features/seller/SellerOrderQueuePage').then(m => ({ default: m.SellerOrderQueuePage })));
const PrintLabelPage         = lazy(() => import('../features/seller/print/PrintLabelPage').then(m => ({ default: m.PrintLabelPage })));
const SellerProfilePage           = lazy(() => import('../features/seller/SellerProfilePage').then(m => ({ default: m.SellerProfilePage })));
const SellerSettlementsPage       = lazy(() => import('../features/seller/SellerSettlementsPage').then(m => ({ default: m.SellerSettlementsPage })));
const SellerSettlementDetailPage  = lazy(() => import('../features/seller/SellerSettlementDetailPage').then(m => ({ default: m.SellerSettlementDetailPage })));
const SellerBankAccountsPage      = lazy(() => import('../features/seller/SellerBankAccountsPage').then(m => ({ default: m.SellerBankAccountsPage })));
const SellerWarehousesPage        = lazy(() => import('../features/seller/SellerWarehousesPage').then(m => ({ default: m.SellerWarehousesPage })));

// ── Admin pages ──────────────────────────────────────────────────
const AdminDashboardPage = lazy(() => import('../features/admin/AdminDashboardPage').then(m => ({ default: m.AdminDashboardPage })));
const AdminSellersPage   = lazy(() => import('../features/admin/AdminSellersPage').then(m => ({ default: m.AdminSellersPage })));
const AdminProductsPage  = lazy(() => import('../features/admin/AdminProductsPage').then(m => ({ default: m.AdminProductsPage })));
const AdminUsersPage     = lazy(() => import('../features/admin/AdminUsersPage').then(m => ({ default: m.AdminUsersPage })));
const AdminOrdersPage    = lazy(() => import('../features/admin/AdminOrdersPage').then(m => ({ default: m.AdminOrdersPage })));
const AdminCMSPage       = lazy(() => import('../features/admin/AdminCMSPage').then(m => ({ default: m.AdminCMSPage })));
const AdminCouponsPage   = lazy(() => import('../features/admin/AdminCouponsPage').then(m => ({ default: m.AdminCouponsPage })));
const AdminReviewsPage   = lazy(() => import('../features/admin/AdminReviewsPage').then(m => ({ default: m.AdminReviewsPage })));
const AdminAuditPage     = lazy(() => import('../features/admin/AdminAuditPage').then(m => ({ default: m.AdminAuditPage })));
const AdminInventoryPage = lazy(() => import('../features/admin/AdminInventoryPage').then(m => ({ default: m.AdminInventoryPage })));
const AdminCategoriesPage = lazy(() => import('../features/admin/AdminCategoriesPage').then(m => ({ default: m.AdminCategoriesPage })));
const AdminComplaintsPage = lazy(() => import('../features/admin/AdminComplaintsPage').then(m => ({ default: m.AdminComplaintsPage })));
const SellerInventoryPage = lazy(() => import('../features/seller/SellerInventoryPage').then(m => ({ default: m.SellerInventoryPage })));

// ── Dispatcher pages ─────────────────────────────────────────────
const DispatcherLoginPage    = lazy(() => import('../features/dispatch/DispatcherLoginPage').then(m => ({ default: m.DispatcherLoginPage })));
const DispatcherTodayPage    = lazy(() => import('../features/dispatch/DispatcherTodayPage').then(m => ({ default: m.DispatcherTodayPage })));
const DispatcherPickupsPage  = lazy(() => import('../features/dispatch/DispatcherPickupsPage').then(m => ({ default: m.DispatcherPickupsPage })));
const DispatcherActivePage   = lazy(() => import('../features/dispatch/DispatcherActivePage').then(m => ({ default: m.DispatcherActivePage })));

// ── Loaders & Guards ─────────────────────────────────────────────
const PageLoader = () => (
  <div className="min-h-[60vh] flex items-center justify-center">
    <Spinner size="lg" />
  </div>
);

const CustomerRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, user, isLoading } = useAuthContext();
  const location = useLocation();
  if (isLoading) return <PageLoader />;
  // Admin previewing the storefront — bounce them back to their own dashboard
  // instead of asking them to "log in as buyer" for a personal page they can't use.
  if (isAuthenticated && user?.role === 'Admin') {
    return <Navigate to="/admin/dashboard" replace />;
  }
  const isCustomer = user?.role === 'Buyer' || user?.role === 'Customer';
  if (!isAuthenticated || !isCustomer) {
    return <Navigate to="/user/login" state={{ returnUrl: location.pathname + location.search }} replace />;
  }
  return <>{children}</>;
};

// Cart preview: admit Buyers AND Admins (admin gets the read-only preview view).
const BuyerOrAdminRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, user, isLoading } = useAuthContext();
  const location = useLocation();
  if (isLoading) return <PageLoader />;
  const role = user?.role;
  const ok = isAuthenticated && (role === 'Buyer' || role === 'Customer' || role === 'Admin');
  if (!ok) {
    return <Navigate to="/user/login" state={{ returnUrl: location.pathname + location.search }} replace />;
  }
  return <>{children}</>;
};

// Lightweight wrong-role notifier — fires a single toast then renders Navigate.
// Guarded with both a module-level dedupe key and a mount ref so React 18
// StrictMode's double-invocation of effects can't fire the toast twice.
const recentBounces = new Map<string, number>();
const WrongRoleBounce: React.FC<{ to: string; message: string }> = ({ to, message }) => {
  const { showToast } = useToast();
  const fired = React.useRef(false);
  React.useEffect(() => {
    if (fired.current) return;
    const key = `${to}|${message}`;
    const now = Date.now();
    const last = recentBounces.get(key) ?? 0;
    if (now - last < 1500) return;   // already fired in the last 1.5s — skip
    recentBounces.set(key, now);
    fired.current = true;
    showToast(message, 'error');
  }, [showToast, message, to]);
  return <Navigate to={to} replace />;
};

const SellerRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, user, isLoading } = useAuthContext();
  const location = useLocation();
  if (isLoading) return <PageLoader />;
  if (!isAuthenticated)
    return <Navigate to="/seller/login" state={{ returnUrl: location.pathname + location.search }} replace />;
  if (user?.role !== 'Seller')
    return <WrongRoleBounce to="/home" message="That area is for sellers only." />;
  return <>{children}</>;
};

const AdminRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, user, isLoading } = useAuthContext();
  const location = useLocation();
  if (isLoading) return <PageLoader />;
  if (!isAuthenticated)
    return <Navigate to="/user/login" state={{ returnUrl: location.pathname + location.search }} replace />;
  if (user?.role !== 'Admin')
    return <WrongRoleBounce to="/home" message="That area is for admins only." />;
  return <>{children}</>;
};

const DispatcherRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, user, isLoading } = useAuthContext();
  const location = useLocation();
  if (isLoading) return <PageLoader />;
  if (!isAuthenticated)
    return <Navigate to="/dispatch/login" state={{ returnUrl: location.pathname + location.search }} replace />;
  if (user?.role !== 'Dispatcher')
    return <WrongRoleBounce to="/home" message="That area is for dispatchers only." />;
  return <>{children}</>;
};

// Auth/signup pages — keep them out of reach when already signed in so a
// buyer can't manually open `/seller/login` (the page would otherwise render
// and look like an invitation to start a parallel seller session).
const GuestRoute: React.FC<{ children: React.ReactNode; allowRole?: 'Buyer' | 'Seller' }> = ({ children, allowRole }) => {
  const { isAuthenticated, user, isLoading } = useAuthContext();
  if (isLoading) return <PageLoader />;
  if (!isAuthenticated) return <>{children}</>;
  // Already-signed-in user — if their role doesn't match what this page is for,
  // bounce them to a sensible landing with a toast.
  const role = user?.role;
  if (allowRole === 'Seller' && role !== 'Seller') {
    return <WrongRoleBounce to="/home" message="You're already signed in. Sign out first to use a seller account." />;
  }
  if (allowRole === 'Buyer' && role === 'Seller') {
    return <WrongRoleBounce to="/seller/dashboard" message="You're signed in as a seller." />;
  }
  if (allowRole === 'Buyer' && role === 'Admin') {
    return <Navigate to="/admin/dashboard" replace />;
  }
  // Same-role visitor revisiting login page → send to their dashboard
  if (role === 'Seller') return <Navigate to="/seller/dashboard" replace />;
  if (role === 'Admin')  return <Navigate to="/admin/dashboard" replace />;
  return <Navigate to="/home" replace />;
};

const MainLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="flex flex-col min-h-screen bg-bg">
    <Header />
    <div className="flex-1">
      <Suspense fallback={<PageLoader />}>{children}</Suspense>
    </div>
    <Footer />
    <WelcomeBonusModal />
  </div>
);

const AuthLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <Suspense fallback={<PageLoader />}>{children}</Suspense>
);

const S = ({ children }: { children: React.ReactNode }) => (
  <Suspense fallback={<PageLoader />}>{children}</Suspense>
);

export const AppRouter: React.FC = () => (
  <BrowserRouter>
    <Routes>
      {/* ── Customer Auth ─────────────────────────────────────── */}
      <Route path="/user/login"  element={<AuthLayout><GuestRoute allowRole="Buyer"><LoginPage  /></GuestRoute></AuthLayout>} />
      <Route path="/user/signup" element={<AuthLayout><GuestRoute allowRole="Buyer"><SignupPage /></GuestRoute></AuthLayout>} />

      {/* ── Seller Auth ───────────────────────────────────────── */}
      <Route path="/seller/login"    element={<AuthLayout><GuestRoute allowRole="Seller"><SellerLoginPage  /></GuestRoute></AuthLayout>} />
      <Route path="/seller/register" element={<AuthLayout><GuestRoute allowRole="Seller"><SellerSignupPage /></GuestRoute></AuthLayout>} />

      {/* ── Seller Protected ──────────────────────────────────── */}
      <Route path="/seller/onboarding"          element={<SellerRoute><AuthLayout><SellerOnboardingPage /></AuthLayout></SellerRoute>} />
      <Route path="/seller/dashboard"           element={<ErrorBoundary><SellerRoute><S><SellerDashboardPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/products"            element={<ErrorBoundary><SellerRoute><S><SellerProductsPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/products/new"        element={<ErrorBoundary><SellerRoute><S><SellerAddProductPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/products/:id/edit"   element={<ErrorBoundary><SellerRoute><S><SellerEditProductPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/inventory"           element={<ErrorBoundary><SellerRoute><S><SellerInventoryPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/orders/queue"        element={<ErrorBoundary><SellerRoute><S><SellerOrderQueuePage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/orders/items/:itemId/print" element={<ErrorBoundary><SellerRoute><S><PrintLabelPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/orders"              element={<ErrorBoundary><SellerRoute><S><SellerOrdersPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/profile"             element={<ErrorBoundary><SellerRoute><S><SellerProfilePage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/settlements"         element={<ErrorBoundary><SellerRoute><S><SellerSettlementsPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/settlements/:id"     element={<ErrorBoundary><SellerRoute><S><SellerSettlementDetailPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/bank-accounts"       element={<ErrorBoundary><SellerRoute><S><SellerBankAccountsPage /></S></SellerRoute></ErrorBoundary>} />
      <Route path="/seller/warehouses"          element={<ErrorBoundary><SellerRoute><S><SellerWarehousesPage /></S></SellerRoute></ErrorBoundary>} />

      {/* ── Admin Panel ───────────────────────────────────────── */}
      <Route path="/admin/dashboard" element={<ErrorBoundary><AdminRoute><S><AdminDashboardPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/sellers"   element={<ErrorBoundary><AdminRoute><S><AdminSellersPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/products"             element={<ErrorBoundary><AdminRoute><S><AdminProductsPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/products/moderation"  element={<ErrorBoundary><AdminRoute><S><AdminProductsPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/users"     element={<ErrorBoundary><AdminRoute><S><AdminUsersPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/orders"    element={<ErrorBoundary><AdminRoute><S><AdminOrdersPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/cms"       element={<ErrorBoundary><AdminRoute><S><AdminCMSPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/coupons"   element={<ErrorBoundary><AdminRoute><S><AdminCouponsPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/reviews"   element={<ErrorBoundary><AdminRoute><S><AdminReviewsPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/audit"     element={<ErrorBoundary><AdminRoute><S><AdminAuditPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/inventory" element={<ErrorBoundary><AdminRoute><S><AdminInventoryPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/categories" element={<ErrorBoundary><AdminRoute><S><AdminCategoriesPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin/complaints" element={<ErrorBoundary><AdminRoute><S><AdminComplaintsPage /></S></AdminRoute></ErrorBoundary>} />
      <Route path="/admin"           element={<Navigate to="/admin/dashboard" replace />} />

      {/* ── Dispatcher Portal ─────────────────────────────────── */}
      <Route path="/dispatch/login"   element={<AuthLayout><DispatcherLoginPage /></AuthLayout>} />
      <Route path="/dispatch/today"   element={<ErrorBoundary><DispatcherRoute><S><DispatcherTodayPage /></S></DispatcherRoute></ErrorBoundary>} />
      <Route path="/dispatch/pickups" element={<ErrorBoundary><DispatcherRoute><S><DispatcherPickupsPage /></S></DispatcherRoute></ErrorBoundary>} />
      <Route path="/dispatch/active"  element={<ErrorBoundary><DispatcherRoute><S><DispatcherActivePage /></S></DispatcherRoute></ErrorBoundary>} />
      <Route path="/dispatch"         element={<Navigate to="/dispatch/today" replace />} />

      {/* ── Public storefront ─────────────────────────────────── */}
      <Route path="/home"                   element={<MainLayout><HomePage /></MainLayout>} />
      <Route path="/home/category/:slug"    element={<MainLayout><CategoryPage /></MainLayout>} />
      <Route path="/home/products"          element={<MainLayout><ProductListPage /></MainLayout>} />
      <Route path="/home/product/:id"       element={<MainLayout><ProductDetailPage /></MainLayout>} />

      {/* ── Protected customer pages ──────────────────────────── */}
      <Route path="/user/wishlist"       element={<MainLayout><CustomerRoute><WishlistPage /></CustomerRoute></MainLayout>} />
      <Route path="/user/cart"           element={<MainLayout><BuyerOrAdminRoute><CartPage /></BuyerOrAdminRoute></MainLayout>} />
      <Route path="/user/orders"         element={<MainLayout><CustomerRoute><OrdersListPage /></CustomerRoute></MainLayout>} />
      <Route path="/user/orders/:id"     element={<MainLayout><CustomerRoute><OrderDetailPage /></CustomerRoute></MainLayout>} />
      <Route path="/user/profile"        element={<MainLayout><CustomerRoute><ProfilePage /></CustomerRoute></MainLayout>} />
      <Route path="/user/addresses"      element={<MainLayout><CustomerRoute><AddressesPage /></CustomerRoute></MainLayout>} />
      <Route path="/user/notifications"  element={<MainLayout><CustomerRoute><NotificationPage /></CustomerRoute></MainLayout>} />
      <Route path="/user/wallet"         element={<MainLayout><CustomerRoute><WalletPage /></CustomerRoute></MainLayout>} />

      {/* ── Legacy redirects (old bookmarks keep working) ─────── */}
      <Route path="/"                element={<Navigate to="/home" replace />} />
      <Route path="/login"           element={<Navigate to="/user/login" replace />} />
      <Route path="/signup"          element={<Navigate to="/user/signup" replace />} />
      <Route path="/cart"            element={<Navigate to="/user/cart" replace />} />
      <Route path="/wishlist"        element={<Navigate to="/user/wishlist" replace />} />
      <Route path="/profile"         element={<Navigate to="/user/profile" replace />} />
      <Route path="/orders"          element={<Navigate to="/user/orders" replace />} />
      <Route path="/addresses"       element={<Navigate to="/user/addresses" replace />} />
      <Route path="/notifications"   element={<Navigate to="/user/notifications" replace />} />
      <Route path="/wallet"          element={<Navigate to="/user/wallet" replace />} />
      <Route path="/products"        element={<Navigate to="/home/products" replace />} />
      <Route path="/products/:id"    element={<MainLayout><ProductDetailPage /></MainLayout>} />
      <Route path="/category/:slug"  element={<CategorySlugRedirect />} />
      <Route path="/orders/:id"      element={<OrderRedirect />} />
      <Route path="/seller/signup"   element={<Navigate to="/seller/register" replace />} />

      <Route path="*" element={<MainLayout><NotFoundPage /></MainLayout>} />
    </Routes>
    <CartDrawer />
    <AIAgentDrawer />
    <CommandPalette />
  </BrowserRouter>
);

export const AppRouterWrapper: React.FC = () => (
  <AppRouter />
);
