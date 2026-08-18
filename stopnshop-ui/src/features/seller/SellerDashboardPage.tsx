import React, { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Package, ShoppingCart, TrendingUp, AlertTriangle, ArrowRight,
  Truck, Wallet, Activity, CheckCircle2, Clock,
} from 'lucide-react';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { sellerApi } from '../../api/sellerApi';
import { sellerLifecycleApi, SETTLEMENT_STATUS_LABELS } from '../../api/sellerLifecycleApi';
import { PerformanceScoreCard } from './components/PerformanceScoreCard';

interface KPIProps {
  icon: React.ElementType;
  label: string;
  value: number | string;
  subtext?: string;
  to?: string;
  tone?: 'default' | 'warning' | 'brand';
}

const KPI: React.FC<KPIProps> = ({ icon: Icon, label, value, subtext, to, tone = 'default' }) => {
  const toneClasses =
    tone === 'warning'
      ? 'bg-amber-50 border-amber-200 hover:border-amber-300'
      : tone === 'brand'
        ? 'bg-brand-50 border-brand-200 hover:border-brand-300'
        : 'bg-surface-elevated border-outline/60 hover:border-outline-strong';

  const iconClasses =
    tone === 'warning'
      ? 'bg-amber-100 text-amber-600'
      : tone === 'brand'
        ? 'bg-brand-100 text-brand-600'
        : 'bg-surface text-content-muted';

  const Inner = (
    <div className={`group rounded-2xl p-5 border transition-all ${toneClasses} ${to ? 'cursor-pointer hover:shadow-md' : ''}`}>
      <div className="flex items-start justify-between mb-3">
        <div className={`p-2 rounded-lg ${iconClasses}`}>
          <Icon size={18} />
        </div>
        {to && <ArrowRight className="h-4 w-4 text-content-subtle opacity-0 group-hover:opacity-100 transition-opacity" />}
      </div>
      <p className="text-xs font-medium text-content-muted uppercase tracking-wide">{label}</p>
      <p className="text-2xl font-bold text-content mt-1">{value}</p>
      {subtext && <p className="text-[11px] text-content-subtle mt-1">{subtext}</p>}
    </div>
  );

  return to ? <Link to={to}>{Inner}</Link> : Inner;
};

function buildDailyRevenue(orders: any[]): { day: string; revenue: number; orders: number }[] {
  const buckets = new Map<string, { revenue: number; orders: number }>();
  const today = new Date();
  for (let i = 13; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    buckets.set(key, { revenue: 0, orders: 0 });
  }
  for (const o of orders) {
    const date = (o.orderDate || o.createdAt || '').slice(0, 10);
    if (!buckets.has(date)) continue;
    const b = buckets.get(date)!;
    b.revenue += Number(o.sellerTotalAmount ?? o.totalAmount ?? 0);
    b.orders += 1;
  }
  return Array.from(buckets.entries()).map(([key, v]) => ({
    day: new Date(key).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' }),
    revenue: v.revenue,
    orders: v.orders,
  }));
}

export const SellerDashboardPage: React.FC = () => {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['seller-dashboard'],
    queryFn: () => sellerApi.dashboard.getStats().then((r) => r.data.data),
    staleTime: 1000 * 60 * 5,
  });

  const { data: analytics } = useQuery({
    queryKey: ['seller-analytics'],
    queryFn: () => sellerApi.analytics.get().then((r) => r.data.data),
    staleTime: 1000 * 60 * 5,
  });

  const { data: ordersData } = useQuery({
    queryKey: ['seller-orders', 'dashboard'],
    queryFn: () => sellerApi.orders.getAll({ page: 1, pageSize: 200 }).then((r) => r.data.data),
    staleTime: 1000 * 60 * 3,
  });

  const { data: settlementsData } = useQuery({
    queryKey: ['seller-settlements', 'dashboard'],
    queryFn: () => sellerLifecycleApi.settlements.list(1, 5).then((r) => r.data.data),
    staleTime: 1000 * 60 * 5,
  });

  const allOrders: any[] = ordersData?.items ?? [];
  const dailyRevenue = useMemo(() => buildDailyRevenue(allOrders), [allOrders]);
  const totalRevenue14d = dailyRevenue.reduce((a, b) => a + b.revenue, 0);

  const actionItems = useMemo(() => {
    const pendingShipments = allOrders.filter((o) => {
      const s = (o.orderStatus ?? o.status ?? '').toLowerCase();
      return s === 'confirmed' || s === 'pending' || s === 'processing';
    }).length;
    return { pendingShipments };
  }, [allOrders]);

  const recentSettlements = settlementsData?.items ?? [];

  return (
    <SellerLayout>
      <div className="mb-6">
        <h1 className="text-3xl font-display font-bold text-content mb-1">Dashboard</h1>
        <p className="text-content-muted text-sm">
          Real-time snapshot of your store — last 14 days.
        </p>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface-elevated rounded-2xl shadow-soft p-6 animate-pulse h-32" />
          ))}
        </div>
      ) : stats ? (
        <>
          {/* KPI grid — clickable */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <KPI
              icon={TrendingUp}
              label="Revenue (14d)"
              value={`₹${totalRevenue14d.toLocaleString('en-IN')}`}
              subtext={`Avg ₹${Math.round(totalRevenue14d / 14).toLocaleString('en-IN')} / day`}
              tone="brand"
            />
            <KPI
              icon={ShoppingCart}
              label="Total Orders"
              value={stats.totalOrders}
              subtext="View all orders →"
              to="/seller/orders"
            />
            <KPI
              icon={Package}
              label="Active Products"
              value={`${stats.activeProducts}/${stats.totalProducts}`}
              subtext="Manage catalog →"
              to="/seller/products"
            />
            <KPI
              icon={AlertTriangle}
              label="Low Stock"
              value={stats.lowStockCount}
              subtext={stats.lowStockCount > 0 ? 'Restock now →' : 'All healthy'}
              to="/seller/inventory"
              tone={stats.lowStockCount > 0 ? 'warning' : 'default'}
            />
          </div>

          {/* Revenue chart + Action panel */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
            <div className="lg:col-span-2 bg-surface-elevated rounded-2xl shadow-soft p-6 border border-outline/60">
              <div className="flex items-end justify-between mb-4">
                <div>
                  <h2 className="text-base font-semibold text-content">Revenue trend</h2>
                  <p className="text-xs text-content-subtle">Last 14 days · daily total in ₹</p>
                </div>
                <Link to="/seller/orders" className="text-xs font-medium text-brand-500 hover:underline">
                  All orders →
                </Link>
              </div>
              <ResponsiveContainer width="100%" height={240}>
                <AreaChart data={dailyRevenue} margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
                  <defs>
                    <linearGradient id="revGrad14" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#c41230" stopOpacity={0.18} />
                      <stop offset="95%" stopColor="#c41230" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
                  <XAxis dataKey="day" tick={{ fontSize: 10, fill: '#9ca3af' }} axisLine={false} tickLine={false} interval={1} />
                  <YAxis tick={{ fontSize: 10, fill: '#9ca3af' }} axisLine={false} tickLine={false} tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}k`} />
                  <Tooltip
                    contentStyle={{ borderRadius: 12, border: '1px solid #f0f0f0', fontSize: 12 }}
                    formatter={(val) => [`₹${Number(val).toLocaleString('en-IN')}`, 'Revenue']}
                  />
                  <Area type="monotone" dataKey="revenue" stroke="#c41230" strokeWidth={2} fill="url(#revGrad14)" dot={{ r: 2, fill: '#c41230' }} activeDot={{ r: 4 }} />
                </AreaChart>
              </ResponsiveContainer>
            </div>

            {/* Action Required */}
            <div className="bg-surface-elevated rounded-2xl shadow-soft p-6 border border-outline/60">
              <h2 className="text-base font-semibold text-content mb-1 flex items-center gap-2">
                <Activity className="h-4 w-4 text-brand-500" />
                Action required
              </h2>
              <p className="text-xs text-content-subtle mb-4">Things waiting on you.</p>

              <div className="space-y-2">
                <Link to="/seller/orders" className="block group">
                  <div className="flex items-center justify-between p-3 rounded-xl bg-surface hover:bg-brand-50 border border-outline/60 transition-colors">
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-amber-100 text-amber-600">
                        <Truck className="h-4 w-4" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-content">Pending shipments</p>
                        <p className="text-[11px] text-content-muted">Orders to confirm or ship</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-lg font-bold text-content">{actionItems.pendingShipments}</span>
                      <ArrowRight className="h-3.5 w-3.5 text-content-subtle group-hover:translate-x-0.5 transition-transform" />
                    </div>
                  </div>
                </Link>

                <Link to="/seller/inventory" className="block group">
                  <div className="flex items-center justify-between p-3 rounded-xl bg-surface hover:bg-brand-50 border border-outline/60 transition-colors">
                    <div className="flex items-center gap-3">
                      <div className={`p-2 rounded-lg ${stats.lowStockCount > 0 ? 'bg-rose-100 text-rose-600' : 'bg-emerald-100 text-emerald-600'}`}>
                        <AlertTriangle className="h-4 w-4" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-content">Low stock items</p>
                        <p className="text-[11px] text-content-muted">SKUs below threshold</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-lg font-bold text-content">{stats.lowStockCount}</span>
                      <ArrowRight className="h-3.5 w-3.5 text-content-subtle group-hover:translate-x-0.5 transition-transform" />
                    </div>
                  </div>
                </Link>

                <Link to="/seller/products/new" className="block group">
                  <div className="flex items-center justify-between p-3 rounded-xl bg-brand-50 hover:bg-brand-100 border border-brand-200 transition-colors">
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-brand-500 text-white">
                        <Package className="h-4 w-4" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-brand-700">Add a product</p>
                        <p className="text-[11px] text-brand-600/80">Grow your catalog</p>
                      </div>
                    </div>
                    <ArrowRight className="h-3.5 w-3.5 text-brand-500 group-hover:translate-x-0.5 transition-transform" />
                  </div>
                </Link>
              </div>
            </div>
          </div>

          {/* Performance + Settlements row */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
            <PerformanceScoreCard />

            <div className="lg:col-span-2 bg-surface-elevated rounded-2xl shadow-soft p-6 border border-outline/60">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h2 className="text-base font-semibold text-content flex items-center gap-2">
                    <Wallet className="h-4 w-4 text-brand-500" />
                    Recent settlements
                  </h2>
                  <p className="text-xs text-content-subtle">Nightly payouts for delivered orders past return window.</p>
                </div>
                <Link to="/seller/settlements" className="text-xs font-medium text-brand-500 hover:underline">
                  View all →
                </Link>
              </div>

              {recentSettlements.length === 0 ? (
                <div className="text-center py-8 text-content-muted text-sm">
                  <Clock className="h-8 w-8 mx-auto mb-2 text-content-subtle" />
                  No settlements yet. They run nightly once orders complete the 7-day return window.
                </div>
              ) : (
                <div className="overflow-hidden rounded-xl border border-outline/60">
                  <table className="w-full text-sm">
                    <thead className="bg-surface text-content-muted text-xs uppercase tracking-wide">
                      <tr>
                        <th className="text-left px-3 py-2 font-medium">Period</th>
                        <th className="text-right px-3 py-2 font-medium">Gross</th>
                        <th className="text-right px-3 py-2 font-medium">Net payout</th>
                        <th className="text-right px-3 py-2 font-medium">Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-outline/60">
                      {recentSettlements.slice(0, 5).map((s) => {
                        const start = new Date(s.periodStart).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
                        const end = new Date(s.periodEnd).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
                        const statusLabel = SETTLEMENT_STATUS_LABELS[s.status] ?? 'Unknown';
                        const statusClass = s.status === 2
                          ? 'bg-emerald-50 text-emerald-700'
                          : s.status === 1
                            ? 'bg-amber-50 text-amber-700'
                            : 'bg-rose-50 text-rose-700';
                        return (
                          <tr key={s.settlementId} className="hover:bg-surface transition-colors">
                            <td className="px-3 py-2.5">
                              <Link to={`/seller/settlements/${s.settlementId}`} className="text-content hover:text-brand-500 font-medium">
                                {start} – {end}
                              </Link>
                            </td>
                            <td className="text-right px-3 py-2.5 text-content-muted">₹{s.grossSales.toLocaleString('en-IN')}</td>
                            <td className="text-right px-3 py-2.5 font-semibold text-content">₹{s.netPayout.toLocaleString('en-IN')}</td>
                            <td className="text-right px-3 py-2.5">
                              <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-medium ${statusClass}`}>
                                {s.status === 2 && <CheckCircle2 className="h-3 w-3" />}
                                {statusLabel}
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>

          {/* 30-day summary strip */}
          {analytics && (
            <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-6">
              <h2 className="text-base font-semibold text-content mb-4">Last 30 days summary</h2>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
                {[
                  { label: 'Revenue', value: `₹${analytics.totalRevenue.toLocaleString('en-IN')}` },
                  { label: 'Orders', value: analytics.totalOrders },
                  { label: 'Units Sold', value: analytics.totalUnitsSold },
                  { label: 'Avg Order Value', value: `₹${Math.round(analytics.averageOrderValue).toLocaleString('en-IN')}` },
                ].map(({ label, value }) => (
                  <div key={label}>
                    <p className="text-xs text-content-muted mb-1">{label}</p>
                    <p className="text-xl font-bold text-content">{value}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      ) : null}
    </SellerLayout>
  );
};
