export interface Product {
  id: number;
  name: string;
  price: number;
  originalPrice?: number;
  description: string;
  imageUrl: string;
  categoryName: string;
  categoryId: number;
  isNew?: boolean;
  isBestseller?: boolean;
}

export interface ProductListItem {
  id: number;
  name: string;
  brand: string;
  sellingPrice: number;
  mrp: number;
  discountPercent: number;
  primaryImage: string;
  offerCount: number;
  categoryId: number;
  subCategoryId: number;
}

export interface ProductImage {
  id: number;
  url: string;
  altText?: string;
}

export interface ProductSize {
  label: string;
  inStock: boolean;
}

export interface ProductColor {
  name: string;
  hex: string;
  inStock: boolean;
}

export interface ProductOffer {
  code: string;
  description: string;
  discountType: string;
  value: number;
}

export interface ProductSpec {
  key: string;
  value: string;
}

export interface ProductDetail {
  id: number;
  name: string;
  brand: string;
  description: string;
  sellingPrice: number;
  mrp: number;
  discountPercent: number;
  images: ProductImage[];
  sizes: ProductSize[];
  colors: ProductColor[];
  offers: ProductOffer[];
  categoryId: number;
  subCategoryId: number;
  categoryName?: string;
  subCategoryName?: string;
  highlights?: string[];
  aboutBrand?: string;

  // Extended product details — all optional; API substitutes defaults for legacy products.
  material?: string;
  careInstructions?: string;
  fitType?: string;
  countryOfOrigin?: string;
  warrantyInfo?: string;
  deliveryInfo?: string;
  returnPolicyDays?: number;
  specifications?: ProductSpec[];
  seller?: {
    id: number;
    name: string;
    description?: string;
    logo?: string;
  };
}

export interface ProductQueryParams {
  menuId?: number;
  categoryId?: number;
  subCategoryId?: number;
  brandIds?: string;
  gender?: string;
  sizes?: string;
  colors?: string;
  minPrice?: number;
  maxPrice?: number;
  minDiscount?: number;
  sortBy?: 'POPULAR' | 'LATEST' | 'DISCOUNT' | 'PRICE_ASC' | 'PRICE_DESC';
  datePosted?: string;
  pageNo?: number;
  pageSize?: number;
  search?: string;
}

export interface CreateProductRequest {
  name: string;
  price: number;
  description: string;
  imageUrl: string;
  categoryId: number;
}

export interface UpdateProductRequest {
  name?: string;
  price?: number;
  description?: string;
  imageUrl?: string;
  categoryId?: number;
}
