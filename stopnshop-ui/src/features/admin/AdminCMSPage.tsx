import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2, ToggleLeft, ToggleRight, Image, Edit2, Upload } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { adminApi, type CmsBanner } from '../../api/adminApi';
import { useToast } from '../../components/ui/Toast';
import { validateBannerLink } from './validateBannerLink';

const SECTION_LABELS: Record<number, string> = {
  1: 'Section 1 – Hero',
  2: 'Section 2',
  3: 'Section 3',
  4: 'Section 4',
  5: 'Section 5',
  6: 'Section 6',
  7: 'Section 7',
};

interface FormState {
  bannerId?: number | null;
  title: string;
  subTitle?: string;
  imageUrl: string;
  mobileImageUrl?: string;
  linkUrl?: string;
  section: number;
  sortOrder: number;
  gapBelowPx: number;
  backgroundColor?: string;
  isActive: boolean;
  startDate?: string;
  endDate?: string;
}

export const AdminCMSPage: React.FC = () => {
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [form, setForm] = useState<FormState>({
    bannerId: null,
    title: '',
    subTitle: '',
    imageUrl: '',
    mobileImageUrl: '',
    linkUrl: '',
    section: 1,
    sortOrder: 0,
    gapBelowPx: 32,
    backgroundColor: '',
    isActive: true,
    startDate: '',
    endDate: '',
  });

  const { data: banners = [], isLoading } = useQuery({
    queryKey: ['admin-banners'],
    queryFn: () => adminApi.cms.getBanners().then((r) => r.data.data),
  });

  const upsertMutation = useMutation({
    mutationFn: (data: Partial<CmsBanner>) => adminApi.cms.upsertBanner(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-banners'] });
      // Invalidate public banner cache for the section being edited
      if (form.section) {
        queryClient.invalidateQueries({ queryKey: ['banners', form.section] });
      }
      showToast(editingId ? 'Banner updated' : 'Banner created');
      resetForm();
    },
    onError: () => showToast('Failed to save banner', 'error'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => adminApi.cms.deleteBanner(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-banners'] });
      // Invalidate all banner sections since we don't know which section was deleted
      for (let i = 1; i <= 7; i++) {
        queryClient.invalidateQueries({ queryKey: ['banners', i] });
      }
      showToast('Banner deleted');
    },
    onError: () => showToast('Failed to delete banner', 'error'),
  });

  const uploadMutation = useMutation({
    mutationFn: (file: File) => adminApi.cms.uploadImage(file),
    onSuccess: (response) => {
      const imageUrl = (response.data.data as any).imageUrl || (response.data.data as any).ImageUrl;
      setForm((p) => ({ ...p, imageUrl }));
      showToast('Image uploaded successfully');
    },
    onError: () => showToast('Failed to upload image', 'error'),
  });

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      uploadMutation.mutate(file);
    }
  };

  const resetForm = () => {
    setShowForm(false);
    setEditingId(null);
    setForm({
      bannerId: null,
      title: '',
      subTitle: '',
      imageUrl: '',
      mobileImageUrl: '',
      linkUrl: '',
      section: 1,
      sortOrder: 0,
      gapBelowPx: 32,
      backgroundColor: '',
      isActive: true,
      startDate: '',
      endDate: '',
    });
  };

  const handleAddClick = () => {
    resetForm();
    setShowForm(true);
  };

  const handleEditBanner = (banner: CmsBanner) => {
    setForm({
      bannerId: banner.bannerId,
      title: banner.title,
      subTitle: banner.subTitle || '',
      imageUrl: banner.imageUrl,
      mobileImageUrl: banner.mobileImageUrl || '',
      linkUrl: banner.linkUrl || '',
      section: banner.section,
      sortOrder: banner.sortOrder,
      gapBelowPx: banner.gapBelowPx ?? 32,
      backgroundColor: banner.backgroundColor ?? '',
      isActive: banner.isActive,
      startDate: banner.startDate ? banner.startDate.split('T')[0] : '',
      endDate: banner.endDate ? banner.endDate.split('T')[0] : '',
    });
    setEditingId(banner.bannerId || null);
    setShowForm(true);
  };

  const handleToggleActive = (banner: CmsBanner) => {
    upsertMutation.mutate({
      ...banner,
      bannerId: banner.bannerId,
      isActive: !banner.isActive,
    });
  };

  const handleSave = () => {
    if (!form.title || !form.imageUrl || form.section < 1 || form.section > 7) {
      showToast('Please fill in required fields', 'error');
      return;
    }

    const payload: Partial<CmsBanner> = {
      bannerId: form.bannerId || undefined,
      title: form.title,
      subTitle: form.subTitle || undefined,
      imageUrl: form.imageUrl,
      mobileImageUrl: form.mobileImageUrl || undefined,
      linkUrl: form.linkUrl || undefined,
      section: form.section,
      sortOrder: form.sortOrder,
      gapBelowPx: form.gapBelowPx,
      backgroundColor: form.backgroundColor?.trim() ? form.backgroundColor.trim() : null,
      isActive: form.isActive,
      startDate: form.startDate || undefined,
      endDate: form.endDate || undefined,
    };

    upsertMutation.mutate(payload);
  };

  const groupedBanners = Array.from({ length: 7 }, (_, i) => i + 1).map((section) => ({
    section,
    banners: banners.filter((b) => b.section === section),
  }));

  return (
    <AdminLayout>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-display font-bold text-content">CMS / Banners</h1>
          <p className="text-sm text-content-muted mt-1">Manage 7 home page banner sections with carousels and scheduling</p>
        </div>
        <button
          onClick={handleAddClick}
          className="flex items-center gap-2 px-4 py-2.5 bg-brand-500 text-white rounded-xl text-sm font-semibold hover:bg-brand-600 transition-colors"
        >
          <Plus className="h-4 w-4" /> Add Banner
        </button>
      </div>

      {/* Banner form */}
      <AnimatePresence>
        {showForm && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="mb-6 bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-6 space-y-4 overflow-hidden"
          >
            <h3 className="font-semibold text-content">
              {editingId ? 'Edit Banner' : 'New Banner'}
            </h3>

            {/* Section */}
            <div>
              <label className="text-xs text-content-muted font-medium mb-1.5 block">Section *</label>
              <select
                value={form.section}
                onChange={(e) => setForm((p) => ({ ...p, section: parseInt(e.target.value) }))}
                className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
              >
                {Object.entries(SECTION_LABELS).map(([num, label]) => (
                  <option key={num} value={num}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            {/* Title and Subtitle */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">Title *</label>
                <input
                  value={form.title}
                  onChange={(e) => setForm((p) => ({ ...p, title: e.target.value }))}
                  className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                  placeholder="Banner title"
                />
              </div>
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">Subtitle</label>
                <input
                  value={form.subTitle || ''}
                  onChange={(e) => setForm((p) => ({ ...p, subTitle: e.target.value }))}
                  className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                  placeholder="Optional subtitle"
                />
              </div>
            </div>

            {/* Images */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">Desktop Image URL *</label>
                <div className="flex gap-2">
                  <input
                    value={form.imageUrl}
                    onChange={(e) => setForm((p) => ({ ...p, imageUrl: e.target.value }))}
                    className="flex-1 border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                    placeholder="https://..."
                  />
                  <label className="flex items-center gap-2 px-3 py-2 bg-brand-50 border border-brand-200 text-brand-600 rounded-lg text-sm font-medium hover:bg-brand-100 cursor-pointer transition-colors">
                    <Upload className="h-4 w-4" />
                    <span>Upload</span>
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleImageUpload}
                      disabled={uploadMutation.isPending}
                      className="hidden"
                    />
                  </label>
                </div>
                {form.imageUrl && (
                  <img
                    src={form.imageUrl}
                    alt="Preview"
                    className="mt-2 h-24 w-24 object-cover rounded-lg border border-outline"
                  />
                )}
                {uploadMutation.isPending && (
                  <p className="mt-2 text-xs text-content-muted">Uploading image...</p>
                )}
              </div>
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">Mobile Image URL</label>
                <input
                  value={form.mobileImageUrl || ''}
                  onChange={(e) => setForm((p) => ({ ...p, mobileImageUrl: e.target.value }))}
                  className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                  placeholder="https://... (optional)"
                />
              </div>
            </div>

            {/* Link and Sort Order */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">Link URL</label>
                <input
                  value={form.linkUrl || ''}
                  onChange={(e) => setForm((p) => ({ ...p, linkUrl: e.target.value }))}
                  className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                  placeholder="/home/products?sortBy=LATEST" />
                {(() => {
                  const v = validateBannerLink(form.linkUrl);
                  if (v.ok) return null;
                  return (
                    <div className="mt-1.5 text-[11px] text-amber-700 bg-amber-50 border border-amber-200 rounded-md px-2 py-1.5">
                      <p>{v.reason}</p>
                      {v.suggestion && (
                        <button
                          type="button"
                          onClick={() => setForm((p) => ({ ...p, linkUrl: v.suggestion }))}
                          className="mt-1 inline-flex items-center gap-1 font-semibold text-amber-800 hover:underline"
                        >
                          Use <code className="bg-surface-elevated/60 px-1 rounded">{v.suggestion}</code>
                        </button>
                      )}
                    </div>
                  );
                })()}
              </div>
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">Sort Order</label>
                <input
                  type="number"
                  value={form.sortOrder}
                  onChange={(e) => setForm((p) => ({ ...p, sortOrder: parseInt(e.target.value) || 0 }))}
                  className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                  placeholder="0"
                />
              </div>
            </div>

            {/* Stack spacing + surface colour — control the home banner rhythm without a deploy. */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">
                  Spacing below (px)
                </label>
                <input
                  type="number"
                  min={0}
                  max={160}
                  value={form.gapBelowPx}
                  onChange={(e) => setForm((p) => ({ ...p, gapBelowPx: Math.max(0, parseInt(e.target.value) || 0) }))}
                  className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                  placeholder="32"
                />
                <p className="mt-1 text-[11px] text-content-subtle">Gap between this banner and the next one in the home stack.</p>
              </div>
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">
                  Surface colour
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    value={form.backgroundColor && /^#[0-9a-fA-F]{6}$/.test(form.backgroundColor) ? form.backgroundColor : '#ffffff'}
                    onChange={(e) => setForm((p) => ({ ...p, backgroundColor: e.target.value }))}
                    className="h-9 w-12 rounded-md border border-outline cursor-pointer"
                    aria-label="Pick surface colour"
                  />
                  <input
                    type="text"
                    value={form.backgroundColor ?? ''}
                    onChange={(e) => setForm((p) => ({ ...p, backgroundColor: e.target.value }))}
                    placeholder="(none)"
                    className="flex-1 border border-outline rounded-lg px-3 py-2 text-sm font-mono focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                  />
                  {form.backgroundColor && (
                    <button
                      type="button"
                      onClick={() => setForm((p) => ({ ...p, backgroundColor: '' }))}
                      className="text-[11px] text-content-muted hover:text-red-600"
                    >
                      Clear
                    </button>
                  )}
                </div>
                <p className="mt-1 text-[11px] text-content-subtle">Optional band behind the banner (e.g. <code>#faf6ec</code>).</p>
              </div>
            </div>

            {/* Dates */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">Start Date</label>
                <input
                  type="date"
                  value={form.startDate || ''}
                  onChange={(e) => setForm((p) => ({ ...p, startDate: e.target.value }))}
                  className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                />
              </div>
              <div>
                <label className="text-xs text-content-muted font-medium mb-1.5 block">End Date</label>
                <input
                  type="date"
                  value={form.endDate || ''}
                  onChange={(e) => setForm((p) => ({ ...p, endDate: e.target.value }))}
                  className="w-full border border-outline rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400"
                />
              </div>
            </div>

            {/* Active checkbox */}
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="is-active"
                checked={form.isActive}
                onChange={(e) => setForm((p) => ({ ...p, isActive: e.target.checked }))}
                className="w-4 h-4 rounded border-outline-strong text-brand-500 focus:ring-1 focus:ring-brand-400"
              />
              <label htmlFor="is-active" className="text-sm text-content">
                Active
              </label>
            </div>

            {/* Buttons */}
            <div className="flex gap-3 pt-2">
              <button
                onClick={handleSave}
                disabled={upsertMutation.isPending}
                className="px-5 py-2 bg-brand-500 text-white rounded-lg text-sm font-semibold hover:bg-brand-600 transition-colors disabled:opacity-60"
              >
                {upsertMutation.isPending ? 'Saving…' : editingId ? 'Update Banner' : 'Create Banner'}
              </button>
              <button
                onClick={resetForm}
                className="px-5 py-2 border border-outline text-content rounded-lg text-sm font-semibold hover:bg-surface transition-colors"
              >
                Cancel
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Banners grid by section */}
      {isLoading ? (
        <div className="space-y-8">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i}>
              <div className="h-6 bg-surface-sunken rounded w-32 mb-4 animate-pulse" />
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {Array.from({ length: 3 }).map((_, j) => (
                  <div key={j} className="aspect-video bg-surface-sunken rounded-lg animate-pulse" />
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : banners.length === 0 ? (
        <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-20 text-center">
          <Image className="h-10 w-10 text-content-subtle mx-auto mb-3" />
          <p className="text-content-subtle text-sm">No banners yet. Add your first banner above.</p>
        </div>
      ) : (
        <div className="space-y-8">
          {groupedBanners.map(({ section, banners: sectionBanners }) => (
            <div key={section}>
              {sectionBanners.length > 0 && (
                <>
                  <h3 className="text-sm font-semibold text-content mb-4">
                    {SECTION_LABELS[section]} ({sectionBanners.length})
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {sectionBanners.map((banner) => (
                      <div
                        key={banner.bannerId}
                        className="bg-surface-elevated rounded-lg border border-outline/60 overflow-hidden hover:border-brand-300 transition-colors"
                      >
                        <button
                          onClick={() => handleEditBanner(banner)}
                          className="w-full aspect-video bg-surface-sunken relative group"
                        >
                          {banner.imageUrl ? (
                            <img
                              src={banner.imageUrl}
                              alt={banner.title}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-content-subtle">
                              <Image className="h-8 w-8" />
                            </div>
                          )}
                          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                            <Edit2 className="h-5 w-5 text-white" />
                          </div>
                          <span
                            className={`absolute top-2 right-2 px-2 py-0.5 rounded-full text-xs font-semibold ${
                              banner.isActive
                                ? 'bg-green-500 text-white'
                                : 'bg-stone-400 text-white'
                            }`}
                          >
                            {banner.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </button>
                        <div className="p-3 space-y-2">
                          <p className="font-medium text-sm text-content line-clamp-2">
                            {banner.title}
                          </p>
                          <div className="flex items-center justify-between">
                            <span className="text-xs text-content-muted">#{banner.sortOrder}</span>
                            <div className="flex items-center gap-1">
                              <button
                                onClick={() => handleToggleActive(banner)}
                                className="p-1.5 text-content-subtle hover:text-brand-500 transition-colors"
                                title="Toggle active"
                              >
                                {banner.isActive ? (
                                  <ToggleRight className="h-4 w-4 text-green-500" />
                                ) : (
                                  <ToggleLeft className="h-4 w-4" />
                                )}
                              </button>
                              <button
                                onClick={() => deleteMutation.mutate(banner.bannerId || 0)}
                                className="p-1.5 text-content-subtle hover:text-red-500 transition-colors"
                                title="Delete"
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>
          ))}
        </div>
      )}
    </AdminLayout>
  );
};
