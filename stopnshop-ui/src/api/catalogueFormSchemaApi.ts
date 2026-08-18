import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export type ImageSlot = 'front' | 'back' | 'left' | 'right' | 'top' | 'bottom' | 'detail' | 'single';
export type SizeScale = 'apparel' | 'shoe-uk' | 'shoe-eu' | 'toy' | 'none';

export interface SubCategoryFormSchema {
  subCategoryId: number;
  subCategoryName: string;
  imageAngles: ImageSlot[];
  sizeScale: SizeScale;
  requiresGender: boolean;
  requiresDimensions: boolean;
}

export const catalogueFormSchemaApi = {
  async getFormSchema(subCategoryId: number): Promise<SubCategoryFormSchema> {
    const res = await axiosInstance.get<ApiResponse<SubCategoryFormSchema>>(
      `/catalog/subcategories/${subCategoryId}/form-schema`,
    );
    return res.data.data!;
  },
};
