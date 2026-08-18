import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Store, MapPin, Mail, Phone, CreditCard, BadgeCheck, Calendar } from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { sellerApi } from '../../api/sellerApi';
import { Spinner } from '../../components/ui/Spinner';

export const SellerProfilePage: React.FC = () => {
  const { data, isLoading, error } = useQuery({
    queryKey: ['seller-profile'],
    queryFn: () => sellerApi.auth.getProfile().then(r => r.data.data),
  });

  if (isLoading) {
    return (
      <SellerLayout>
        <div className="flex justify-center items-center h-64">
          <Spinner size="lg" />
        </div>
      </SellerLayout>
    );
  }

  if (error || !data) {
    return (
      <SellerLayout>
        <div className="bg-red-50 text-red-600 p-4 rounded-lg">
          Failed to load profile. Please try again.
        </div>
      </SellerLayout>
    );
  }

  const profile = data;
  const initial = (profile.businessName || profile.ownerName || 'S').charAt(0).toUpperCase();
  const p = profile as any;
  const addressLines = [
    [p.pickupAddressLine1, p.pickupAddressLine2].filter(Boolean).join(', '),
    [p.pickupCity, p.pickupState, p.pickupPincode].filter(Boolean).join(', '),
    p.pickupLandmark ? `Landmark: ${p.pickupLandmark}` : '',
  ].filter(Boolean);
  const hasAddress = addressLines.length > 0;

  return (
    <SellerLayout>
      {/* Hero banner */}
      <div className="relative mb-8 rounded-2xl overflow-hidden bg-gradient-brand text-white p-8 shadow-sm">
        <div className="absolute inset-0 opacity-10 bg-[radial-gradient(circle_at_top_right,_white,_transparent_60%)]" />
        <div className="relative flex flex-col sm:flex-row sm:items-center gap-6">
          <div className="w-20 h-20 rounded-2xl bg-surface-elevated/15 backdrop-blur flex items-center justify-center text-3xl font-bold ring-2 ring-white/30">
            {initial}
          </div>
          <div className="flex-1 min-w-0">
            <h1 className="text-3xl font-display font-bold truncate">
              {profile.businessName || 'Your Store'}
            </h1>
            <p className="text-white/80 mt-1 flex items-center gap-2 text-sm">
              <BadgeCheck size={16} /> Active Seller
              <span className="opacity-40">·</span>
              <Calendar size={14} />
              Joined {new Date(profile.createdAt).toLocaleDateString()}
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-2 space-y-6">
          <section className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-content mb-5 flex items-center gap-2">
              <Store className="text-brand-500" size={20} /> Business Details
            </h2>
            <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-5">
              <div>
                <dt className="text-xs uppercase tracking-wide text-content-muted mb-1">Business Name</dt>
                <dd className="font-medium text-content">{profile.businessName || '—'}</dd>
              </div>
              <div>
                <dt className="text-xs uppercase tracking-wide text-content-muted mb-1">Owner Name</dt>
                <dd className="font-medium text-content">{profile.ownerName || '—'}</dd>
              </div>
              <div>
                <dt className="text-xs uppercase tracking-wide text-content-muted mb-1">Joined On</dt>
                <dd className="font-medium text-content">{new Date(profile.createdAt).toLocaleDateString()}</dd>
              </div>
              {profile.gstNumber && (
                <div>
                  <dt className="text-xs uppercase tracking-wide text-content-muted mb-1 flex items-center gap-1">
                    <CreditCard size={12} /> GST Number
                  </dt>
                  <dd className="font-medium text-content">{profile.gstNumber}</dd>
                </div>
              )}
            </dl>
          </section>

          <section className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-content mb-5 flex items-center gap-2">
              <MapPin className="text-brand-500" size={20} /> Address Information
            </h2>
            {hasAddress ? (
              <div className="bg-surface p-4 rounded-lg text-content leading-relaxed space-y-1">
                {addressLines.map((line, i) => (
                  <p key={i}>{line}</p>
                ))}
              </div>
            ) : (
              <p className="text-sm text-content-muted italic">No pickup address on file yet.</p>
            )}
          </section>
        </div>

        <aside className="space-y-6">
          <section className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-content mb-5">Contact Info</h2>
            <div className="space-y-5">
              <div className="flex items-start gap-3">
                <div className="w-9 h-9 rounded-lg bg-red-50 text-brand-500 flex items-center justify-center shrink-0">
                  <Mail size={16} />
                </div>
                <div className="min-w-0">
                  <p className="text-xs uppercase tracking-wide text-content-muted">Registered Email</p>
                  <p className="font-medium text-content truncate">{profile.email}</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-9 h-9 rounded-lg bg-red-50 text-brand-500 flex items-center justify-center shrink-0">
                  <Phone size={16} />
                </div>
                <div>
                  <p className="text-xs uppercase tracking-wide text-content-muted">Phone Number</p>
                  <p className="font-medium text-content">{profile.phoneNumber || '—'}</p>
                </div>
              </div>
            </div>
          </section>
        </aside>
      </div>
    </SellerLayout>
  );
};
