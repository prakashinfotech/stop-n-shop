import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Plus, MapPin, Star, X, Check } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { addressesApi } from '../../api/addressesApi';
import { useToast } from '../../components/ui/Toast';
import type { AddAddressRequest } from '../../types/cart.types';

const addressSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  mobile: z.string().length(10, 'Enter valid 10-digit mobile'),
  line1: z.string().min(3, 'Address line 1 is required'),
  line2: z.string().optional(),
  city: z.string().min(2, 'City is required'),
  state: z.string().min(2, 'State is required'),
  pincode: z.string().length(6, 'Enter valid 6-digit pincode'),
  isDefault: z.boolean().optional(),
});

type AddressForm = z.infer<typeof addressSchema>;

export const AddressesPage: React.FC = () => {
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);

  const { data: addresses = [], isLoading } = useQuery({
    queryKey: ['addresses'],
    queryFn: () => addressesApi.getAddresses().then((r) => r.data.data),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<AddressForm>({ resolver: zodResolver(addressSchema) });

  const addMutation = useMutation({
    mutationFn: (data: AddAddressRequest) => addressesApi.addAddress(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['addresses'] });
      showToast('Address saved');
      closeModal();
    },
    onError: () => showToast('Failed to save address', 'error'),
  });

  const defaultMutation = useMutation({
    mutationFn: (id: number) => addressesApi.setDefault(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['addresses'] });
      showToast('Default address updated');
    },
    onError: () => showToast('Failed to update default', 'error'),
  });

  const openAdd = () => {
    reset({ name: '', mobile: '', line1: '', line2: '', city: '', state: '', pincode: '', isDefault: false });
    setModalOpen(true);
  };

  const closeModal = () => {
    setModalOpen(false);
    reset();
  };

  const onSubmit = (data: AddressForm) => {
    addMutation.mutate(data as AddAddressRequest);
  };

  const isPending = addMutation.isPending;

  return (
    <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-2xl font-bold text-content">Saved Addresses</h1>
          <p className="text-sm text-content-muted mt-1">{addresses.length} address{addresses.length !== 1 ? 'es' : ''} saved</p>
        </div>
        <button
          onClick={openAdd}
          className="flex items-center gap-2 px-4 py-2.5 bg-brand-500 hover:bg-brand-600 text-white rounded-xl text-sm font-semibold transition-colors"
        >
          <Plus className="h-4 w-4" /> Add New
        </button>
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {[1, 2].map((i) => (
            <div key={i} className="h-32 bg-surface-sunken rounded-2xl animate-pulse" />
          ))}
        </div>
      ) : addresses.length === 0 ? (
        <div className="text-center py-20 bg-surface-elevated rounded-2xl border border-outline/60">
          <div className="w-16 h-16 bg-brand-50 rounded-full flex items-center justify-center mx-auto mb-4">
            <MapPin className="h-7 w-7 text-brand-400" />
          </div>
          <p className="font-semibold text-content mb-1">No addresses saved</p>
          <p className="text-sm text-content-muted mb-6">Add an address for faster checkout</p>
          <button
            onClick={openAdd}
            className="px-5 py-2.5 bg-brand-500 text-white rounded-xl text-sm font-semibold hover:bg-brand-600 transition-colors"
          >
            Add First Address
          </button>
        </div>
      ) : (
        <div className="space-y-3">
          <AnimatePresence initial={false}>
            {addresses.map((addr) => (
              <motion.div
                key={addr.id}
                layout
                initial={{ opacity: 0, y: -8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.97 }}
                className={`bg-surface-elevated rounded-2xl border p-5 transition-colors ${
                  addr.isDefault ? 'border-brand-300 ring-1 ring-brand-200' : 'border-outline/60'
                }`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <p className="font-semibold text-content">{addr.name}</p>
                      {addr.isDefault && (
                        <span className="text-[10px] font-bold bg-brand-100 text-brand-600 px-1.5 py-0.5 rounded-full flex items-center gap-1">
                          <Star className="h-2.5 w-2.5 fill-current" /> DEFAULT
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-content-muted leading-relaxed">
                      {addr.line1}{addr.line2 ? `, ${addr.line2}` : ''}<br />
                      {addr.city}, {addr.state} – {addr.pincode}
                    </p>
                    <p className="text-sm text-content-muted mt-1">{addr.mobile}</p>
                  </div>
                  <div className="flex items-center gap-1 flex-shrink-0" />
                </div>
                {!addr.isDefault && (
                  <button
                    onClick={() => defaultMutation.mutate(addr.id)}
                    disabled={defaultMutation.isPending}
                    className="mt-3 text-xs font-semibold text-brand-500 hover:text-brand-600 transition-colors"
                  >
                    Set as default
                  </button>
                )}
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}

      {/* Address modal */}
      <AnimatePresence>
        {modalOpen && (
          <div className="fixed inset-0 z-40 z-50 flex items-center justify-center">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={closeModal}
              className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="relative z-50 w-full max-w-lg mx-4 max-h-[90vh] bg-surface-elevated rounded-2xl shadow-2xl overflow-hidden flex flex-col"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-outline/60">
                <h3 className="font-display font-bold text-content">New Address</h3>
                <button onClick={closeModal} className="p-1 text-content-subtle hover:text-content-muted">
                  <X className="h-5 w-5" />
                </button>
              </div>

              <form onSubmit={handleSubmit(onSubmit)} className="flex-1 overflow-y-auto p-6 space-y-4">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="label-sm">Full Name *</label>
                    <input {...register('name')} className={fi(!!errors.name)} placeholder="Full name" />
                    {errors.name && <p className="err">{errors.name.message}</p>}
                  </div>
                  <div>
                    <label className="label-sm">Mobile *</label>
                    <input {...register('mobile')} className={fi(!!errors.mobile)} placeholder="10-digit mobile" maxLength={10} />
                    {errors.mobile && <p className="err">{errors.mobile.message}</p>}
                  </div>
                </div>

                <div>
                  <label className="label-sm">Address Line 1 *</label>
                  <input {...register('line1')} className={fi(!!errors.line1)} placeholder="House / flat / building" />
                  {errors.line1 && <p className="err">{errors.line1.message}</p>}
                </div>

                <div>
                  <label className="label-sm">Address Line 2</label>
                  <input {...register('line2')} className={fi(false)} placeholder="Street / area / landmark (optional)" />
                </div>

                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <label className="label-sm">City *</label>
                    <input {...register('city')} className={fi(!!errors.city)} placeholder="City" />
                    {errors.city && <p className="err">{errors.city.message}</p>}
                  </div>
                  <div>
                    <label className="label-sm">State *</label>
                    <input {...register('state')} className={fi(!!errors.state)} placeholder="State" />
                    {errors.state && <p className="err">{errors.state.message}</p>}
                  </div>
                  <div>
                    <label className="label-sm">Pincode *</label>
                    <input {...register('pincode')} className={fi(!!errors.pincode)} placeholder="6-digit" maxLength={6} />
                    {errors.pincode && <p className="err">{errors.pincode.message}</p>}
                  </div>
                </div>

                <label className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" {...register('isDefault')} className="rounded" />
                  <span className="text-sm text-content">Set as default address</span>
                </label>

                <div className="flex gap-3 pt-2">
                  <button
                    type="button"
                    onClick={closeModal}
                    className="flex-1 py-2.5 border border-outline rounded-xl text-sm font-semibold text-content hover:bg-surface transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isPending}
                    className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-brand-500 text-white rounded-xl text-sm font-semibold hover:bg-brand-600 transition-colors disabled:opacity-60"
                  >
                    <Check className="h-4 w-4" />
                    {isPending ? 'Saving…' : 'Save Address'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

const fi = (err: boolean) =>
  `w-full px-3.5 py-2.5 rounded-xl border text-sm focus:outline-none focus:ring-2 focus:ring-brand-100 focus:border-brand-400 transition-colors ${
    err ? 'border-red-300 bg-red-50' : 'border-outline bg-surface-elevated'
  }`;
