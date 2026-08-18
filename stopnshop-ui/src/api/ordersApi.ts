import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';
import type { Order, OrderDetail, PlaceOrderRequest } from '../types/cart.types';

export const ordersApi = {
  placeOrder: (data: PlaceOrderRequest) =>
    axiosInstance.post<ApiResponse<{ orderId: number }>>('/orders', data),

  getOrders: () =>
    axiosInstance.get<ApiResponse<Order[]>>('/orders'),

  getOrderDetail: (id: number) =>
    axiosInstance.get<ApiResponse<OrderDetail>>(`/orders/${id}`),

  cancelOrder: (id: number, reason: string) =>
    axiosInstance.delete<ApiResponse<OrderDetail>>(`/orders/${id}`, { data: { reason } }),
};
