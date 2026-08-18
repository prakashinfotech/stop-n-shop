import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import type { UserProfile, LoginRequest, SignupRequest } from '../types/auth.types';
import { authApi } from '../api/authApi';
import { authErrorEvent, AUTH_ERROR_EVENT } from '../api/axiosInstance';
import { isJwtExpired } from '../lib/jwt';

interface AuthContextValue {
  user: UserProfile | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  sendOtp: (mobile: string) => Promise<string>;
  verifyOtp: (mobile: string, otp: string) => Promise<UserProfile>;
  login: (data: LoginRequest) => Promise<void>;
  signup: (data: SignupRequest) => Promise<void>;
  setAuth: (token: string, user: UserProfile) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const CUSTOMER_TOKEN_KEY = 'sns_customer_token';
const CUSTOMER_USER_KEY  = 'sns_customer_user';
const SELLER_TOKEN_KEY = 'sns_seller_token';
const SELLER_USER_KEY  = 'sns_seller_user';

function clearAllAuth() {
  localStorage.removeItem(CUSTOMER_TOKEN_KEY);
  localStorage.removeItem(CUSTOMER_USER_KEY);
  localStorage.removeItem(SELLER_TOKEN_KEY);
  localStorage.removeItem(SELLER_USER_KEY);
}

function loadInitialState(): { token: string | null; user: UserProfile | null } {
  try {
    let token = localStorage.getItem(CUSTOMER_TOKEN_KEY);
    let raw   = localStorage.getItem(CUSTOMER_USER_KEY);
    let user  = raw ? (JSON.parse(raw) as UserProfile) : null;

    if (!token) {
      token = localStorage.getItem(SELLER_TOKEN_KEY);
      raw   = localStorage.getItem(SELLER_USER_KEY);
      user  = raw ? (JSON.parse(raw) as UserProfile) : null;
    }

    // Reject expired tokens before the rest of the app trusts them.
    if (token && isJwtExpired(token)) {
      clearAllAuth();
      return { token: null, user: null };
    }

    return { token, user };
  } catch {
    return { token: null, user: null };
  }
}

function persist(token: string, user: UserProfile) {
  localStorage.clear();

  if (user.role === 'Seller') {
    localStorage.setItem(SELLER_TOKEN_KEY, token);
    localStorage.setItem(SELLER_USER_KEY, JSON.stringify(user));
  } else {
    localStorage.setItem(CUSTOMER_TOKEN_KEY, token);
    localStorage.setItem(CUSTOMER_USER_KEY, JSON.stringify(user));
  }
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const initial = loadInitialState();
  const [token, setToken] = useState<string | null>(initial.token);
  const [user,  setUser]  = useState<UserProfile | null>(initial.user);
  const [isLoading, setIsLoading] = useState(false);

  // Listen for 401 errors from axios interceptor
  useEffect(() => {
    const handleAuthError = (event: Event) => {
      const customEvent = event as CustomEvent;
      setToken(null);
      setUser(null);
      // Navigate using window.location as a fallback (only after clearing state)
      setTimeout(() => {
        window.location.href = customEvent.detail?.redirectPath || '/user/login';
      }, 0);
    };

    authErrorEvent.addEventListener(AUTH_ERROR_EVENT, handleAuthError);
    return () => authErrorEvent.removeEventListener(AUTH_ERROR_EVENT, handleAuthError);
  }, []);

  // Re-check token expiry when the tab regains focus — covers the case where a
  // user left the tab open for days, the JWT expired in the background, and they
  // came back expecting a fresh session instead of stale "logged in" UI.
  useEffect(() => {
    const checkExpiry = () => {
      if (token && isJwtExpired(token)) {
        clearAllAuth();
        setToken(null);
        setUser(null);
      }
    };

    window.addEventListener('focus', checkExpiry);
    document.addEventListener('visibilitychange', checkExpiry);
    return () => {
      window.removeEventListener('focus', checkExpiry);
      document.removeEventListener('visibilitychange', checkExpiry);
    };
  }, [token]);

  const sendOtp = useCallback(async (mobile: string): Promise<string> => {
    setIsLoading(true);
    try {
      const res = await authApi.sendOtp(mobile);
      return res.data.data?.otpCode ?? '';
    } finally {
      setIsLoading(false);
    }
  }, []);

  const verifyOtp = useCallback(async (mobile: string, otp: string): Promise<UserProfile> => {
    setIsLoading(true);
    try {
      const res = await authApi.verifyOtp(mobile, otp);
      const { token: newToken, user: newUser } = res.data.data;
      persist(newToken, newUser);
      setToken(newToken);
      setUser(newUser);
      return newUser;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const login = useCallback(async (data: LoginRequest) => {
    setIsLoading(true);
    try {
      const res = await authApi.login(data);
      const { token: newToken, user: newUser } = res.data.data;
      persist(newToken, newUser);
      setToken(newToken);
      setUser(newUser);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const signup = useCallback(async (data: SignupRequest) => {
    setIsLoading(true);
    try {
      const res = await authApi.signup(data);
      const { token: newToken, user: newUser } = res.data.data;
      persist(newToken, newUser);
      setToken(newToken);
      setUser(newUser);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const setAuth = useCallback((newToken: string, newUser: UserProfile) => {
    persist(newToken, newUser);
    setToken(newToken);
    setUser(newUser);
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(CUSTOMER_TOKEN_KEY);
    localStorage.removeItem(CUSTOMER_USER_KEY);
    localStorage.removeItem(SELLER_TOKEN_KEY);
    localStorage.removeItem(SELLER_USER_KEY);
    setToken(null);
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider
      value={{ user, token, isAuthenticated: !!token, isLoading, sendOtp, verifyOtp, login, signup, setAuth, logout }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export function useAuthContext(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuthContext must be used inside AuthProvider');
  return ctx;
}
