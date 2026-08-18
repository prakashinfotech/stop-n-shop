import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';
import type { CartDto, AddToCartRequest } from '../types/cart.types';

export const cartApi = {
  getCart: () =>
    axiosInstance.get<ApiResponse<CartDto>>('/cart'),

  addToCart: (data: AddToCartRequest) =>
    axiosInstance.post<ApiResponse<{ cartId: number }>>('/cart', data),

  updateCart: (cartId: number, quantity: number) =>
    axiosInstance.put<ApiResponse<{ updated: boolean }>>(`/cart/${cartId}`, { quantity }),

  deleteCartItem: (cartId: number) =>
    axiosInstance.delete<ApiResponse<null>>(`/cart/${cartId}`),
};
