import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';
import type { MegaMenuCategory, Banner, Store, PincodeDelivery, FeaturedSubCategory } from '../types/catalogue.types';

export const catalogueApi = {
  getMegaMenu: () =>
    axiosInstance.get<ApiResponse<MegaMenuCategory[]>>('/menu'),

  /** Admin-curated subcategories flagged IsFeatured=1 for the home tile grid. */
  getFeaturedSubCategories: (count = 10) =>
    axiosInstance.get<ApiResponse<FeaturedSubCategory[]>>('/subcategories/featured', { params: { count } }),

  getBanners: (section: number) =>
    axiosInstance.get<ApiResponse<Banner[]>>('/banners', { params: { section } }),

  /** Every active promotional banner (BannerType 2..7) in one ordered list for the home stack. */
  getBannerStack: () =>
    axiosInstance.get<ApiResponse<Banner[]>>('/banners/stack'),

  getStores: (city?: string) =>
    axiosInstance.get<ApiResponse<Store[]>>('/stores', { params: city ? { city } : undefined }),

  checkPincode: (pin: string) =>
    axiosInstance.get<ApiResponse<PincodeDelivery>>(`/pincode/${pin}`),
};
