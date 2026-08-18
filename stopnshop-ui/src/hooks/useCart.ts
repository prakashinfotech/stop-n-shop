import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { cartApi } from '../api/cartApi';
import type { AddToCartRequest } from '../types/cart.types';
import { useAuthContext } from '../context/AuthContext';

const CART_KEY = ['cart'];

export function useCart() {
  const { isAuthenticated } = useAuthContext();
  const queryClient = useQueryClient();

  const { data, isLoading, isError } = useQuery({
    queryKey: CART_KEY,
    queryFn: () => cartApi.getCart().then((r) => r.data.data),
    enabled: isAuthenticated,
  });

  const addMutation = useMutation({
    mutationFn: (req: AddToCartRequest) => cartApi.addToCart(req).then((r) => r.data.data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: CART_KEY }),
  });

  const updateMutation = useMutation({
    mutationFn: ({ cartId, quantity }: { cartId: number; quantity: number }) =>
      cartApi.updateCart(cartId, quantity).then((r) => r.data.data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: CART_KEY }),
  });

  const deleteMutation = useMutation({
    mutationFn: (cartId: number) => cartApi.deleteCartItem(cartId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: CART_KEY }),
  });

  const cartCount = data?.items.reduce((sum, item) => sum + item.quantity, 0) ?? 0;

  return {
    cart: data,
    cartCount,
    isLoading,
    isError,
    addToCart: addMutation.mutateAsync,
    isAdding: addMutation.isPending,
    updateCart: updateMutation.mutateAsync,
    deleteCartItem: deleteMutation.mutateAsync,
  };
}
