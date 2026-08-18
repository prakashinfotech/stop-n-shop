import React from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Package, Truck, ArrowRight, MapPin } from 'lucide-react';
import { DispatcherLayout } from '../../components/layout/DispatcherLayout';
import { dispatcherApi } from '../../api/dispatcherApi';

/** Dispatcher home — counters + quick links. Mirrors the Today summary card
 *  pattern from the seller dashboard but with dispatcher-relevant numbers. */
export const DispatcherTodayPage: React.FC = () => {
  const pickupsQ = useQuery({
    queryKey: ['dispatcher-pickup-queue'],
    queryFn: () => dispatcherApi.getPickupQueue({ page: 1, pageSize: 50 }).then((r) => r.data.data),
    refetchInterval: 30_000,
  });

  const activeQ = useQuery({
    queryKey: ['dispatcher-active'],
    queryFn: () => dispatcherApi.getActive({ page: 1, pageSize: 50 }).then((r) => r.data.data),
    refetchInterval: 30_000,
  });

  const pickupCount  = pickupsQ.data?.totalCount ?? 0;
  const activeCount  = activeQ.data?.totalCount ?? 0;
  const claimedCount = (pickupsQ.data?.items ?? []).filter((i) => i.orderStatus === 10).length;

  return (
    <DispatcherLayout>
      <h1 className="text-2xl font-display font-bold text-content mb-1">Today</h1>
      <p className="text-sm text-content-muted mb-6">
        Your live queue. Updates every 30 seconds.
      </p>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <StatCard
          icon={<Package className="h-5 w-5" />}
          label="Pickups available"
          value={Math.max(0, pickupCount - claimedCount)}
          href="/dispatch/pickups"
          tone="brand"
        />
        <StatCard
          icon={<Truck className="h-5 w-5" />}
          label="Claimed at warehouse"
          value={claimedCount}
          href="/dispatch/pickups"
          tone="amber"
        />
        <StatCard
          icon={<MapPin className="h-5 w-5" />}
          label="Active deliveries"
          value={activeCount}
          href="/dispatch/active"
          tone="emerald"
        />
      </div>

      <div className="bg-surface-elevated rounded-2xl border border-outline/60 p-5 text-sm">
        <p className="text-content font-medium mb-1">What you can do today</p>
        <ul className="text-content-muted space-y-1 list-disc list-inside">
          <li>Open <Link to="/dispatch/pickups" className="text-brand-600 hover:underline">Pickups</Link> to claim Packed orders at your assigned warehouses.</li>
          <li>After collecting items, hit <strong>Confirm pickup</strong> to mark them dispatched.</li>
          <li>Track in-transit and out-for-delivery items under <Link to="/dispatch/active" className="text-brand-600 hover:underline">Active</Link>.</li>
          <li><span className="text-content-subtle">(Coming in L3)</span> Tap an active item to mark Out-for-Delivery, send the buyer OTP, and capture proof of delivery.</li>
        </ul>
      </div>
    </DispatcherLayout>
  );
};

interface StatCardProps {
  icon:  React.ReactNode;
  label: string;
  value: number;
  href:  string;
  tone:  'brand' | 'amber' | 'emerald';
}

const STAT_TONE: Record<StatCardProps['tone'], string> = {
  brand:   'bg-brand-50 text-brand-700',
  amber:   'bg-amber-50 text-amber-700',
  emerald: 'bg-emerald-50 text-emerald-700',
};

const StatCard: React.FC<StatCardProps> = ({ icon, label, value, href, tone }) => (
  <Link
    to={href}
    className="bg-surface-elevated rounded-2xl border border-outline/60 p-5 hover:border-outline-strong hover:shadow-soft transition group"
  >
    <div className="flex items-start justify-between gap-3">
      <div>
        <p className={`inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-widest px-2 py-0.5 rounded-full ${STAT_TONE[tone]}`}>
          {icon} {label}
        </p>
        <p className="font-display text-3xl font-bold text-content mt-3 tabular-nums">{value}</p>
      </div>
      <ArrowRight className="h-4 w-4 text-content-subtle group-hover:text-brand-500 transition-colors" />
    </div>
  </Link>
);
