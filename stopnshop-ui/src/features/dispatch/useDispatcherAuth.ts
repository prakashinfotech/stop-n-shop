import { useCallback } from 'react';
import { useAuthContext } from '../../context/AuthContext';
import { dispatcherApi } from '../../api/dispatcherApi';
import type { UserProfile } from '../../types/auth.types';

/** Dispatcher login + logout. Mirrors useSellerAuth pattern — wraps the
 *  standard AuthController.DispatcherLogin endpoint, then stuffs the
 *  resulting profile into the shared AuthContext so route guards work. */
export const useDispatcherAuth = () => {
  const { setAuth, logout } = useAuthContext();

  const login = useCallback(async (email: string, password: string) => {
    const response = await dispatcherApi.auth.login(email, password);
    if (!response.data?.success || !response.data?.data) {
      throw new Error(response.data?.message || 'Login failed');
    }
    const { token, user } = response.data.data;

    const profile: UserProfile = {
      id: user.id,
      email: user.email,
      name: [user.firstName, user.lastName].filter(Boolean).join(' ') || 'Dispatcher',
      role: 'Dispatcher',
      mobile: user.mobile,
      firstName: user.firstName,
      lastName: user.lastName,
    };
    setAuth(token, profile);
    return profile;
  }, [setAuth]);

  return { login, logout };
};
