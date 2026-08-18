import { axiosInstance } from './axiosInstance';
import type { ApiResponse } from '../types/common.types';
import type {
  AuthTokenResponse,
  UserProfile,
  UpdateProfileRequest,
  LoginRequest,
  SignupRequest,
} from '../types/auth.types';

export const authApi = {
  // ── OTP ──────────────────────────────────────────────────────────────────────
  sendOtp: (mobile: string) =>
    axiosInstance.post<ApiResponse<{ otpCode?: string }>>('/auth/otp/send', { mobile }),

  verifyOtp: (mobile: string, otp: string) =>
    axiosInstance.post<ApiResponse<AuthTokenResponse>>('/auth/otp/verify', { mobile, otp }),

  // ── Email / Password ─────────────────────────────────────────────────────────
  login: (data: LoginRequest) =>
    axiosInstance.post<ApiResponse<AuthTokenResponse>>('/auth/buyer/login', data),

  signup: (data: SignupRequest) =>
    axiosInstance.post<ApiResponse<AuthTokenResponse>>('/auth/buyer/register', data),

  // ── Password Reset ────────────────────────────────────────────────────────────
  forgotPassword: (email: string) =>
    axiosInstance.post<ApiResponse<{ userId: number; email: string; firstName?: string } | null>>('/auth/forgot-password', { email }),

  verifyForgotPasswordOtp: (userId: number, otp: string) =>
    axiosInstance.post<ApiResponse<null>>('/auth/forgot-password/verify-otp', { userId, otp }),

  resetPassword: (userId: number, newPassword: string) =>
    axiosInstance.post<ApiResponse<null>>('/auth/reset-password', { userId, newPassword }),

  // ── Profile ───────────────────────────────────────────────────────────────────
  getProfile: () =>
    axiosInstance.get<ApiResponse<UserProfile>>('/auth/profile'),

  updateProfile: (data: UpdateProfileRequest) =>
    axiosInstance.put<ApiResponse<UserProfile>>('/auth/profile', data),
};
