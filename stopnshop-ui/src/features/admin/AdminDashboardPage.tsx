import React, { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Users, Package, ShoppingCart, TrendingUp, Clock, AlertCircle, Truck, XOctagon,
} from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { KpiCard } from '../../components/admin/KpiCard';
import { adminApi } from '../../api/adminApi';

function buildDailyOrders(orders: { createdAt: string }[]): { day: string; orders: number }[] {
  const buckets = new Map<string, number>();
  const today = new Date();
  for (let i = 13; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    buckets.set(d.toISOString().slice(0, 10), 0);
  }
  for (const o of orders) {
    const k = (o.createdAt || '').slice(0, 10);
    if (buckets.has(k)) buckets.set(k, buckets.get(k)! + 1);
  }
  return Array.from(buckets.entries()).map(([key, count]) => ({
    day: new Date(key).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' }),
    orders: count,
  }));
}

export const AdminDashboardPage: React.FC = () => {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['admin-stats'],
    queryFn: () => adminApi.dashboard.getStats().then((r) => r.data.data),
  });

  const { data: recentOrders } = useQuery({
    queryKey: ['admin-orders', 'dashboard-chart'],
    queryFn: () => adminApi.orders.getAll({ pageNo: 1, pageSize: 200 }).then((r) => r.data.data),
    staleTime: 1000 * 60 * 3,
  });

  const dailyOrders = useMemo(
    () => buildDailyOrders(recentOrders?.items ?? []),
    [recentOrders],
  );

  // Every card carries an href so the dashboard is a navigable index of the admin console.
  type Kpi = {
    icon: React.ComponentType<{ className?: string }>;
    label: string;
    value: React.ReactNode;
    href: string;
    tone?: 'default' | 'warning' | 'danger' | 'positive';
  };
  const kpis: Kpi[] = stats
    ? [
        { icon: Users,        label: 'Total Buyers',     value: stats.totalBuyers ?? stats.totalUsers ?? 0, href: '/admin/users?role=Buyer' },
        { icon: Users,        label: 'Sellers',          value: stats.totalSellers,                         href: '/admin/sellers?status=approved' },
        { icon: Clock,        label: 'Pending Sellers',  value: stats.pendingSellerApprovals,               href: '/admin/sellers?status=pending', tone: stats.pendingSellerApprovals > 0 ? 'warning' : 'default' },
        { icon: Package,      label: 'Total Products',   value: stats.totalProducts,                        href: '/admin/products' },
        { icon: AlertCircle,  label: 'Pending Products', value: stats.pendingProductApprovals,              href: '/admin/products/moderation', tone: stats.pendingProductApprovals > 0 ? 'warning' : 'default' },
        { icon: ShoppingCart, label: 'Total Orders',     value: stats.totalOrders,                          href: '/admin/orders' },
        { icon: Truck,        label: 'Unfulfilled',      value: stats.unfulfilledOrders ?? 0,               href: '/admin/orders?status=unfulfilled', tone: (stats.unfulfilledOrders ?? 0) > 0 ? 'warning' : 'default' },
        { icon: XOctagon,     label: 'Rejected Items',   value: stats.rejectedOrderItems ?? 0,              href: '/admin/orders?status=rejected', tone: (stats.rejectedOrderItems ?? 0) > 0 ? 'danger'  : 'default' },
        { icon: TrendingUp,   label: 'Revenue',          value: `₹${(stats.totalRevenue ?? 0).toLocaleString('en-IN')}`, href: '/admin/orders?paymentStatus=paid', tone: 'positive' },
      ]
    : [];

  return (
    <AdminLayout>
      <div className="mb-6">
        <h1 className="text-2xl font-display font-bold text-content">Platform Overview</h1>
        <p className="text-sm text-content-muted mt-1">Real-time stats across all users, sellers, and orders</p>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {Array.from({ length: 9 }).map((_, i) => (
            <div key={i} className="h-28 bg-surface-sunken rounded-xl animate-pulse" />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {kpis.map(({ icon: Icon, label, value, href, tone }) => (
            <KpiCard
              key={label}
              label={label}
              value={value}
              href={href}
              tone={tone}
              icon={<Icon className="h-4 w-4" />}
            />
          ))}
        </div>
      )}

      <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-5">
        <div className="flex items-end justify-between mb-4">
          <div>
            <h2 className="font-semibold text-content">Orders trend</h2>
            <p className="text-xs text-content-subtle">Last 14 days · platform-wide</p>
          </div>
        </div>
        <ResponsiveContainer width="100%" height={220}>
          <AreaChart data={dailyOrders} margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
            <defs>
              <linearGradient id="adminGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#c41230" stopOpacity={0.12} />
                <stop offset="95%" stopColor="#c41230" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="day" tick={{ fontSize: 10, fill: '#9ca3af' }} axisLine={false} tickLine={false} interval={1} />
            <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
            <Tooltip contentStyle={{ borderRadius: 10, fontSize: 12, border: '1px solid #f0f0f0' }} />
            <Area type="monotone" dataKey="orders" stroke="#c41230" strokeWidth={2} fill="url(#adminGrad)" dot={{ r: 3, fill: '#c41230' }} />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </AdminLayout>
  );
};
