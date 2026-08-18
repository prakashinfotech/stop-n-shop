import { axiosInstance } from './axiosInstance';
import type { ApiResponse, PagedResult } from '../types/common.types';

export interface AdminStats {
  totalUsers: number;
  totalBuyers?: number;
  totalSellers: number;
  totalProducts: number;
  totalOrders: number;
  totalRevenue: number;
  pendingSellerApprovals: number;
  pendingProductApprovals: number;
  unfulfilledOrders?: number;
  rejectedOrderItems?: number;
}

export interface AdminSeller {
  id: number;
  businessName: string;
  ownerName: string;
  email: string;
  phoneNumber: string;
  isApproved: boolean;
  isActive: boolean;
  createdAt: string;
}

export interface AdminProduct {
  id: number;
  name: string;
  sellerName: string;
  sellingPrice: number;
  mrp: number;
  isApproved: boolean;
  primaryImage?: string;
  createdAt: string;
}

export interface AdminUser {
  id: number;
  name?: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  mobile: string;
  role: string;
  createdAt: string;
}

export interface AdminOrder {
  id: number;
  orderNumber: string;
  customerName: string;
  sellerName: string;
  status: string;
  finalAmount: number;
  createdAt: string;
}

export interface AdminReview {
  id: number;
  productName: string;
  reviewerName: string;
  rating: number;
  comment: string;
  isApproved: boolean;
  createdAt: string;
}

export interface AdminAuditEntry {
  auditId: number;
  tableName: string;
  recordId: number;
  action: string;
  oldValues?: string | null;
  newValues?: string | null;
  changedBy?: number | null;
  changedAt: string;
  ipAddress?: string | null;
  changedByEmail?: string | null;
  changedByName: string;
}

export interface AdminSellerScore {
  sellerId: number;
  fromDate: string;
  toDate: string;
  totalOrders: number;
  deliveredOrders: number;
  cancelledOrders: number;
  gmv: number;
  averageRating: number;
  reviewCount: number;
  deliveryRatePct: number;
  cancellationRatePct: number;
}

export interface UpdateCouponPayload {
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

export interface CmsBanner {
  bannerId?: number;
  title: string;
  subTitle?: string;
  imageUrl: string;
  mobileImageUrl?: string;
  linkUrl?: string;
  section: number;
  sortOrder: number;
  /** Vertical gap (px) the CMS author wants below this banner in the home stack. */
  gapBelowPx?: number;
  /** Optional surface colour rendered behind this banner. */
  backgroundColor?: string | null;
  isActive: boolean;
  startDate?: string;
  endDate?: string;
  createdAt?: string;
  updatedAt?: string;
}

export const adminApi = {
  dashboard: {
    getStats: () =>
      axiosInstance.get<ApiResponse<AdminStats>>('/admin/dashboard'),
  },

  sellers: {
    getAll: (params?: { pageNo?: number; pageSize?: number; approvalStatus?: number; search?: string }) =>
      axiosInstance.get<ApiResponse<PagedResult<AdminSeller>>>('/admin/sellers', { params }),
    approve: (id: number) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/sellers/${id}/approve`),
    reject: (id: number, reason?: string) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/sellers/${id}/reject`, { reason }),
    suspend: (id: number) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/sellers/${id}/suspend`),
    getScore: (id: number, params?: { from?: string; to?: string }) =>
      axiosInstance.get<ApiResponse<AdminSellerScore>>(`/admin/sellers/${id}/score`, { params }),
  },

  products: {
    getAll: (params?: { pageNo?: number; pageSize?: number }) =>
      axiosInstance.get<ApiResponse<PagedResult<AdminProduct>>>('/admin/products', { params }),
    moderationQueue: (params?: { pageNo?: number; pageSize?: number }) =>
      axiosInstance.get<ApiResponse<PagedResult<AdminProduct>>>('/admin/products/moderation-queue', { params }),
    approve: (id: number) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/products/${id}/approve`),
    reject: (id: number, reason?: string) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/products/${id}/reject`, { reason }),
  },

  users: {
    getAll: (params?: { pageNo?: number; pageSize?: number; role?: string }) =>
      axiosInstance.get<ApiResponse<PagedResult<AdminUser>>>('/admin/users', { params }),
    suspend: (id: number, reason?: string) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/users/${id}/suspend`, { reason }),
    activate: (id: number) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/users/${id}/activate`),
    softDelete: (id: number) =>
      axiosInstance.delete<ApiResponse<null>>(`/admin/users/${id}`),
  },

  orders: {
    getAll: (params?: {
      pageNo?: number;
      pageSize?: number;
      status?: number;
      search?: string;
      lineStatus?: 'unfulfilled' | 'rejected';
      paymentStatus?: 'paid' | 'unpaid' | 'refunded';
    }) =>
      axiosInstance.get<ApiResponse<PagedResult<AdminOrder>>>('/admin/orders', { params }),
    forceCancel: (id: number, reason: string) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/orders/${id}/force-cancel`, { reason }),
    refund: (id: number, refundAmount: number, reason: string, gatewayRef?: string) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/orders/${id}/refund`, { refundAmount, reason, gatewayRef }),
  },

  coupons: {
    update: (id: number, payload: UpdateCouponPayload) =>
      axiosInstance.put<ApiResponse<null>>(`/admin/coupons/${id}`, payload),
    remove: (id: number) =>
      axiosInstance.delete<ApiResponse<null>>(`/admin/coupons/${id}`),
  },

  audit: {
    query: (params?: {
      tableName?: string;
      recordId?: number;
      changedBy?: number;
      from?: string;
      to?: string;
      pageNo?: number;
      pageSize?: number;
    }) =>
      axiosInstance.get<ApiResponse<PagedResult<AdminAuditEntry>>>('/admin/audit', { params }),
  },

  reviews: {
    getAll: (params?: { pageNo?: number; pageSize?: number }) =>
      axiosInstance.get<ApiResponse<PagedResult<AdminReview>>>('/admin/reviews', { params }),
    approve: (id: number) =>
      axiosInstance.patch<ApiResponse<null>>(`/admin/reviews/${id}/approve`),
  },

  cms: {
    getBanners: () =>
      axiosInstance.get<ApiResponse<CmsBanner[]>>('/admin/cms/banners'),
    upsertBanner: (data: Partial<CmsBanner>) =>
      axiosInstance.post<ApiResponse<{ BannerId: number }>>('/admin/cms/banners', data),
    deleteBanner: (id: number) =>
      axiosInstance.delete<ApiResponse<null>>(`/admin/cms/banners/${id}`),
    uploadImage: (file: File) => {
      const formData = new FormData();
      formData.append('file', file);
      return axiosInstance.post<ApiResponse<{ ImageUrl: string }>>('/admin/cms/banners/upload-image', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    },
  },
};
