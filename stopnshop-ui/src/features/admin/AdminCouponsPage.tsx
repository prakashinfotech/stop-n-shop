import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, X, Check, Loader2 } from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { couponsApi, type CreateCouponRequest } from '../../api/couponsApi';
import { brandsApi } from '../../api/brandsApi';
import { useToast } from '../../components/ui/Toast';

const APPLICABLE_LABEL: Record<number, string> = { 1: 'Product', 2: 'Brand', 3: 'Category', 4: 'Cart' };

const todayPlusYears = (years: number) => {
  const d = new Date();
  d.setFullYear(d.getFullYear() + years);
  return d.toISOString().split('T')[0];
};

const emptyForm = (): CreateCouponRequest => ({
  couponCode: '',
  offerName: '',
  offerType: 2,
  discountValue: 10,
  minOrderValue: 0,
  maxDiscountCap: null,
  startDate: new Date().toISOString().split('T')[0],
  endDate: todayPlusYears(1),
  applicableOn: 4,
  entityId: null,
  usageLimitPerUser: 1,
});

export const AdminCouponsPage: React.FC = () => {
  const qc = useQueryClient();
  const { showToast } = useToast();
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<CreateCouponRequest>(emptyForm());
  const [formError, setFormError] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['admin-coupons'],
    queryFn: () => couponsApi.adminList(1, 100).then((r) => r.data.data),
  });

  const { data: brands = [] } = useQuery({
    queryKey: ['brands'],
    queryFn: () => brandsApi.getAll().then((r) => r.data.data),
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isActive }: { id: number; isActive: boolean }) =>
      couponsApi.adminToggle(id, isActive),
    onSuccess: (_, vars) => {
      qc.invalidateQueries({ queryKey: ['admin-coupons'] });
      showToast(vars.isActive ? 'Coupon enabled' : 'Coupon disabled');
    },
    onError: () => showToast('Could not update coupon', 'error'),
  });

  const createMutation = useMutation({
    mutationFn: (body: CreateCouponRequest) => couponsApi.adminCreate(body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-coupons'] });
      setShowForm(false);
      setForm(emptyForm());
      setFormError('');
      showToast('Coupon created');
    },
    onError: (err: any) => {
      setFormError(err.response?.data?.message ?? 'Could not create coupon');
    },
  });

  const items = data?.items ?? [];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError('');
    if (!form.couponCode.trim()) { setFormError('Coupon code is required.'); return; }
    if (!form.offerName.trim())  { setFormError('Offer name is required.'); return; }
    if (form.discountValue <= 0) { setFormError('Discount value must be > 0.'); return; }
    if (new Date(form.endDate) <= new Date(form.startDate)) {
      setFormError('End date must be after start date.'); return;
    }
    if (form.applicableOn === 2 && !form.entityId) {
      setFormError('Brand-specific coupons need a brand.'); return;
    }
    createMutation.mutate({
      ...form,
      couponCode: form.couponCode.trim().toUpperCase(),
      offerName: form.offerName.trim(),
      maxDiscountCap: form.maxDiscountCap || null,
      entityId: form.applicableOn === 2 ? form.entityId : null,
    });
  };

  return (
    <AdminLayout>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="font-display text-3xl font-bold text-content">Coupons</h1>
          <p className="text-sm text-content-muted mt-1">
            All coupons stay active until disabled. Add brand-specific coupons to target a single brand.
          </p>
        </div>
        <button
          onClick={() => { setShowForm((v) => !v); setFormError(''); }}
          className="inline-flex items-center gap-2 bg-stone-900 hover:bg-brand-500 text-white text-sm font-semibold px-4 py-2.5 rounded-xl transition-colors"
        >
          {showForm ? <><X className="h-4 w-4" /> Cancel</> : <><Plus className="h-4 w-4" /> New Coupon</>}
        </button>
      </div>

      {showForm && (
        <form
          onSubmit={handleSubmit}
          className="bg-surface-elevated border border-outline/60 rounded-2xl p-6 mb-6 space-y-4"
        >
          {formError && (
            <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-3 py-2 text-sm">
              {formError}
            </div>
          )}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Field label="Coupon code *">
              <input
                type="text" value={form.couponCode}
                onChange={(e) => setForm({ ...form, couponCode: e.target.value.toUpperCase() })}
                placeholder="WELCOME10" required
                className="input-style font-mono"
              />
            </Field>
            <Field label="Offer name *">
              <input
                type="text" value={form.offerName}
                onChange={(e) => setForm({ ...form, offerName: e.target.value })}
                placeholder="Welcome 10% off" required
                className="input-style"
              />
            </Field>
            <Field label="Type *">
              <select
                value={form.offerType}
                onChange={(e) => setForm({ ...form, offerType: Number(e.target.value) })}
                className="input-style"
              >
                <option value={2}>Percentage off</option>
                <option value={1}>Flat ₹ off</option>
              </select>
            </Field>
            <Field label={form.offerType === 1 ? 'Discount (₹) *' : 'Discount (%) *'}>
              <input
                type="number" min={1} value={form.discountValue}
                onChange={(e) => setForm({ ...form, discountValue: Number(e.target.value) })}
                required className="input-style"
              />
            </Field>
            <Field label="Min order value (₹)">
              <input
                type="number" min={0} value={form.minOrderValue}
                onChange={(e) => setForm({ ...form, minOrderValue: Number(e.target.value) })}
                className="input-style"
              />
            </Field>
            <Field label="Max discount cap (₹)">
              <input
                type="number" min={0} value={form.maxDiscountCap ?? ''}
                onChange={(e) => setForm({ ...form, maxDiscountCap: e.target.value ? Number(e.target.value) : null })}
                placeholder="No cap" className="input-style"
              />
            </Field>
            <Field label="Start date *">
              <input
                type="date" value={form.startDate}
                onChange={(e) => setForm({ ...form, startDate: e.target.value })}
                required className="input-style"
              />
            </Field>
            <Field label="End date *">
              <input
                type="date" value={form.endDate}
                onChange={(e) => setForm({ ...form, endDate: e.target.value })}
                required className="input-style"
              />
            </Field>
            <Field label="Applies to *">
              <select
                value={form.applicableOn}
                onChange={(e) => setForm({ ...form, applicableOn: Number(e.target.value), entityId: null })}
                className="input-style"
              >
                <option value={4}>Entire cart</option>
                <option value={2}>Specific brand</option>
              </select>
            </Field>
            {form.applicableOn === 2 && (
              <Field label="Brand *">
                <select
                  value={form.entityId ?? ''}
                  onChange={(e) => setForm({ ...form, entityId: e.target.value ? Number(e.target.value) : null })}
                  required className="input-style"
                >
                  <option value="">Select brand</option>
                  {brands.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
                </select>
              </Field>
            )}
            <Field label="Uses per user">
              <input
                type="number" min={1} max={255} value={form.usageLimitPerUser}
                onChange={(e) => setForm({ ...form, usageLimitPerUser: Number(e.target.value) })}
                className="input-style"
              />
            </Field>
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => { setShowForm(false); setFormError(''); setForm(emptyForm()); }}
              className="px-4 py-2 text-sm font-semibold text-content-muted hover:text-content"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={createMutation.isPending}
              className="px-5 py-2 bg-stone-900 hover:bg-brand-500 text-white text-sm font-semibold rounded-xl transition-colors disabled:opacity-50"
            >
              {createMutation.isPending ? 'Creating…' : 'Create Coupon'}
            </button>
          </div>
        </form>
      )}

      <div className="bg-surface-elevated border border-outline/60 rounded-2xl overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-surface text-xs uppercase tracking-wider text-content-muted">
            <tr>
              <th className="text-left px-4 py-3">Code</th>
              <th className="text-left px-4 py-3">Discount</th>
              <th className="text-left px-4 py-3">Min Order</th>
              <th className="text-left px-4 py-3">Applies To</th>
              <th className="text-left px-4 py-3">Valid Till</th>
              <th className="text-left px-4 py-3">Status</th>
              <th className="text-right px-4 py-3">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-outline/60">
            {isLoading ? (
              <tr><td colSpan={7} className="px-4 py-10 text-center text-content-subtle">
                <Loader2 className="h-5 w-5 animate-spin inline" />
              </td></tr>
            ) : items.length === 0 ? (
              <tr><td colSpan={7} className="px-4 py-10 text-center text-content-subtle">
                No coupons yet. Click "New Coupon" to add one.
              </td></tr>
            ) : items.map((c) => (
              <tr key={c.couponId} className="hover:bg-surface">
                <td className="px-4 py-3">
                  <p className="font-mono font-bold text-content">{c.couponCode}</p>
                  <p className="text-xs text-content-muted">{c.offerName}</p>
                </td>
                <td className="px-4 py-3">
                  <span className="font-semibold text-content">
                    {c.offerType === 1 ? `₹${c.discountValue}` : `${c.discountValue}%`}
                  </span>
                  {c.maxDiscountCap && (
                    <span className="text-xs text-content-muted"> (max ₹{c.maxDiscountCap})</span>
                  )}
                </td>
                <td className="px-4 py-3 text-content">₹{c.minOrderValue}</td>
                <td className="px-4 py-3">
                  <span className="inline-block bg-surface-sunken text-content text-xs font-medium rounded-full px-2.5 py-0.5">
                    {APPLICABLE_LABEL[c.applicableOn]}
                    {c.brandName ? `: ${c.brandName}` : ''}
                  </span>
                </td>
                <td className="px-4 py-3 text-content-muted text-xs">
                  {new Date(c.endDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
                </td>
                <td className="px-4 py-3">
                  {c.isActive ? (
                    <span className="inline-flex items-center gap-1 text-xs font-semibold text-green-700 bg-green-50 border border-green-200 rounded-full px-2 py-0.5">
                      <Check className="h-3 w-3" /> Active
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 text-xs font-semibold text-content-muted bg-surface-sunken border border-outline rounded-full px-2 py-0.5">
                      Disabled
                    </span>
                  )}
                </td>
                <td className="px-4 py-3 text-right">
                  <button
                    onClick={() => toggleMutation.mutate({ id: c.couponId, isActive: !c.isActive })}
                    disabled={toggleMutation.isPending}
                    className={`text-xs font-bold tracking-widest transition-colors ${
                      c.isActive ? 'text-red-500 hover:text-red-700' : 'text-green-600 hover:text-green-800'
                    }`}
                  >
                    {c.isActive ? 'DISABLE' : 'ENABLE'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <style>{`.input-style { width: 100%; padding: 0.5rem 0.75rem; border: 1px solid rgb(229 231 235); border-radius: 0.5rem; font-size: 0.875rem; outline: none; }
        .input-style:focus { border-color: rgb(196 18 48); }`}</style>
    </AdminLayout>
  );
};

const Field: React.FC<{ label: string; children: React.ReactNode }> = ({ label, children }) => (
  <div>
    <label className="block text-xs font-semibold text-content-muted mb-1">{label}</label>
    {children}
  </div>
);
