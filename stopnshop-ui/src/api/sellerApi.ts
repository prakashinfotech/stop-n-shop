import { axiosInstance } from './axiosInstance';
import type { ApiResponse, PagedResult } from '../types/common.types';

export interface SellerAnalytics {
  fromDate: string;
  toDate: string;
  totalRevenue: number;
  totalOrders: number;
  totalUnitsSold: number;
  averageOrderValue: number;
  newOrders: number;
  processingOrders: number;
  shippedOrders: number;
  deliveredOrders: number;
  cancelledOrders: number;
}

/** Per-tab counters for the seller fulfilment queue. Drives tab badges. */
export interface SellerQueueCounts {
  placed:    number;
  confirmed: number;
  rejected:  number;
  fulfilled: number;
  all:       number;
}

// Seller auth types
interface SellerLoginRequest {
  email: string;
  password: string;
}

interface SellerSignupRequest {
  email: string;
  phoneNumber: string;
  password: string;
  confirmPassword: string;
}

interface SellerProfile {
  id: number;
  businessName?: string;
  ownerName?: string;
  email: string;
  phoneNumber: string;
  gstNumber?: string;
  address?: string;
  city?: string;
  state?: string;
  pincode?: string;
  displayName?: string;
  storeDescription?: string;
  bannerUrl?: string;
  logoUrl?: string;
  supportEmail?: string;
  supportPhone?: string;
  description?: string;
  isPhoneVerified: boolean;
  isEmailVerified: boolean;
  isIdVerified: boolean;
  onboardingCompleted: boolean;
  pickupAddressLine1?: string;
  pickupAddressLine2?: string;
  pickupCity?: string;
  pickupState?: string;
  pickupPincode?: string;
  pickupLandmark?: string;
  selectedCategories?: string;
  isActive: boolean;
  isApproved: boolean;
  createdAt: string;
  updatedAt: string;
}

interface SellerAuthResponse {
  token: string;
  expiresAt: string;
  seller: SellerProfile;
}

interface SellerSignupResponse extends SellerAuthResponse {
  phoneOtp: string;
  emailOtp: string;
}

interface SellerOnboardingRequest {
  ownerFullName: string;
  displayName: string;
  storeDescription: string;
  isPhoneVerified: boolean;
  isEmailVerified: boolean;
  isIdVerified: boolean;
  allCategories: boolean;
  selectedCategoryIds: number[];
  pickupAddressLine1: string;
  pickupAddressLine2?: string;
  pickupCity: string;
  pickupState: string;
  pickupPincode: string;
  pickupLandmark?: string;
}

// Product types
interface SellerProduct {
  id: number;
  name: string;
  mrp: number;
  sellingPrice: number;
  discountPercent: number;
  stockQuantity: number;
  lowStockThreshold: number;
  primaryImage?: string;
  isApproved: boolean;
  createdAt: string;
}

interface SellerDashboardStats {
  totalProducts: number;
  activeProducts: number;
  lowStockCount: number;
  totalOrders: number;
  totalSales: number;
}

interface CategoryOption {
  id: number;
  name: string;
}

interface SubCategoryOption {
  id: number;
  name: string;
}

export const sellerApi = {
  auth: {
    login: (data: SellerLoginRequest) =>
      axiosInstance.post<ApiResponse<SellerAuthResponse>>(
        '/seller/auth/login',
        data
      ),

    signup: (data: SellerSignupRequest) =>
      axiosInstance.post<ApiResponse<SellerSignupResponse>>(
        '/seller/auth/signup',
        data
      ),

    completeOnboarding: (data: SellerOnboardingRequest) =>
      axiosInstance.post<ApiResponse<boolean>>(
        '/seller/auth/onboarding',
        data
      ),

    getProfile: () =>
      axiosInstance.get<ApiResponse<SellerProfile>>('/seller/auth/profile'),

    updateProfile: (data: Partial<SellerProfile>) =>
      axiosInstance.put<ApiResponse<SellerProfile>>(
        '/seller/auth/profile',
        data
      ),
  },

  products: {
    getAll: (params: { page?: number; pageSize?: number; approvalStatus?: string }) =>
      axiosInstance.get<ApiResponse<PagedResult<SellerProduct>>>(
        '/seller/products',
        { params }
      ),

    getById: (id: number) =>
      axiosInstance.get(`/seller/products/${id}`),

    create: (data: any) =>
      axiosInstance.post('/seller/products', data),

    update: (id: number, data: any) =>
      axiosInstance.put(`/seller/products/${id}`, data),

    delete: (id: number) =>
      axiosInstance.delete(`/seller/products/${id}`),

    uploadImages: (files: File[]) => {
      const formData = new FormData();
      files.forEach((file) => formData.append('files', file));
      return axiosInstance.post(
        '/seller/products/images/upload',
        formData,
        { headers: { 'Content-Type': 'multipart/form-data' } }
      );
    },

    updateInventory: (productId: number, data: any) =>
      axiosInstance.patch(`/seller/products/${productId}/inventory`, data),
  },

  inventory: {
    getAll: () =>
      axiosInstance.get('/seller/inventory'),

    getLowStock: () =>
      axiosInstance.get('/seller/inventory/low-stock'),
  },

  orders: {
    getAll: (params: { page?: number; pageSize?: number; orderStatus?: string }) =>
      axiosInstance.get('/seller/orders', { params }),

    getById: (orderId: number) =>
      axiosInstance.get(`/seller/orders/${orderId}`),

    updateStatus: (orderId: number, orderStatus: string) =>
      axiosInstance.patch(`/seller/orders/${orderId}/status`, { orderStatus }),

    cancelOrder: (orderId: number, cancellationReason?: string) =>
      axiosInstance.post(`/seller/orders/${orderId}/cancel`, { cancellationReason }),

    // ── Fulfilment queue ────────────────────────────────────────────
    getQueue: (params: { status?: string; page?: number; pageSize?: number }) =>
      axiosInstance.get('/seller/orders/items', { params }),

    /** Per-tab counts for the queue. One roundtrip, safe to poll every 30s. */
    getQueueCounts: () =>
      axiosInstance.get<ApiResponse<SellerQueueCounts>>('/seller/orders/items/counts'),

    confirmItem: (orderItemId: number) =>
      axiosInstance.patch(`/seller/orders/items/${orderItemId}/confirm`),

    rejectItem: (orderItemId: number, reason: string) =>
      axiosInstance.patch(`/seller/orders/items/${orderItemId}/reject`, { reason }),

    /** Move a confirmed line one step forward.
     *  Valid newStatus values: 3=Packed, 4=Dispatched, 9=OutForDelivery, 5=Delivered.
     *  Backend enforces forward-only one-step transitions. */
    updateItemStatus: (orderItemId: number, newStatus: number) =>
      axiosInstance.patch(`/seller/orders/items/${orderItemId}/status`, { newStatus }),
  },

  analytics: {
    get: (params?: { fromDate?: string; toDate?: string }) =>
      axiosInstance.get<ApiResponse<SellerAnalytics>>('/seller/analytics', { params }),
  },

  dashboard: {
    getStats: () =>
      axiosInstance.get<ApiResponse<SellerDashboardStats>>(
        '/seller/dashboard'
      ),
  },

  catalogue: {
    getCategories: () =>
      axiosInstance.get<ApiResponse<CategoryOption[]>>(
        '/categories'
      ),

    getSubCategories: (categoryId: number) =>
      axiosInstance.get<ApiResponse<SubCategoryOption[]>>(
        `/categories/${categoryId}/subcategories`
      ),

    getBrands: () =>
      axiosInstance.get<ApiResponse<Array<{ id: number; name: string }>>>(
        '/brands'
      ),
  },
};
