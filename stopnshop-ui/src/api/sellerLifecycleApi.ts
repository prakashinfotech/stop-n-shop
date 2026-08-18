import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface SellerBankAccount {
  bankAccountId: number;
  sellerId: number;
  accountHolderName: string;
  bankName: string;
  accountNumber: string;
  ifscCode: string;
  branchName?: string | null;
  isPrimary: boolean;
  isVerified: boolean;
  verifiedAt?: string | null;
  createdAt: string;
}

export interface AddBankAccountRequest {
  accountHolderName: string;
  bankName: string;
  accountNumber: string;
  ifscCode: string;
  branchName?: string;
  isPrimary?: boolean;
}

export interface SellerWarehouse {
  sellerWarehouseId: number;
  sellerId: number;
  name: string;
  contactName?: string | null;
  contactPhone?: string | null;
  addressLine1: string;
  addressLine2?: string | null;
  city: string;
  state: string;
  pincode: string;
  isPrimary: boolean;
}

export interface UpsertWarehouseRequest {
  sellerWarehouseId?: number | null;
  name: string;
  contactName?: string;
  contactPhone?: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  pincode: string;
  isPrimary?: boolean;
}

export interface VendorAgreement {
  agreementId: number;
  sellerId: number;
  version: string;
  acceptedAt: string;
  documentUrl?: string | null;
}

export interface SellerSettlement {
  settlementId: number;
  sellerId: number;
  periodStart: string;
  periodEnd: string;
  grossSales: number;
  commissionAmount: number;
  tdsAmount: number;
  penaltyAmount: number;
  refundAmount: number;
  netPayout: number;
  status: number;     // 1=Pending,2=Paid,3=OnHold,4=Failed
  paidAt?: string | null;
  utrNumber?: string | null;
  bankAccountId?: number | null;
  notes?: string | null;
  createdAt: string;
}

export interface SellerSettlementLine {
  settlementLineId: number;
  settlementId: number;
  orderItemId: number;
  orderId: number;
  grossAmount: number;
  commissionAmount: number;
  tdsAmount: number;
  penaltyAmount: number;
  netAmount: number;
}

export interface SellerSettlementDetail {
  settlement: SellerSettlement | null;
  lines: SellerSettlementLine[];
}

export interface SellerPerformanceScore {
  performanceScoreId: number;
  sellerId: number;
  snapshotDate: string;
  windowDays: number;
  ordersTotal: number;
  ordersDelivered: number;
  ordersCancelled: number;
  ordersReturned: number;
  onTimeDispatchPct: number;
  cancellationPct: number;
  returnPct: number;
  avgRating: number;
  compositeScore: number;
  tier: string;
  createdAt: string;
}

export const SETTLEMENT_STATUS_LABELS: Record<number, string> = {
  1: 'Pending',
  2: 'Paid',
  3: 'On Hold',
  4: 'Failed',
};

export const sellerLifecycleApi = {
  onboarding: {
    advanceStage: (stage: string) =>
      axiosInstance.post<ApiResponse<unknown>>('/seller/onboarding/stage', { stage }),
  },

  documents: {
    upload: (documentType: number, documentUrl: string) =>
      axiosInstance.post<ApiResponse<unknown>>('/seller/documents', { documentType, documentUrl }),
  },

  bankAccounts: {
    list: () =>
      axiosInstance.get<ApiResponse<SellerBankAccount[]>>('/seller/bank-accounts'),
    add: (req: AddBankAccountRequest) =>
      axiosInstance.post<ApiResponse<SellerBankAccount>>('/seller/bank-accounts', req),
    setPrimary: (bankAccountId: number) =>
      axiosInstance.put<ApiResponse<unknown>>(`/seller/bank-accounts/${bankAccountId}/primary`),
  },

  warehouses: {
    list: () =>
      axiosInstance.get<ApiResponse<SellerWarehouse[]>>('/seller/warehouses'),
    upsert: (req: UpsertWarehouseRequest) =>
      axiosInstance.post<ApiResponse<SellerWarehouse>>('/seller/warehouses', req),
  },

  agreement: {
    accept: (version: string, documentUrl?: string) =>
      axiosInstance.post<ApiResponse<VendorAgreement>>('/seller/agreement/accept', { version, documentUrl }),
    latest: () =>
      axiosInstance.get<ApiResponse<VendorAgreement | null>>('/seller/agreement/latest'),
  },

  settlements: {
    list: (page = 1, pageSize = 20) =>
      axiosInstance.get<ApiResponse<{ items: SellerSettlement[]; totalCount: number; page: number; pageSize: number }>>(
        '/seller/settlements',
        { params: { page, pageSize } },
      ),
    get: (settlementId: number) =>
      axiosInstance.get<ApiResponse<SellerSettlementDetail>>(`/seller/settlements/${settlementId}`),
  },

  performanceScore: {
    get: () =>
      axiosInstance.get<ApiResponse<SellerPerformanceScore | null>>('/seller/performance-score'),
    recompute: () =>
      axiosInstance.post<ApiResponse<SellerPerformanceScore | null>>('/seller/performance-score/recompute'),
  },
};
