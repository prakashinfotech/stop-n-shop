import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export const engagementApi = {
  /** Signed-in user's recent search terms; returns [] for unauthenticated callers. */
  getRecentSearches: (count = 6) =>
    axiosInstance.get<ApiResponse<string[]>>('/engagement/recent-searches', { params: { count } }),
};
