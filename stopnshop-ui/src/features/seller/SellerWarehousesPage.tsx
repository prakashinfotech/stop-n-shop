import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { Plus, Star, MapPin } from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { Spinner } from '../../components/ui/Spinner';
import { sellerLifecycleApi, type UpsertWarehouseRequest } from '../../api/sellerLifecycleApi';

export const SellerWarehousesPage: React.FC = () => {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);

  const { data: warehouses, isLoading } = useQuery({
    queryKey: ['seller-warehouses'],
    queryFn: () => sellerLifecycleApi.warehouses.list().then(r => r.data.data),
    staleTime: 60_000,
  });

  const upsertMutation = useMutation({
    mutationFn: (req: UpsertWarehouseRequest) => sellerLifecycleApi.warehouses.upsert(req),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['seller-warehouses'] });
      setShowForm(false);
    },
  });

  const { register, handleSubmit, reset, formState: { errors } } = useForm<UpsertWarehouseRequest>();

  const onSubmit = (data: UpsertWarehouseRequest) => {
    upsertMutation.mutate(data, { onSuccess: () => reset() });
  };

  return (
    <SellerLayout>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-display font-bold text-content mb-2">Warehouses</h1>
          <p className="text-content-muted">Pickup locations used to ship customer orders.</p>
        </div>
        <button onClick={() => setShowForm(s => !s)}
                className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg hover:bg-brand-700 font-medium">
          <Plus size={16} /> Add warehouse
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit(onSubmit)}
              className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-6 mb-6 grid grid-cols-1 md:grid-cols-2 gap-4">
          <input {...register('name', { required: true })} placeholder="Warehouse name" className="px-3 py-2 border rounded-md md:col-span-2" />
          <input {...register('contactName')} placeholder="Contact name (optional)" className="px-3 py-2 border rounded-md" />
          <input {...register('contactPhone')} placeholder="Contact phone (optional)" className="px-3 py-2 border rounded-md" />
          <input {...register('addressLine1', { required: true })} placeholder="Address line 1" className="px-3 py-2 border rounded-md md:col-span-2" />
          <input {...register('addressLine2')} placeholder="Address line 2 (optional)" className="px-3 py-2 border rounded-md md:col-span-2" />
          <input {...register('city', { required: true })} placeholder="City" className="px-3 py-2 border rounded-md" />
          <input {...register('state', { required: true })} placeholder="State" className="px-3 py-2 border rounded-md" />
          <input {...register('pincode', { required: true })} placeholder="Pincode" className="px-3 py-2 border rounded-md" />
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" {...register('isPrimary')} /> Set as primary pickup
          </label>
          <div className="md:col-span-2 flex justify-end gap-3">
            {Object.keys(errors).length > 0 && (
              <span className="text-sm text-rose-700 self-center">Please fill all required fields.</span>
            )}
            <button type="button" onClick={() => setShowForm(false)}
                    className="px-4 py-2 border border-outline rounded-lg hover:bg-surface">Cancel</button>
            <button type="submit" disabled={upsertMutation.isPending}
                    className="px-4 py-2 bg-brand-600 text-white rounded-lg disabled:opacity-50">
              {upsertMutation.isPending ? 'Saving…' : 'Save warehouse'}
            </button>
          </div>
        </form>
      )}

      {isLoading ? (
        <div className="flex justify-center py-16"><Spinner /></div>
      ) : !warehouses || warehouses.length === 0 ? (
        <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-16 text-center text-content-muted">
          No warehouses on file yet — add one so couriers can collect orders.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {warehouses.map(w => (
            <div key={w.sellerWarehouseId}
                 className={`bg-surface-elevated rounded-2xl shadow-soft border p-6 ${w.isPrimary ? 'border-brand-500 ring-1 ring-brand-200' : 'border-outline/60'}`}>
              <div className="flex items-start justify-between">
                <div>
                  <p className="font-semibold text-content flex items-center gap-2">
                    <MapPin size={16} className="text-brand-600" /> {w.name}
                  </p>
                  <p className="text-sm text-content-muted mt-2">{w.addressLine1}{w.addressLine2 ? `, ${w.addressLine2}` : ''}</p>
                  <p className="text-sm text-content-muted">{w.city}, {w.state} — {w.pincode}</p>
                  {(w.contactName || w.contactPhone) && (
                    <p className="text-xs text-content-subtle mt-2">
                      {w.contactName} {w.contactPhone ? `· ${w.contactPhone}` : ''}
                    </p>
                  )}
                </div>
                {w.isPrimary && (
                  <span className="inline-flex items-center gap-1 px-2 py-1 bg-brand-50 text-brand-700 rounded-full text-xs font-medium">
                    <Star size={12} /> Primary
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </SellerLayout>
  );
};
