import { useState } from 'react';
import { useAuthContext } from '../../context/AuthContext';
import type { LoginRequest, SignupRequest } from '../../types/auth.types';

export function useLogin() {
  const { login, isLoading } = useAuthContext();
  const [serverError, setServerError] = useState<string | null>(null);

  const submit = async (data: LoginRequest) => {
    setServerError(null);
    try {
      await login(data);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setServerError(msg ?? 'Invalid email or password.');
      throw err;
    }
  };

  const clearError = () => setServerError(null);
  return { submit, isLoading, serverError, clearError };
}

export function useRegister() {
  const { signup, isLoading } = useAuthContext();
  const [serverError, setServerError] = useState<string | null>(null);

  const submit = async (data: SignupRequest) => {
    setServerError(null);
    try {
      await signup(data);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setServerError(msg ?? 'Could not create account. Please try again.');
      throw err;
    }
  };

  return { submit, isLoading, serverError };
}
