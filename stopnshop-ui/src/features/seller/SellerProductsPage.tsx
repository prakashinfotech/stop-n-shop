import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Plus, Edit, Trash2 } from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { sellerApi } from '../../api/sellerApi';
import { PremiumButton } from '../../components/forms/PremiumButton';
import { Spinner } from '../../components/ui/Spinner';
import { resolveProductImage } from '../../constants/productImage';

export const SellerProductsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const { data, isLoading, error } = useQuery({
    queryKey: ['seller-products'],
    queryFn: () => sellerApi.products.getAll({}).then(r => r.data.data),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => sellerApi.products.delete(id),
    onSuccess: () => {
      setDeletingId(null);
      queryClient.invalidateQueries({ queryKey: ['seller-products'] });
    },
  });

  const handleDelete = async (id: number) => {
    if (!window.confirm('Are you sure you want to delete this product?')) {
      return;
    }
    setDeletingId(id);
    await deleteMutation.mutateAsync(id);
  };

  const products = data?.items || [];

  return (
    <SellerLayout>
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-display font-bold text-content mb-2">Products</h1>
          <p className="text-content-muted">Manage your product catalog</p>
        </div>
        {products.length > 0 && (
          <Link to="/seller/products/new">
            <PremiumButton variant="primary">
              <Plus className="mr-2 h-4 w-4" /> Add Product
            </PremiumButton>
          </Link>
        )}
      </div>

      {isLoading ? (
        <div className="flex justify-center items-center h-64">
          <Spinner size="lg" />
        </div>
      ) : error ? (
        <div className="bg-red-50 text-red-600 p-4 rounded-lg">
          <p className="font-semibold">Failed to load products</p>
          <p className="text-sm mt-1">{(error as any)?.message || 'Please try again.'}</p>
        </div>
      ) : products.length === 0 ? (
        <div className="bg-surface-elevated rounded-2xl shadow-soft p-12 text-center border border-outline/60">
          <div className="w-16 h-16 bg-brand-50 text-brand-500 rounded-full flex items-center justify-center mx-auto mb-4">
            <Plus size={24} />
          </div>
          <h3 className="text-lg font-semibold text-content mb-2">No products yet</h3>
          <p className="text-content-muted mb-6">Add your first product to start selling.</p>
          <Link to="/seller/products/new">
            <PremiumButton variant="primary">Add Your First Product</PremiumButton>
          </Link>
        </div>
      ) : (
        <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface border-b border-outline/60">
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Product</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Price</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Stock</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted">Status</th>
                  <th className="px-6 py-4 text-sm font-semibold text-content-muted text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline/60">
                {products.map(product => (
                  <tr key={product.id} className="hover:bg-surface transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-4">
                        <div className="h-12 w-12 rounded-lg bg-surface-sunken flex-shrink-0 overflow-hidden">
                          <img
                            src={resolveProductImage(product.primaryImage)}
                            alt={product.name}
                            className="h-full w-full object-cover"
                            onError={(e) => { (e.currentTarget as HTMLImageElement).src = resolveProductImage(null); }}
                          />
                        </div>
                        <div>
                          <p className="font-semibold text-content">{product.name}</p>
                          <p className="text-xs text-content-muted">ID: {product.id}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-content font-medium">₹{product.sellingPrice}</p>
                      {product.mrp > product.sellingPrice && (
                        <p className="text-xs text-content-muted line-through">₹{product.mrp}</p>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        product.stockQuantity <= product.lowStockThreshold 
                          ? 'bg-amber-100 text-amber-800' 
                          : 'bg-green-100 text-green-800'
                      }`}>
                        {product.stockQuantity} in stock
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        product.isApproved ? 'bg-blue-100 text-blue-800' : 'bg-surface-sunken text-content'
                      }`}>
                        {product.isApproved ? 'Approved' : 'Pending'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-2">
                        <Link to={`/seller/products/${product.id}/edit`}>
                          <button className="p-2 text-content-subtle hover:text-brand-500 transition-colors">
                            <Edit size={18} />
                          </button>
                        </Link>
                        <button
                          onClick={() => handleDelete(product.id)}
                          disabled={deletingId === product.id || deleteMutation.isPending}
                          className="p-2 text-content-subtle hover:text-red-500 transition-colors disabled:opacity-50"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </SellerLayout>
  );
};
