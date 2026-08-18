import { axiosInstance } from './axiosInstance';
import type { ApiResponse, PagedResult } from '../types/common.types';
import type { ProductListItem, ProductDetail, ProductQueryParams } from '../types/product.types';

export const productsApi = {
  getProducts: (params: ProductQueryParams) =>
    axiosInstance.get<ApiResponse<PagedResult<ProductListItem>>>('/products', { params }),

  getProductDetail: (id: number) =>
    axiosInstance.get<ApiResponse<ProductDetail>>(`/products/${id}`),

  getSimilar: (id: number) =>
    axiosInstance.get<ApiResponse<ProductListItem[]>>(`/products/${id}/similar`),

  getRecommended: (productIds: number[]) =>
    axiosInstance.get<ApiResponse<ProductListItem[]>>('/products/recommended', {
      params: { productIds: productIds.join(',') },
    }),

  getMasterOffers: () =>
    axiosInstance.get<ApiResponse<OffersMaster>>('/products/offers/master'),

  /** Trending products — rolling-window view count from ProductViewLogs. */
  getTrending: (days = 7, limit = 12) =>
    axiosInstance.get<ApiResponse<ProductListItem[]>>('/products/trending', {
      params: { days, limit },
    }),
};

export interface MasterCoupon {
  code: string;
  name: string;
  offerType: number;       // 1=Flat, 2=Percentage, 3=BOGO
  discountValue: number;
  minOrderValue: number;
  maxDiscount?: number | null;
  endsAt: string;
}

export interface BankOffer {
  id: number;
  title: string;
  description?: string | null;
  minSpend?: number | null;
  maxDiscount?: number | null;
  termsUrl?: string | null;
}

export interface OffersMaster {
  coupons: MasterCoupon[];
  bankOffers: BankOffer[];
}
