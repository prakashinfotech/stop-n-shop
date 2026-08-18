import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface RazorpayOrderResponse {
  orderId: string;
  amount: number;
  currency: string;
  keyId: string;
}

export const paymentsApi = {
  createRazorpayOrder: (amount: number) =>
    axiosInstance.post<ApiResponse<RazorpayOrderResponse>>('/payments/razorpay/create-order', { amount }),
};
