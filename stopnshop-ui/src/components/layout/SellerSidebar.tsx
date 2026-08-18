import React from 'react';
import { NavLink } from 'react-router-dom';
import { BarChart3, Package, Boxes, ShoppingCart, User, Wallet, Landmark, Warehouse, ClipboardCheck } from 'lucide-react';

const navItems = [
  { path: '/seller/dashboard', icon: BarChart3, label: 'Dashboard' },
  { path: '/seller/products', icon: Package, label: 'Products' },
  { path: '/seller/inventory', icon: Boxes, label: 'Inventory' },
  { path: '/seller/orders/queue', icon: ClipboardCheck, label: 'Fulfilment Queue' },
  { path: '/seller/orders', icon: ShoppingCart, label: 'Orders History' },
  { path: '/seller/settlements', icon: Wallet, label: 'Settlements' },
  { path: '/seller/bank-accounts', icon: Landmark, label: 'Bank Accounts' },
  { path: '/seller/warehouses', icon: Warehouse, label: 'Warehouses' },
  { path: '/seller/profile', icon: User, label: 'Profile' },
];

export const SellerSidebar: React.FC = () => (
  <aside className="w-64 bg-bg border-r border-outline/60 h-[calc(100vh-4rem)] flex flex-col fixed left-0 top-16">
    <nav className="flex-1 p-4 space-y-0.5">
      {navItems.map(({ path, icon: Icon, label }) => (
        <NavLink
          key={path}
          to={path}
          // `end` forces exact-path matching so /seller/orders doesn't light
          // up when the user is on /seller/orders/queue or /seller/orders/items/.../print.
          // Other items are leaf routes so the default startsWith behaviour is fine.
          end={path === '/seller/orders'}
          className={({ isActive }) =>
            `flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm transition-colors ${
              isActive
                ? 'bg-brand-50 text-brand-600 font-medium'
                : 'text-content-muted hover:text-content hover:bg-surface'
            }`
          }
        >
          <Icon size={18} />
          <span>{label}</span>
        </NavLink>
      ))}
    </nav>
  </aside>
);
