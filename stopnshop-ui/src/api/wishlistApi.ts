import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';
import type { WishlistItem } from '../types/cart.types';

export const wishlistApi = {
  getWishlist: () =>
    axiosInstance.get<ApiResponse<WishlistItem[]>>('/wishlist'),

  toggleWishlist: (productId: number) =>
    axiosInstance.post<ApiResponse<{ isWishlisted: boolean }>>(`/wishlist/${productId}`),
};
