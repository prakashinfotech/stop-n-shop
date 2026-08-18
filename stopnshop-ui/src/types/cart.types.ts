export interface CartItem {
  id: number;
  productId: number;
  productName: string;
  brand: string;
  imageUrl: string;
  sizeLabel: string;
  colorName: string;
  quantity: number;
  sellingPrice: number;
  mrp: number;
  discountPercent: number;
}

export interface CartSummary {
  totalMRP: number;
  totalDiscount: number;
  couponDiscount?: number;
  couponCode?: string | null;
  deliveryCharge: number;
  finalAmount: number;
}

export interface CartDto {
  items: CartItem[];
  summary: CartSummary;
}

export interface AddToCartRequest {
  productId: number;
  sizeLabel: string;
  colorName: string;
  quantity: number;
}

export interface Address {
  id: number;
  name: string;
  mobile: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  pincode: string;
  isDefault: boolean;
}

export interface AddAddressRequest {
  name: string;
  mobile: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  pincode: string;
  isDefault?: boolean;
}

export type PaymentMethod = 'UPI' | 'CARD' | 'NETBANKING' | 'COD' | 'RAZORPAY';

export interface PlaceOrderRequest {
  addressId: number;
  paymentMethod: PaymentMethod;
  couponCode?: string;
}

export interface Order {
  id: number;
  orderNumber: string;
  status: string;
  createdAt: string;
  itemCount: number;
  finalAmount: number;
  primaryImage?: string;
}

export interface OrderItem {
  id: number;
  productId: number;
  productName: string;
  brand: string;
  imageUrl: string;
  sizeLabel: string;
  colorName?: string;
  quantity: number;
  sellingPrice: number;
  /** Per-line fulfilment state: 1 Placed, 2 Confirmed, 3 Packed, 4 Dispatched, 5 Delivered, 6 Cancelled, 7 Returned, 8 Rejected. */
  lineStatus?: number;
  confirmedAt?: string | null;
  rejectedAt?: string | null;
  rejectionReason?: string | null;
}

export interface OrderTracking {
  status: string;
  description: string;
  createdAt: string;
}

export interface OrderDetail {
  id: number;
  orderNumber: string;
  status: string;
  paymentMethod: string;
  createdAt: string;
  address: Address;
  items: OrderItem[];
  summary: CartSummary;
  tracking: OrderTracking[];
}

export interface WishlistItem {
  id: number;
  productId: number;
  productName: string;
  brand: string;
  primaryImage: string;
  sellingPrice: number;
  mrp: number;
  discountPercent: number;
  offerCount: number;
}
