import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface WalletDto {
  walletId: number;
  userId: number;
  balance: number;
  updatedAt: string;
}

export interface WalletTransactionDto {
  transactionId: number;
  amount: number;
  transactionType: number;  // 1=Credit, 2=Debit
  referenceType?: string;
  referenceId?: number;
  description: string;
  createdAt: string;
}

export interface WalletPageDto {
  wallet: WalletDto;
  transactions: WalletTransactionDto[];
  totalCount: number;
  totalPages: number;
}

export interface WelcomeBonusResult {
  claimed: boolean;
  amountCredited: number;
  newBalance: number;
  message: string;
}

export const walletApi = {
  getWallet: (page = 1, pageSize = 20) =>
    axiosInstance.get<ApiResponse<WalletPageDto>>('/wallet', { params: { page, pageSize } }),

  claimWelcomeBonus: () =>
    axiosInstance.post<ApiResponse<WelcomeBonusResult>>('/wallet/welcome-bonus'),

  dismissWelcomeBonus: () =>
    axiosInstance.post<ApiResponse<null>>('/wallet/welcome-bonus/dismiss'),
};
