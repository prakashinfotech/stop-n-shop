import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Users, Package, ShieldCheck, Boxes,
  ClipboardList, Image, Star, Settings, Tag, FileClock, FolderTree, MessageSquare,
} from 'lucide-react';
import { useAuthContext } from '../../context/AuthContext';
import { SellerHeader } from '../layout/SellerHeader';
import { UserMenu, UserMenuItem } from '../ui/UserMenu';

const NAV_ITEMS = [
  { to: '/admin/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/admin/sellers',   icon: Users,           label: 'Sellers' },
  { to: '/admin/products',  icon: Package,         label: 'Products' },
  { to: '/admin/products/moderation', icon: ShieldCheck, label: 'Moderation' },
  { to: '/admin/categories', icon: FolderTree,      label: 'Categories' },
  { to: '/admin/inventory', icon: Boxes,           label: 'Inventory' },
  { to: '/admin/users',     icon: Users,           label: 'Users' },
  { to: '/admin/orders',    icon: ClipboardList,   label: 'Orders' },
  { to: '/admin/cms',       icon: Image,           label: 'CMS / Banners' },
  { to: '/admin/coupons',   icon: Tag,             label: 'Coupons' },
  { to: '/admin/reviews',   icon: Star,            label: 'Reviews' },
  { to: '/admin/complaints', icon: MessageSquare,  label: 'Complaints' },
  { to: '/admin/audit',     icon: FileClock,       label: 'Audit Trail' },
];

export const AdminLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuthContext();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const displayName = user?.firstName ?? user?.name ?? 'Admin';
  const menuItems: UserMenuItem[] = [
    { to: '/admin/dashboard', label: 'Settings', icon: <Settings className="h-4 w-4" /> },
  ];

  return (
    <div className="min-h-screen bg-bg">
      <SellerHeader
        badge="Admin Console"
        rightContent={
          <UserMenu
            name={displayName}
            email={user?.email}
            items={menuItems}
            onLogout={handleLogout}
          />
        }
      />

      <div className="flex">
        <aside className="w-64 bg-bg border-r border-outline/60 h-[calc(100vh-4rem)] flex flex-col fixed left-0 top-16">
          <nav className="flex-1 p-4 space-y-0.5">
            {NAV_ITEMS.map(({ to, icon: Icon, label }) => {
              // Longest-prefix wins so `/admin/products/moderation` only highlights Moderation
              const matches = NAV_ITEMS.filter((n) => pathname.startsWith(n.to));
              const best = matches.reduce((a, b) => (b.to.length > a.to.length ? b : a), matches[0] ?? { to: '' });
              const active = best.to === to;
              return (
                <Link
                  key={to}
                  to={to}
                  className={`flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm transition-colors ${
                    active
                      ? 'bg-brand-50 text-brand-600 font-medium'
                      : 'text-content-muted hover:text-content hover:bg-surface'
                  }`}
                >
                  <Icon className="h-[18px] w-[18px] flex-shrink-0" />
                  <span>{label}</span>
                </Link>
              );
            })}
          </nav>
        </aside>

        <main className="flex-1 ml-64 pt-8 pb-16 px-8">
          <div className="max-w-6xl mx-auto">{children}</div>
        </main>
      </div>
    </div>
  );
};
