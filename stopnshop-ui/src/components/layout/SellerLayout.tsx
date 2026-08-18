import React, { useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Settings } from 'lucide-react';
import { useAuthContext } from '../../context/AuthContext';
import { sellerApi } from '../../api/sellerApi';
import { usePendingOrderNudge } from '../../hooks/usePendingOrderNudge';
import { SellerHeader } from './SellerHeader';
import { SellerSidebar } from './SellerSidebar';
import { UserMenu, UserMenuItem } from '../ui/UserMenu';

interface SellerLayoutProps {
  children: React.ReactNode;
}

export const SellerLayout: React.FC<SellerLayoutProps> = ({ children }) => {
  const navigate = useNavigate();
  const { user, logout } = useAuthContext();

  const { data: profile } = useQuery({
    queryKey: ['seller-profile'],
    queryFn: () => sellerApi.auth.getProfile().then((r) => r.data.data),
    staleTime: 5 * 60 * 1000,
  });

  // Proactive Aria: watches pending order counts and fires a nudge into the
  // drawer when there's work to do. Self-contained — see hook for fire rules.
  usePendingOrderNudge();

  const email = profile?.email || user?.email;
  const displayName =
    profile?.businessName ||
    profile?.ownerName ||
    user?.firstName ||
    user?.name ||
    'Seller';

  const handleLogout = useCallback(() => {
    logout();
    navigate('/seller/login');
  }, [logout, navigate]);

  const menuItems: UserMenuItem[] = [
    { to: '/seller/profile', label: 'Settings', icon: <Settings className="h-4 w-4" /> },
  ];

  return (
    <div className="min-h-screen bg-bg">
      <SellerHeader
        badge="Seller Center"
        rightContent={
          <UserMenu
            name={displayName}
            email={email}
            items={menuItems}
            onLogout={handleLogout}
          />
        }
      />

      <div className="flex">
        <SellerSidebar />

        <main className="flex-1 ml-64 pt-8 pb-16 px-8">
          <div className="max-w-6xl mx-auto">{children}</div>
        </main>
      </div>
    </div>
  );
};
