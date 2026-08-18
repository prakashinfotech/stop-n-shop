import React, { useState } from 'react';
import { Heart } from 'lucide-react';
import { useAuthContext } from '../../context/AuthContext';
import { usePreviewMode } from '../../hooks/usePreviewMode';
import { AuthModal } from '../auth/AuthModal';

interface ProtectedWishlistButtonProps {
  productId: number;
  isWishlisted: boolean;
  onToggle: (productId: number) => void;
  isLoading?: boolean;
  size?: 'sm' | 'md';
  className?: string;
}

export const ProtectedWishlistButton: React.FC<ProtectedWishlistButtonProps> = ({
  productId,
  isWishlisted,
  onToggle,
  isLoading = false,
  size = 'md',
  className = '',
}) => {
  const { isAuthenticated } = useAuthContext();
  const previewMode = usePreviewMode();
  const [showAuthModal, setShowAuthModal] = useState(false);

  const iconSize = size === 'sm' ? 'h-4 w-4' : 'h-5 w-5';

  const handleClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (previewMode) return;          // admin preview — no-op
    if (!isAuthenticated) {
      setShowAuthModal(true);
      return;
    }
    onToggle(productId);
  };

  return (
    <>
      <button
        type="button"
        onClick={handleClick}
        disabled={isLoading || previewMode}
        title={previewMode ? 'Preview mode — not available for admins' : undefined}
        aria-label={isWishlisted ? 'Remove from wishlist' : 'Add to wishlist'}
        className={`transition-all disabled:opacity-50 ${previewMode ? 'cursor-not-allowed' : ''} ${className}`}
      >
        <Heart
          className={`${iconSize} transition-all ${
            isWishlisted
              ? 'fill-red-500 stroke-red-500'
              : 'stroke-content-muted hover:stroke-red-500'
          }`}
        />
      </button>

      <AuthModal
        open={showAuthModal}
        onClose={() => setShowAuthModal(false)}
        returnMessage="Sign in to save items to your wishlist"
      />
    </>
  );
};
