import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface DispatcherProfile {
  dispatcherId:            number;
  userId:                  number;
  employeeCode:            string;
  vehicleNumber?:          string | null;
  vehicleType?:            string | null;
  licenseNumber?:          string | null;
  baseWarehouseId?:        number | null;
  baseWarehouseName?:      string | null;
  firstName?:              string | null;
  lastName?:               string | null;
  email?:                  string | null;
  mobile?:                 string | null;
  joinedAt:                string;
  isActive:                boolean;
  assignedWarehousesLabel?: string | null;
}

export interface DispatcherQueueItem {
  orderItemId:        number;
  orderId:            number;
  orderNumber:        string;
  productName:        string;
  variantSnapshot?:   string | null;
  quantity:           number;
  totalPrice:         number;
  orderStatus:        number;    // 3 = claimable, 10 = already claimed by me
  orderItemCreatedAt: string;
  warehouseId:        number;
  warehouseCode?:     string | null;
  warehouseName?:     string | null;
  warehouseCity?:     string | null;
  paymentMode:        number;
  paymentStatus:      number;
  codAmount?:         number | null;
  buyerName?:         string | null;
  buyerMobile?:       string | null;
  buyerAddressLine1?: string | null;
  buyerCity?:         string | null;
  buyerState?:        string | null;
  buyerPincode?:      string | null;
  assignmentId?:      number | null;
  assignmentStatus?:  number | null;
}

export interface DispatcherAssignment {
  assignmentId:       number;
  assignmentStatus:   number;
  assignedAt:         string;
  pickedUpAt?:        string | null;
  outForDeliveryAt?:  string | null;
  attemptNumber:      number;
  codAmount?:         number | null;
  orderItemId:        number;
  orderId:            number;
  orderNumber:        string;
  productName:        string;
  variantSnapshot?:   string | null;
  quantity:           number;
  totalPrice:         number;
  orderStatus:        number;
  warehouseCode?:     string | null;
  warehouseName?:     string | null;
  buyerName?:         string | null;
  buyerMobile?:       string | null;
  buyerAddressLine1?: string | null;
  buyerCity?:         string | null;
  buyerState?:        string | null;
  buyerPincode?:      string | null;
  paymentMode:        number;
  paymentStatus:      number;
}

export interface PagedDispatcherResult<T> {
  items: T[];
  totalCount: number;
  pageNo: number;
  pageSize: number;
}

export const dispatcherApi = {
  auth: {
    /** POST /api/auth/dispatcher/login — returns { token, expiresAt, user } */
    login: (email: string, password: string) =>
      axiosInstance.post<ApiResponse<{
        token: string;
        expiresAt: string;
        user: { id: number; email: string; firstName?: string; lastName?: string; mobile: string; role: string };
      }>>('/auth/dispatcher/login', { email, password }),
  },

  getProfile: () =>
    axiosInstance.get<ApiResponse<DispatcherProfile>>('/dispatcher/profile'),

  getPickupQueue: (params?: { page?: number; pageSize?: number }) =>
    axiosInstance.get<ApiResponse<PagedDispatcherResult<DispatcherQueueItem>>>(
      '/dispatcher/pickups', { params },
    ),

  claimPickup: (orderItemId: number) =>
    axiosInstance.post<ApiResponse<{ assignmentId: number; orderItemId: number; orderStatus: number; orderNumber: string; warehouseId: number }>>(
      `/dispatcher/pickups/${orderItemId}/claim`,
    ),

  confirmPickup: () =>
    axiosInstance.post<ApiResponse<{ confirmed: number }>>('/dispatcher/pickups/confirm'),

  getActive: (params?: { page?: number; pageSize?: number }) =>
    axiosInstance.get<ApiResponse<PagedDispatcherResult<DispatcherAssignment>>>(
      '/dispatcher/assignments/active', { params },
    ),

  /** Move a Dispatched parcel (status 4) → Out for Delivery (status 9). */
  markOutForDelivery: (assignmentId: number) =>
    axiosInstance.post<ApiResponse<{ assignmentId: number; orderItemId: number; status: number; orderNumber: string }>>(
      `/dispatcher/deliveries/${assignmentId}/out-for-delivery`,
    ),

  /** Generate + send the delivery OTP to the buyer (in-app always, SMS best-effort).
   *  The OTP is never returned — dispatcher reads it back from the buyer. */
  sendDeliveryOtp: (assignmentId: number) =>
    axiosInstance.post<ApiResponse<{ orderNumber: string; smsSent: boolean }>>(
      `/dispatcher/deliveries/${assignmentId}/send-otp`,
    ),

  /** Verify the buyer's OTP and complete delivery with proof + COD. */
  completeDelivery: (assignmentId: number, body: {
    otp: string;
    proofPhotoUrl?: string | null;
    gpsLat?: number | null;
    gpsLng?: number | null;
    codAmount?: number | null;
  }) =>
    axiosInstance.post<ApiResponse<{ assignmentId: number; orderItemId: number; status: number; orderNumber: string }>>(
      `/dispatcher/deliveries/${assignmentId}/complete`, body,
    ),
};
