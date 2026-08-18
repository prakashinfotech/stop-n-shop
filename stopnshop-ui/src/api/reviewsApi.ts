import { axiosInstance } from './axiosInstance';

export interface ReviewDto {
  reviewId: number;
  reviewerName: string;
  rating: number;
  title?: string;
  body?: string;
  createdAt: string;
  helpfulCount: number;
}

export interface ProductReviewsDto {
  averageRating: number;
  totalCount: number;
  items: ReviewDto[];
}

export const reviewsApi = {
  getProductReviews: (productId: number, page = 1, pageSize = 10, rating?: number) =>
    axiosInstance.get<{ success: boolean; data: ProductReviewsDto }>(
      `/products/${productId}/reviews`,
      { params: { page, pageSize, ...(rating ? { rating } : {}) } }
    ),

  addReview: (productId: number, data: { rating: number; comment: string }) =>
    axiosInstance.post<{ success: boolean; message: string; data: null }>(
      `/products/${productId}/reviews`,
      data
    ),
};
