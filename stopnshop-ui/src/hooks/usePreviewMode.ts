import { useAuthContext } from '../context/AuthContext';

/**
 * Returns true when an authenticated Admin is browsing the storefront.
 * The admin sees the buyer experience read-only — no cart actions, no
 * wishlist, no checkout, no personal nav. Every storefront component that
 * needs to gate a buyer-only feature should consume this hook.
 */
export const usePreviewMode = (): boolean => {
  const { user } = useAuthContext();
  return user?.role === 'Admin';
};
