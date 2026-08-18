import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { wishlistApi } from '../api/wishlistApi';
import { useAuthContext } from '../context/AuthContext';

const WISHLIST_KEY = ['wishlist'];

export function useWishlist() {
  const { isAuthenticated } = useAuthContext();
  const queryClient = useQueryClient();

  const { data: items = [], isLoading } = useQuery({
    queryKey: WISHLIST_KEY,
    queryFn: () => wishlistApi.getWishlist().then((r) => r.data.data),
    enabled: isAuthenticated,
  });

  const toggleMutation = useMutation({
    mutationFn: (productId: number) =>
      wishlistApi.toggleWishlist(productId).then((r) => r.data.data),
    onMutate: async (productId: number) => {
      await queryClient.cancelQueries({ queryKey: WISHLIST_KEY });
      const previous = queryClient.getQueryData(WISHLIST_KEY);
      queryClient.setQueryData(WISHLIST_KEY, (old: any[] = []) => {
        const exists = old.some((item) => item.productId === productId);
        if (exists) {
          return old.filter((item) => item.productId !== productId);
        } else {
          return [...old, { productId }];
        }
      });
      return { previous };
    },
    onError: (_err, _variables, context: any) => {
      if (context?.previous) {
        queryClient.setQueryData(WISHLIST_KEY, context.previous);
      }
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: WISHLIST_KEY }),
  });

  const isWishlisted = (productId: number) =>
    items.some((item) => item.productId === productId);

  return {
    items,
    isLoading,
    toggleWishlist: toggleMutation.mutateAsync,
    isWishlisted,
  };
}
