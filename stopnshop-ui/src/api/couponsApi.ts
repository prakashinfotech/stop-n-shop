import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface CouponValidateResponse {
  isValid: boolean;
  discountAmount: number;
  discountType: 'FLAT' | 'PERCENT';
  message: string;
  couponCode: string;
}

export interface AdminCoupon {
  couponId: number;
  couponCode: string;
  isActive: boolean;
  offerId: number;
  offerName: string;
  offerType: number;          // 1=Flat, 2=Percentage
  discountValue: number;
  minOrderValue: number;
  maxDiscountCap: number | null;
  startDate: string;
  endDate: string;
  applicableOn: number;       // 1=Product, 2=Brand, 3=Category, 4=Cart
  entityId: number | null;
  brandName: string | null;
  usageLimitPerUser: number;
  currentUsageCount: number;
  createdAt: string;
}

export interface CreateCouponRequest {
  couponCode: string;
  offerName: string;
  offerType: number;
  discountValue: number;
  minOrderValue: number;
  maxDiscountCap: number | null;
  startDate: string;
  endDate: string;
  applicableOn: number;
  entityId: number | null;
  usageLimitPerUser: number;
}

export interface AvailableCoupon {
  couponId: number;
  couponCode: string;
  offerName: string;
  offerType: number;          // 1=Flat, 2=Percentage
  discountValue: number;
  minOrderValue: number;
  maxDiscountCap: number | null;
  applicableOn: number;
  entityId: number | null;
  brandName: string | null;
  startDate: string;
  endDate: string;
  usageLimitPerUser: number;
  usedByUser: number;
  isExhausted: boolean;
}

export const couponsApi = {
  validate: (code: string, cartTotal: number) =>
    axiosInstance.post<ApiResponse<CouponValidateResponse>>('/coupons/validate', {
      couponCode: code,
      cartTotal,
    }),

  available: () =>
    axiosInstance.get<ApiResponse<AvailableCoupon[]>>('/coupons/available'),

  // ── Admin ────────────────────────────────────────────────────────────────
  adminList: (page = 1, pageSize = 50) =>
    axiosInstance.get<ApiResponse<{ items: AdminCoupon[]; totalCount: number; page: number; pageSize: number }>>(
      '/admin/coupons',
      { params: { page, pageSize } }
    ),
  adminCreate: (body: CreateCouponRequest) =>
    axiosInstance.post<ApiResponse<{ couponId: number }>>('/admin/coupons', body),
  adminToggle: (id: number, isActive: boolean) =>
    axiosInstance.patch<ApiResponse<null>>(`/admin/coupons/${id}/toggle`, { isActive }),
};
