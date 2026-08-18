import { useCallback } from 'react';
import { useAuthContext } from '../../context/AuthContext';
import { sellerApi } from '../../api/sellerApi';
import type { UserProfile } from '../../types/auth.types';

export const useSellerAuth = () => {
  const { setAuth, logout } = useAuthContext();

  const login = useCallback(
    async (email: string, password: string) => {
      try {
        const response = await sellerApi.auth.login({ email, password });

        if (!response.data?.success || !response.data?.data) {
          throw new Error(response.data?.message || 'Login failed');
        }

        const { token, seller } = response.data.data;

        // Map seller to UserProfile for AuthContext
        const userProfile: UserProfile = {
          id: seller.id,
          email: seller.email,
          name: seller.businessName || 'Seller',
          role: 'Seller',
          mobile: seller.phoneNumber,
        };

        // Store in context
        setAuth(token, userProfile);

        return seller;
      } catch (error: any) {
        throw new Error(
          error.response?.data?.message || error.message || 'Login failed'
        );
      }
    },
    [setAuth]
  );

  const signup = useCallback(
    async (data: any) => {
      try {
        const response = await sellerApi.auth.signup(data);

        if (!response.data?.success || !response.data?.data) {
          throw new Error(response.data?.message || 'Signup failed');
        }

        const { token, seller, phoneOtp, emailOtp } = response.data.data;

        // Map seller to UserProfile for AuthContext
        const userProfile: UserProfile = {
          id: seller.id,
          email: seller.email,
          name: seller.businessName || 'Seller',
          role: 'Seller',
          mobile: seller.phoneNumber,
        };

        // Store in context
        setAuth(token, userProfile);

        // Return OTPs for the page to display/use
        return { seller, phoneOtp, emailOtp };
      } catch (error: any) {
        throw new Error(
          error.response?.data?.message || error.message || 'Signup failed'
        );
      }
    },
    [setAuth]
  );

  const completeOnboarding = useCallback(
    async (data: any) => {
      try {
        const response = await sellerApi.auth.completeOnboarding(data);

        if (!response.data?.success) {
          throw new Error(response.data?.message || 'Onboarding failed');
        }

        return true;
      } catch (error: any) {
        throw new Error(
          error.response?.data?.message || error.message || 'Onboarding failed'
        );
      }
    },
    []
  );

  return { login, signup, completeOnboarding, logout };
};
