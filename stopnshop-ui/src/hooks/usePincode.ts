import { useState } from 'react';
import { catalogueApi } from '../api/catalogueApi';
import type { PincodeDelivery } from '../types/catalogue.types';

export function usePincode() {
  const [result, setResult] = useState<PincodeDelivery | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const checkPincode = async (pin: string) => {
    setIsLoading(true);
    setError(null);
    setResult(null);
    try {
      const res = await catalogueApi.checkPincode(pin);
      setResult(res.data.data);
    } catch {
      setError('Could not check pincode. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return { result, isLoading, error, checkPincode };
}
