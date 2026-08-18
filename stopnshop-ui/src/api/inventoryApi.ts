import { axiosInstance } from './axiosInstance';
import type { ApiResponse, PagedResult } from '../types/common.types';

export interface Warehouse {
  warehouseId:  number;
  code:         string;
  name:         string;
  sellerId:     number | null;
  sellerName:   string | null;
  addressLine1: string | null;
  addressLine2: string | null;
  city:         string | null;
  state:        string | null;
  pinCode:      string | null;
  country:      string | null;
  isActive:     boolean;
  createdAt:    string;
}

export interface StockRow {
  stockId:        number;
  variantId:      number;
  warehouseId:    number;
  warehouseCode:  string | null;
  warehouseName:  string | null;
  onHand:         number;
  reserved:       number;
  available:      number;
  updatedAt:      string;
}

export interface StockMatrixRow {
  variantId:         number;
  productId:         number;
  variantSku:        string;
  productName:       string;
  color:             string | null;
  size:              string | null;
  lowStockThreshold: number;
  sellerId:          number | null;
  sellerName:        string | null;
  warehouseId:       number | null;
  warehouseCode:     string | null;
  warehouseName:     string | null;
  onHand:            number;
  reserved:          number;
  available:         number;
}

export interface LowStockRow {
  variantId:         number;
  productId:         number;
  variantSku:        string;
  color:             string | null;
  size:              string | null;
  lowStockThreshold: number;
  productName:       string;
  sellerId:          number | null;
  sellerName:        string | null;
  totalOnHand:       number;
  totalReserved:     number;
  totalAvailable:    number;
}

export interface StockMovement {
  movementId:     number;
  variantId:      number;
  warehouseId:    number;
  warehouseCode:  string | null;
  warehouseName:  string | null;
  movementType:   number;
  quantityDelta:  number;
  reservedDelta:  number;
  reason:         string | null;
  referenceType:  string | null;
  referenceId:    number | null;
  changedBy:      number | null;
  changedByEmail: string | null;
  changedAt:      string;
}

export interface StockAdjustRequest {
  variantId:     number;
  warehouseId:   number;
  quantityDelta: number;
  reason?:       string;
  movementType?: number;
}

export interface StockTransferRequest {
  variantId:       number;
  fromWarehouseId: number;
  toWarehouseId:   number;
  quantity:        number;
  reason?:         string;
}

export const MOVEMENT_TYPE_LABELS: Record<number, string> = {
  1: 'Receipt',
  2: 'Adjustment',
  3: 'Reserve',
  4: 'Release',
  5: 'Ship',
  6: 'Return',
  7: 'Transfer Out',
  8: 'Transfer In',
};

export const inventoryApi = {
  getWarehouses: (params?: { sellerId?: number; includeInactive?: boolean }) =>
    axiosInstance.get<ApiResponse<Warehouse[]>>('/inventory/warehouses', { params }),

  getStockByVariant: (variantId: number) =>
    axiosInstance.get<ApiResponse<StockRow[]>>(`/inventory/variants/${variantId}/stock`),

  getMatrix: (params?: { sellerId?: number; warehouseId?: number; search?: string; pageNo?: number; pageSize?: number }) =>
    axiosInstance.get<ApiResponse<PagedResult<StockMatrixRow>>>('/inventory/matrix', { params }),

  getLowStock: (params?: { sellerId?: number; warehouseId?: number; pageNo?: number; pageSize?: number }) =>
    axiosInstance.get<ApiResponse<PagedResult<LowStockRow>>>('/inventory/low-stock', { params }),

  getMovements: (variantId: number, params?: { warehouseId?: number; pageNo?: number; pageSize?: number }) =>
    axiosInstance.get<ApiResponse<PagedResult<StockMovement>>>(`/inventory/variants/${variantId}/movements`, { params }),

  adjust: (req: StockAdjustRequest) =>
    axiosInstance.post<ApiResponse<{ onHand: number; reserved: number }>>('/inventory/stock/adjust', req),

  initiateTransfer: (req: StockTransferRequest) =>
    axiosInstance.post<ApiResponse<{ transferId: number }>>('/inventory/transfers', req),

  receiveTransfer: (id: number) =>
    axiosInstance.patch<ApiResponse<null>>(`/inventory/transfers/${id}/receive`),
};
