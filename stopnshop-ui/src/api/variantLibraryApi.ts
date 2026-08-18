import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface VariantAttribute {
  attributeId: number;
  attributeKey: string;
  displayName: string;
  inputType: 'select' | 'swatch' | 'text';
  sortOrder: number;
  isActive: boolean;
}

export interface SubCategoryVariantOption {
  optionId: number;
  subCategoryId: number;
  attributeId: number;
  attributeKey: string;
  attributeName: string;
  inputType: 'select' | 'swatch' | 'text';
  optionValue: string;
  optionMetadata?: string | null;
  sortOrder: number;
  isActive: boolean;
}

export interface SellerVariantOption extends Omit<SubCategoryVariantOption, 'isActive'> {
  isDisabledForProduct: boolean;
}

export const variantLibraryApi = {
  async getAttributes(): Promise<VariantAttribute[]> {
    const res = await axiosInstance.get<ApiResponse<VariantAttribute[]>>('/admin/variant-library/attributes');
    return res.data.data ?? [];
  },

  async getAdminOptions(subCategoryId: number): Promise<SubCategoryVariantOption[]> {
    const res = await axiosInstance.get<ApiResponse<SubCategoryVariantOption[]>>(
      `/admin/variant-library/subcategories/${subCategoryId}/options`,
    );
    return res.data.data ?? [];
  },

  async upsertOption(payload: {
    optionId?: number | null;
    subCategoryId: number;
    attributeId: number;
    optionValue: string;
    optionMetadata?: string | null;
    sortOrder: number;
  }): Promise<number> {
    const res = await axiosInstance.post<ApiResponse<{ optionId: number }>>(
      '/admin/variant-library/options',
      payload,
    );
    return res.data.data!.optionId;
  },

  async toggleOption(optionId: number, isActive: boolean): Promise<void> {
    await axiosInstance.patch(`/admin/variant-library/options/${optionId}/toggle`, { isActive });
  },

  async deleteOption(optionId: number): Promise<void> {
    await axiosInstance.delete(`/admin/variant-library/options/${optionId}`);
  },

  async bulkSet(subCategoryId: number, attributeId: number, options: {
    optionValue: string; optionMetadata?: string | null; sortOrder: number;
  }[]): Promise<void> {
    await axiosInstance.put('/admin/variant-library/options/bulk', { subCategoryId, attributeId, options });
  },

  // Seller-facing
  async getForSubCategory(subCategoryId: number): Promise<SellerVariantOption[]> {
    const res = await axiosInstance.get<ApiResponse<SellerVariantOption[]>>(
      `/catalog/subcategories/${subCategoryId}/variant-options`,
    );
    return res.data.data ?? [];
  },

  async getForSellerProduct(productId: number, subCategoryId: number): Promise<SellerVariantOption[]> {
    const res = await axiosInstance.get<ApiResponse<SellerVariantOption[]>>(
      `/seller/products/${productId}/variant-options?subCategoryId=${subCategoryId}`,
    );
    return res.data.data ?? [];
  },

  async setDisabledForProduct(productId: number, optionIds: number[]): Promise<void> {
    await axiosInstance.put(`/seller/products/${productId}/variant-options/disabled`, { optionIds });
  },
};
