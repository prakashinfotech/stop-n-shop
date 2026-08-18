import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export type ComplaintCategory = 'delivery' | 'product' | 'payment' | 'account' | 'other';

export interface CreateComplaintPayload {
  category: ComplaintCategory;
  subject: string;
  body: string;
  orderId?: number | null;
  source?: 'aria' | 'web' | 'support';
}

export interface ComplaintRow {
  complaintId: number;
  orderId?: number | null;
  orderNumber?: string | null;
  category: ComplaintCategory;
  subject: string;
  body: string;
  status: number;
  adminNote?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminComplaintRow extends ComplaintRow {
  userId: number;
  userName?: string | null;
  userEmail?: string | null;
  source: string;
}

export const complaintsApi = {
  create: (payload: CreateComplaintPayload) =>
    axiosInstance.post<ApiResponse<{ complaintId: number }>>('/complaints', payload),

  mine: (page = 1, pageSize = 20) =>
    axiosInstance.get<ApiResponse<{ items: ComplaintRow[]; totalCount: number }>>(
      '/complaints/mine',
      { params: { page, pageSize } },
    ),

  adminList: (params?: { status?: number; category?: string; search?: string; page?: number; pageSize?: number }) =>
    axiosInstance.get<ApiResponse<{ items: AdminComplaintRow[]; totalCount: number }>>(
      '/admin/complaints',
      { params },
    ),

  adminUpdate: (id: number, payload: { status: number; adminNote?: string }) =>
    axiosInstance.patch<ApiResponse<null>>(`/admin/complaints/${id}`, payload),
};

export const COMPLAINT_STATUS_LABEL: Record<number, string> = {
  1: 'Open',
  2: 'In progress',
  3: 'Resolved',
  4: 'Closed',
};
