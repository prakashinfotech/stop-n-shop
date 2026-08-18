import { axiosInstance } from './axiosInstance';
import type { ApiResponse, PagedResult } from '../types/common.types';

export interface Notification {
  id: number;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: string;
  type?: string;
}

export const notificationsApi = {
  getAll: (params?: { pageNo?: number; pageSize?: number }) =>
    axiosInstance.get<ApiResponse<PagedResult<Notification>>>('/notifications', { params }),

  markRead: (id: number) =>
    axiosInstance.patch<ApiResponse<null>>(`/notifications/${id}/read`),

  markAllRead: () =>
    axiosInstance.patch<ApiResponse<null>>('/notifications/read-all'),
};
