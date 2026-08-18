import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface Brand {
  id: number;
  name: string;
  slug: string;
  logoUrl?: string;
}

export const brandsApi = {
  getAll: () =>
    axiosInstance.get<ApiResponse<Brand[]>>('/brands'),
};
