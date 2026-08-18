import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';
import type { Address, AddAddressRequest } from '../types/cart.types';

export const addressesApi = {
  getAddresses: () =>
    axiosInstance.get<ApiResponse<Address[]>>('/addresses'),

  addAddress: (data: AddAddressRequest) =>
    axiosInstance.post<ApiResponse<{ id: number }>>('/addresses', data),

  setDefault: (id: number) =>
    axiosInstance.put<ApiResponse<null>>(`/addresses/${id}/default`),
};
