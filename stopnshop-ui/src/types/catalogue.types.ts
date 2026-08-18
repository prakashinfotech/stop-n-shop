export interface ProductType {
  id: number;
  name: string;
}

export interface SubCategory {
  id: number;
  name: string;
  iconUrl?: string;
  productTypes: ProductType[];
}

export interface MegaMenuCategory {
  id: number;
  name: string;
  slug: string;
  subCategories: SubCategory[];
}

export interface Banner {
  id: number;
  imageUrl: string;
  mobileImageUrl?: string;
  title?: string;
  subtitle?: string;
  linkUrl?: string;
  section: number;
  sortOrder: number;
  /** Vertical gap (px) the CMS admin wants below this banner in the home stack. */
  gapBelowPx?: number;
  /** Optional surface colour rendered behind this banner. */
  backgroundColor?: string | null;
}

export interface Store {
  id: number;
  name: string;
  address: string;
  city: string;
  state: string;
  lat: number;
  lng: number;
  phone: string;
}

export interface PincodeDelivery {
  isDeliverable: boolean;
  estimatedDays: number;
  city: string;
  state: string;
}

export interface FeaturedSubCategory {
  subCategoryId: number;
  subCategoryName: string;
  slugUrl: string;
  iconUrl?: string | null;
  sortOrder: number;
  categoryId: number;
  categoryName: string;
  categorySlug: string;
  menuId: number;
  menuName: string;
  menuSlug: string;
}
