import React, { useCallback } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Truck, Package, ClipboardList, LogOut, MapPin } from 'lucide-react';
import { useAuthContext } from '../../context/AuthContext';
import { dispatcherApi } from '../../api/dispatcherApi';

/**
 * Mobile-first dispatcher portal layout. Bottom-tab navigation on small
 * screens (easier one-handed use), top-aligned brand strip with profile
 * chip + logout.
 *
 * Three pages today: Today (dashboard), Pickups, Active Routes.
 */
const navItems = [
  { path: '/dispatch/today',   icon: Truck,         label: 'Today' },
  { path: '/dispatch/pickups', icon: Package,       label: 'Pickups' },
  { path: '/dispatch/active',  icon: ClipboardList, label: 'Active' },
];

interface DispatcherLayoutProps { children: React.ReactNode; }

export const DispatcherLayout: React.FC<DispatcherLayoutProps> = ({ children }) => {
  const navigate = useNavigate();
  const { logout } = useAuthContext();

  const { data: profile } = useQuery({
    queryKey: ['dispatcher-profile'],
    queryFn: () => dispatcherApi.getProfile().then((r) => r.data.data),
    staleTime: 5 * 60 * 1000,
  });

  const handleLogout = useCallback(() => {
    logout();
    navigate('/dispatch/login');
  }, [logout, navigate]);

  return (
    <div className="min-h-screen bg-bg flex flex-col">
      {/* Brand bar */}
      <header className="sticky top-0 z-30 bg-stone-900 text-white px-4 sm:px-6 py-3 flex items-center justify-between shadow-md">
        <div className="flex items-center gap-3 min-w-0">
          <Truck className="h-5 w-5 text-brand-400 flex-shrink-0" />
          <div className="min-w-0">
            <p className="font-display text-base font-bold leading-tight truncate">
              Stop<span className="text-brand-400">N</span>Ship
            </p>
            <p className="text-[10px] uppercase tracking-widest text-stone-400 leading-tight">
              Dispatcher
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          {profile && (
            <div className="hidden sm:flex flex-col items-end text-right">
              <span className="text-sm font-medium">{profile.firstName ?? 'Dispatcher'}</span>
              <span className="text-[10px] text-stone-400 font-mono">{profile.employeeCode}</span>
            </div>
          )}
          <button
            onClick={handleLogout}
            aria-label="Sign out"
            className="p-2 rounded-lg text-stone-300 hover:text-white hover:bg-white/10 transition-colors"
            title="Sign out"
          >
            <LogOut className="h-4 w-4" />
          </button>
        </div>
      </header>

      {/* Desktop side tabs + content */}
      <div className="flex-1 flex">
        <aside className="hidden md:flex md:flex-col w-56 bg-surface-elevated border-r border-outline/60 p-4 gap-1">
          {navItems.map(({ path, icon: Icon, label }) => (
            <NavLink
              key={path}
              to={path}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-colors ${
                  isActive
                    ? 'bg-brand-50 text-brand-600 font-medium'
                    : 'text-content-muted hover:text-content hover:bg-surface'
                }`
              }
            >
              <Icon size={16} />
              <span>{label}</span>
            </NavLink>
          ))}

          {profile?.assignedWarehousesLabel && (
            <div className="mt-auto pt-4 border-t border-outline/60">
              <p className="text-[10px] uppercase tracking-widest text-content-subtle mb-1">
                Warehouses
              </p>
              <p className="text-xs text-content leading-snug flex items-start gap-1">
                <MapPin className="h-3 w-3 mt-0.5 flex-shrink-0 text-brand-500" />
                {profile.assignedWarehousesLabel}
              </p>
            </div>
          )}
        </aside>

        <main className="flex-1 p-4 sm:p-6 pb-24 md:pb-6 max-w-5xl mx-auto w-full">
          {children}
        </main>
      </div>

      {/* Mobile bottom tab bar */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-surface-elevated border-t border-outline/60 z-30 grid grid-cols-3 shadow-soft-lg">
        {navItems.map(({ path, icon: Icon, label }) => (
          <NavLink
            key={path}
            to={path}
            className={({ isActive }) =>
              `flex flex-col items-center gap-1 py-3 text-[11px] font-medium transition-colors ${
                isActive ? 'text-brand-600' : 'text-content-muted'
              }`
            }
          >
            <Icon size={20} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>
    </div>
  );
};
