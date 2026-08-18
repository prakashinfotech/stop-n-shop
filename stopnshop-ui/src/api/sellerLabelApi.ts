import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';

export interface SellerLabelData {
  orderItemId: number;
  lineStatus: number;
  orderId: number;
  orderNumber: string;
  orderDate: string;
  paymentMode: number;       // 1 COD | 2 Online | 3 Wallet
  paymentStatus: number;

  productName: string;
  variantSnapshot?: string | null;
  quantity: number;
  unitPrice: number;
  taxAmount: number;
  totalPrice: number;
  variantSku?: string | null;
  color?: string | null;
  size?: string | null;
  variantWeightGm?: number | null;

  barcodeValue: string;
  qrPayload: string;

  buyerName?: string | null;
  buyerPhoneMasked?: string | null;
  addressLine1?: string | null;
  addressLine2?: string | null;
  buyerCity?: string | null;
  buyerState?: string | null;
  buyerPincode?: string | null;
  buyerCountry?: string | null;

  sellerBusinessName?: string | null;
  sellerGstNumber?: string | null;
  sellerSupportPhone?: string | null;
  sellerSupportEmail?: string | null;
  sellerLogoUrl?: string | null;
  sellerAddressLine1?: string | null;
  sellerAddressLine2?: string | null;
  sellerCity?: string | null;
  sellerState?: string | null;
  sellerPincode?: string | null;
}

export const sellerLabelApi = {
  getLabelData: (orderItemId: number) =>
    axiosInstance.get<ApiResponse<SellerLabelData>>(
      `/seller/orders/items/${orderItemId}/label-data`,
    ),
};
