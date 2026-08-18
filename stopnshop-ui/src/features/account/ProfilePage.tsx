import React, { useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { User, Save, MapPin, Package, Heart, ChevronRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import { authApi } from '../../api/authApi';
import { useToast } from '../../components/ui/Toast';
import type { UpdateProfileRequest } from '../../types/auth.types';

const schema = z.object({
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().optional(),
  email: z.string().email('Invalid email').optional().or(z.literal('')),
  gender: z.enum(['Male', 'Female', 'Other', '']).optional(),
  dateOfBirth: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export const ProfilePage: React.FC = () => {
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const [isEditing, setIsEditing] = useState(false);

  const { data: profile, isLoading } = useQuery({
    queryKey: ['profile'],
    queryFn: () => authApi.getProfile().then((r) => r.data.data),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isDirty },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { firstName: '', lastName: '', email: '', gender: '', dateOfBirth: '' },
  });

  useEffect(() => {
    if (profile) {
      reset({
        firstName: profile.firstName ?? profile.name ?? '',
        lastName: profile.lastName ?? '',
        email: profile.email ?? '',
        gender: (profile.gender as FormValues['gender']) ?? '',
        dateOfBirth: profile.dateOfBirth ? profile.dateOfBirth.split('T')[0] : '',
      });
    }
  }, [profile, reset]);

  const updateMutation = useMutation({
    mutationFn: (data: UpdateProfileRequest) => authApi.updateProfile(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['profile'] });
      showToast('Profile updated successfully');
      setIsEditing(false);
    },
    onError: () => showToast('Failed to update profile', 'error'),
  });

  const onSubmit = (data: FormValues) => {
    const payload: UpdateProfileRequest = {
      firstName: data.firstName,
      lastName: data.lastName,
      email: data.email || undefined,
      gender: data.gender || undefined,
      dateOfBirth: data.dateOfBirth || undefined,
    };
    updateMutation.mutate(payload);
  };

  const userInitial = profile?.firstName?.[0]?.toUpperCase()
    ?? profile?.name?.[0]?.toUpperCase()
    ?? 'U';

  const displayName = profile?.firstName
    ? `${profile.firstName}${profile.lastName ? ' ' + profile.lastName : ''}`
    : profile?.name ?? 'My Account';

  if (isLoading) {
    return (
      <div className="max-w-2xl mx-auto px-4 py-10 space-y-4">
        <div className="h-8 bg-surface-sunken rounded animate-pulse w-40" />
        <div className="h-40 bg-surface-sunken rounded-2xl animate-pulse" />
        <div className="h-64 bg-surface-sunken rounded-2xl animate-pulse" />
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <h1 className="font-display text-2xl font-bold text-content mb-8">My Account</h1>

      {/* Avatar + Name hero */}
      <div className="bg-gradient-to-r from-brand-500 to-brand-700 rounded-2xl p-6 mb-6 flex items-center gap-5 text-white">
        <div className="w-16 h-16 rounded-full bg-surface-elevated/20 flex items-center justify-center text-2xl font-black flex-shrink-0">
          {userInitial}
        </div>
        <div>
          <p className="font-display text-xl font-bold">{displayName}</p>
          {profile?.email && <p className="text-sm opacity-80 mt-0.5">{profile.email}</p>}
          {profile?.mobile && <p className="text-sm opacity-80">{profile.mobile}</p>}
        </div>
      </div>

      {/* Quick links */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        {[
          { to: '/orders', icon: <Package className="h-5 w-5" />, label: 'Orders' },
          { to: '/addresses', icon: <MapPin className="h-5 w-5" />, label: 'Addresses' },
          { to: '/wishlist', icon: <Heart className="h-5 w-5" />, label: 'Wishlist' },
        ].map((item) => (
          <Link
            key={item.to}
            to={item.to}
            className="flex flex-col items-center gap-2 py-4 bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 hover:border-brand-200 hover:bg-brand-50 transition-colors text-content hover:text-brand-600"
          >
            {item.icon}
            <span className="text-xs font-semibold">{item.label}</span>
          </Link>
        ))}
      </div>

      {/* Profile form */}
      <div className="bg-surface-elevated rounded-2xl border border-outline/60 overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-outline/60">
          <div className="flex items-center gap-2">
            <User className="h-4 w-4 text-content-subtle" />
            <h2 className="font-semibold text-content">Personal Information</h2>
          </div>
          {!isEditing && (
            <button
              onClick={() => setIsEditing(true)}
              className="text-sm font-semibold text-brand-500 hover:text-brand-600"
            >
              Edit
            </button>
          )}
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-5">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-content-muted mb-1.5">First Name</label>
              <input
                {...register('firstName')}
                disabled={!isEditing}
                className={inputCls(!!errors.firstName, !isEditing)}
                placeholder="First name"
              />
              {errors.firstName && <p className="text-xs text-red-500 mt-1">{errors.firstName.message}</p>}
            </div>
            <div>
              <label className="block text-xs font-semibold text-content-muted mb-1.5">Last Name</label>
              <input
                {...register('lastName')}
                disabled={!isEditing}
                className={inputCls(false, !isEditing)}
                placeholder="Last name"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-content-muted mb-1.5">Email Address</label>
            <input
              {...register('email')}
              type="email"
              disabled={!isEditing}
              className={inputCls(!!errors.email, !isEditing)}
              placeholder="email@example.com"
            />
            {errors.email && <p className="text-xs text-red-500 mt-1">{errors.email.message}</p>}
          </div>

          <div>
            <label className="block text-xs font-semibold text-content-muted mb-1.5">Mobile</label>
            <input
              value={profile?.mobile ?? ''}
              disabled
              className={inputCls(false, true)}
              placeholder="Mobile number"
            />
            <p className="text-xs text-content-subtle mt-1">Mobile number cannot be changed</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-content-muted mb-1.5">Gender</label>
              <select
                {...register('gender')}
                disabled={!isEditing}
                className={inputCls(false, !isEditing)}
              >
                <option value="">Select gender</option>
                <option value="Male">Male</option>
                <option value="Female">Female</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-content-muted mb-1.5">Date of Birth</label>
              <input
                {...register('dateOfBirth')}
                type="date"
                disabled={!isEditing}
                className={inputCls(false, !isEditing)}
              />
            </div>
          </div>

          {isEditing && (
            <div className="flex gap-3 pt-2">
              <button
                type="button"
                onClick={() => { setIsEditing(false); reset(); }}
                className="px-5 py-2.5 border border-outline rounded-xl text-sm font-semibold text-content hover:bg-surface transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={updateMutation.isPending || !isDirty}
                className="flex items-center gap-2 px-5 py-2.5 bg-brand-500 hover:bg-brand-600 text-white rounded-xl text-sm font-semibold transition-colors disabled:opacity-60"
              >
                <Save className="h-4 w-4" />
                {updateMutation.isPending ? 'Saving…' : 'Save Changes'}
              </button>
            </div>
          )}
        </form>
      </div>

      {/* Account links */}
      <div className="mt-4 bg-surface-elevated rounded-2xl border border-outline/60 divide-y divide-outline/60">
        {[
          { to: '/addresses', label: 'Manage Addresses' },
          { to: '/orders', label: 'Order History' },
          { to: '/wishlist', label: 'Saved Wishlist' },
        ].map((item) => (
          <Link
            key={item.to}
            to={item.to}
            className="flex items-center justify-between px-6 py-4 hover:bg-surface transition-colors"
          >
            <span className="text-sm font-medium text-content">{item.label}</span>
            <ChevronRight className="h-4 w-4 text-content-subtle" />
          </Link>
        ))}
      </div>
    </div>
  );
};

function inputCls(hasError: boolean, disabled: boolean) {
  return [
    'w-full px-4 py-2.5 rounded-xl border text-sm transition-colors focus:outline-none',
    hasError ? 'border-red-300 focus:border-red-400 bg-red-50' : 'border-outline focus:border-brand-400',
    disabled ? 'bg-surface text-content-muted cursor-default' : 'bg-surface-elevated focus:ring-2 focus:ring-brand-100',
  ].join(' ');
}
