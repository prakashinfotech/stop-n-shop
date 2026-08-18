export const DEFAULT_PRODUCT_IMAGE = '/uploads/products/default-product.svg';

export const resolveProductImage = (url?: string | null): string =>
  url && url.trim().length > 0 ? url : DEFAULT_PRODUCT_IMAGE;
