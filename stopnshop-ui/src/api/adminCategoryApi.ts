import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface AdminCategory {
  categoryId: number;
  menuId: number;
  menuName?: string | null;
  categoryName: string;
  slugUrl: string;
  iconUrl?: string | null;
  bannerUrl?: string | null;
  sortOrder: number;
  isFeatured: boolean;
  showInMegaMenu: boolean;
  isActive: boolean;
  metaTitle?: string | null;
  metaDescription?: string | null;
  subCategoryCount: number;
  productCount: number;
}

export interface AdminSubCategory {
  subCategoryId: number;
  categoryId: number;
  subCategoryName: string;
  slugUrl: string;
  iconUrl?: string | null;
  sortOrder: number;
  isFeatured: boolean;
  showInMegaMenu: boolean;
  isActive: boolean;
  metaTitle?: string | null;
  metaDescription?: string | null;
  productCount: number;
}

export interface AdminMegaMenuTree {
  categories: AdminCategory[];
  subCategories: AdminSubCategory[];
}

export interface CategoryUpsertPayload {
  categoryId?: number | null;
  menuId: number;
  categoryName: string;
  slugUrl: string;
  iconUrl?: string | null;
  bannerUrl?: string | null;
  sortOrder: number;
  isFeatured: boolean;
  showInMegaMenu: boolean;
  metaTitle?: string | null;
  metaDescription?: string | null;
}

export interface SubCategoryUpsertPayload {
  subCategoryId?: number | null;
  categoryId: number;
  subCategoryName: string;
  slugUrl: string;
  iconUrl?: string | null;
  sortOrder: number;
  isFeatured: boolean;
  showInMegaMenu: boolean;
  metaTitle?: string | null;
  metaDescription?: string | null;
}

export interface ToggleVisibilityPayload {
  isActive?: boolean | null;
  showInMegaMenu?: boolean | null;
}

export const adminCategoryApi = {
  async getTree(includeInactive = true): Promise<AdminMegaMenuTree> {
    const res = await axiosInstance.get<ApiResponse<AdminMegaMenuTree>>(
      `/admin/categories/tree?includeInactive=${includeInactive}`,
    );
    return res.data.data!;
  },

  async upsertCategory(payload: CategoryUpsertPayload): Promise<number> {
    const res = await axiosInstance.post<ApiResponse<{ categoryId: number }>>(
      '/admin/categories',
      payload,
    );
    return res.data.data!.categoryId;
  },

  async toggleCategory(id: number, payload: ToggleVisibilityPayload): Promise<void> {
    await axiosInstance.patch(`/admin/categories/${id}/toggle`, payload);
  },

  async reorderCategories(items: { categoryId: number; sortOrder: number }[]): Promise<void> {
    await axiosInstance.patch('/admin/categories/reorder', { items });
  },

  async deleteCategory(id: number): Promise<void> {
    await axiosInstance.delete(`/admin/categories/${id}`);
  },

  async upsertSubCategory(payload: SubCategoryUpsertPayload): Promise<number> {
    const res = await axiosInstance.post<ApiResponse<{ subCategoryId: number }>>(
      '/admin/categories/subcategories',
      payload,
    );
    return res.data.data!.subCategoryId;
  },

  async toggleSubCategory(id: number, payload: ToggleVisibilityPayload): Promise<void> {
    await axiosInstance.patch(`/admin/categories/subcategories/${id}/toggle`, payload);
  },

  async reorderSubCategories(items: { subCategoryId: number; sortOrder: number }[]): Promise<void> {
    await axiosInstance.patch('/admin/categories/subcategories/reorder', { items });
  },

  async deleteSubCategory(id: number): Promise<void> {
    await axiosInstance.delete(`/admin/categories/subcategories/${id}`);
  },

  async updateFormRules(subCategoryId: number, payload: {
    imageAngles: string[];
    sizeScale: string;
    requiresGender: boolean;
    requiresDimensions: boolean;
  }): Promise<void> {
    await axiosInstance.patch(`/admin/categories/subcategories/${subCategoryId}/form-rules`, payload);
  },

  async getFormSchema(subCategoryId: number): Promise<{
    subCategoryId: number;
    subCategoryName: string;
    imageAngles: string[];
    sizeScale: string;
    requiresGender: boolean;
    requiresDimensions: boolean;
  }> {
    const res = await axiosInstance.get(`/catalog/subcategories/${subCategoryId}/form-schema`);
    return res.data.data;
  },
};
