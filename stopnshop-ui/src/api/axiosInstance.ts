import axios from 'axios';

const API_BASE_URL = (import.meta as any).env?.VITE_API_URL || 'http://localhost:5000/api';

export const axiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 10000,
});

// Event emitter for auth errors
export const authErrorEvent = new EventTarget();
export const AUTH_ERROR_EVENT = 'auth-error';

axiosInstance.interceptors.request.use((config) => {
  const token =
    localStorage.getItem('sns_seller_token') ||
    localStorage.getItem('sns_customer_token') ||
    localStorage.getItem('sns_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

axiosInstance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const url: string = error.config?.url ?? '';
      // 401 from any auth endpoint (login, OTP, forgot/reset password) is a credential
      // error, not a session-expired event — let it surface as a form error without
      // wiping state or bouncing the user between user/seller login pages.
      const isAuthEndpoint = /^\/?(auth|seller\/auth)\//.test(url);
      if (isAuthEndpoint) {
        return Promise.reject(error);
      }

      // Decide which login page to bounce to based on the CURRENT route, not on
      // whichever token happens to still be in localStorage (stale seller tokens
      // were hijacking buyer logins).
      const path = window.location.pathname;
      const isSellerArea = path.startsWith('/seller');
      const redirectPath = isSellerArea ? '/seller/login' : '/user/login';

      if (isSellerArea) {
        localStorage.removeItem('sns_seller_token');
        localStorage.removeItem('sns_seller_user');
      } else {
        localStorage.removeItem('sns_customer_token');
        localStorage.removeItem('sns_customer_user');
        localStorage.removeItem('sns_token');
        localStorage.removeItem('sns_user');
      }

      authErrorEvent.dispatchEvent(
        new CustomEvent(AUTH_ERROR_EVENT, { detail: { redirectPath } })
      );
    }
    return Promise.reject(error);
  }
);
