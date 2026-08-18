import React, { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Plus, Edit2, Trash2, ChevronDown, ChevronRight, ArrowUp, ArrowDown, X, Loader2, Layers,
} from 'lucide-react';
import { AdminLayout } from '../../components/admin/AdminLayout';
import { SubCategoryVariantsDrawer } from './SubCategoryVariantsDrawer';
import {
  adminCategoryApi,
  type AdminCategory,
  type AdminSubCategory,
  type CategoryUpsertPayload,
  type SubCategoryUpsertPayload,
} from '../../api/adminCategoryApi';
import { useToast } from '../../components/ui/Toast';

const slugify = (s: string) =>
  s.toLowerCase().trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');

type CatForm = CategoryUpsertPayload;
type SubForm = SubCategoryUpsertPayload;

const emptyCat = (menuId: number): CatForm => ({
  categoryId: null,
  menuId,
  categoryName: '',
  slugUrl: '',
  iconUrl: '',
  bannerUrl: '',
  sortOrder: 0,
  isFeatured: false,
  showInMegaMenu: true,
  metaTitle: '',
  metaDescription: '',
});

const emptySub = (categoryId: number): SubForm => ({
  subCategoryId: null,
  categoryId,
  subCategoryName: '',
  slugUrl: '',
  iconUrl: '',
  sortOrder: 0,
  isFeatured: false,
  showInMegaMenu: true,
  metaTitle: '',
  metaDescription: '',
});

export const AdminCategoriesPage: React.FC = () => {
  const qc = useQueryClient();
  const { showToast } = useToast();
  const [expanded, setExpanded] = useState<Set<number>>(new Set());
  const [editingCat, setEditingCat] = useState<CatForm | null>(null);
  const [editingSub, setEditingSub] = useState<SubForm | null>(null);
  const [variantsFor, setVariantsFor] = useState<{ id: number; name: string } | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['admin-categories-tree'],
    queryFn: () => adminCategoryApi.getTree(true),
  });

  const menuOptions = useMemo(() => {
    const seen = new Map<number, string>();
    (data?.categories ?? []).forEach((c) => {
      if (c.menuName) seen.set(c.menuId, c.menuName);
    });
    return Array.from(seen.entries()).sort((a, b) => a[0] - b[0]);
  }, [data]);

  const subsByCat = useMemo(() => {
    const m = new Map<number, AdminSubCategory[]>();
    (data?.subCategories ?? []).forEach((s) => {
      const list = m.get(s.categoryId) ?? [];
      list.push(s);
      m.set(s.categoryId, list);
    });
    return m;
  }, [data]);

  const invalidate = () => qc.invalidateQueries({ queryKey: ['admin-categories-tree'] });

  const upsertCat = useMutation({
    mutationFn: (p: CatForm) => adminCategoryApi.upsertCategory(p),
    onSuccess: () => { invalidate(); setEditingCat(null); showToast('Category saved.', 'success'); },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Save failed.', 'error'),
  });

  const upsertSub = useMutation({
    mutationFn: (p: SubForm) => adminCategoryApi.upsertSubCategory(p),
    onSuccess: () => { invalidate(); setEditingSub(null); showToast('Subcategory saved.', 'success'); },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Save failed.', 'error'),
  });

  const toggleCat = useMutation({
    mutationFn: ({ id, isActive, showInMegaMenu }: { id: number; isActive?: boolean; showInMegaMenu?: boolean }) =>
      adminCategoryApi.toggleCategory(id, { isActive, showInMegaMenu }),
    onSuccess: invalidate,
  });

  const toggleSub = useMutation({
    mutationFn: ({ id, isActive, showInMegaMenu }: { id: number; isActive?: boolean; showInMegaMenu?: boolean }) =>
      adminCategoryApi.toggleSubCategory(id, { isActive, showInMegaMenu }),
    onSuccess: invalidate,
  });

  const deleteCat = useMutation({
    mutationFn: (id: number) => adminCategoryApi.deleteCategory(id),
    onSuccess: () => { invalidate(); showToast('Category deleted.', 'success'); },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Delete failed.', 'error'),
  });

  const deleteSub = useMutation({
    mutationFn: (id: number) => adminCategoryApi.deleteSubCategory(id),
    onSuccess: () => { invalidate(); showToast('Subcategory deleted.', 'success'); },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Delete failed.', 'error'),
  });

  const reorderCats = useMutation({
    mutationFn: (items: { categoryId: number; sortOrder: number }[]) =>
      adminCategoryApi.reorderCategories(items),
    onSuccess: invalidate,
  });

  const reorderSubs = useMutation({
    mutationFn: (items: { subCategoryId: number; sortOrder: number }[]) =>
      adminCategoryApi.reorderSubCategories(items),
    onSuccess: invalidate,
  });

  const moveCat = (cat: AdminCategory, dir: -1 | 1) => {
    const peers = (data?.categories ?? []).filter((c) => c.menuId === cat.menuId)
      .sort((a, b) => a.sortOrder - b.sortOrder);
    const idx = peers.findIndex((c) => c.categoryId === cat.categoryId);
    const swap = peers[idx + dir];
    if (!swap) return;
    reorderCats.mutate([
      { categoryId: cat.categoryId,  sortOrder: swap.sortOrder },
      { categoryId: swap.categoryId, sortOrder: cat.sortOrder  },
    ]);
  };

  const moveSub = (sub: AdminSubCategory, dir: -1 | 1) => {
    const peers = (subsByCat.get(sub.categoryId) ?? [])
      .slice().sort((a, b) => a.sortOrder - b.sortOrder);
    const idx = peers.findIndex((s) => s.subCategoryId === sub.subCategoryId);
    const swap = peers[idx + dir];
    if (!swap) return;
    reorderSubs.mutate([
      { subCategoryId: sub.subCategoryId,  sortOrder: swap.sortOrder },
      { subCategoryId: swap.subCategoryId, sortOrder: sub.sortOrder  },
    ]);
  };

  const groupedByMenu = useMemo(() => {
    const m = new Map<number, AdminCategory[]>();
    (data?.categories ?? []).slice()
      .sort((a, b) => a.sortOrder - b.sortOrder || a.categoryName.localeCompare(b.categoryName))
      .forEach((c) => {
        const list = m.get(c.menuId) ?? [];
        list.push(c);
        m.set(c.menuId, list);
      });
    return m;
  }, [data]);

  return (
    <AdminLayout>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-display font-semibold text-content">Categories</h1>
          <p className="text-sm text-content-muted mt-1">
            Manage categories and subcategories. Hide items from the mega-menu without disabling them.
          </p>
        </div>
        <button
          onClick={() => setEditingCat(emptyCat(menuOptions[0]?.[0] ?? 1))}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 transition-colors"
        >
          <Plus className="h-4 w-4" />
          Add Category
        </button>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-24"><Loader2 className="h-6 w-6 animate-spin text-content-muted" /></div>
      ) : (
        <div className="space-y-8">
          {menuOptions.map(([menuId, menuName]) => {
            const cats = groupedByMenu.get(menuId) ?? [];
            return (
              <section key={menuId}>
                <h2 className="text-xs font-semibold uppercase tracking-wider text-content-muted mb-3">
                  {menuName}
                  <span className="ml-2 text-content-subtle font-normal normal-case tracking-normal">
                    · {cats.length} {cats.length === 1 ? 'category' : 'categories'}
                  </span>
                </h2>

                <div className="rounded-2xl shadow-soft bg-surface-elevated overflow-hidden">
                  {cats.length === 0 && (
                    <div className="px-6 py-8 text-sm text-content-muted text-center">
                      No categories under this menu.
                    </div>
                  )}
                  {cats.map((cat, i) => {
                    const subs = (subsByCat.get(cat.categoryId) ?? [])
                      .slice().sort((a, b) => a.sortOrder - b.sortOrder);
                    const isOpen = expanded.has(cat.categoryId);
                    return (
                      <div key={cat.categoryId} className="border-t border-outline/60 first:border-t-0">
                        <div className={`flex items-center gap-3 px-4 py-3 ${!cat.isActive ? 'opacity-50' : ''}`}>
                          <button
                            onClick={() => {
                              const next = new Set(expanded);
                              next.has(cat.categoryId) ? next.delete(cat.categoryId) : next.add(cat.categoryId);
                              setExpanded(next);
                            }}
                            className="p-1 text-content-muted hover:text-content"
                          >
                            {isOpen ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                          </button>

                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="font-medium text-content truncate">{cat.categoryName}</span>
                              <span className="text-xs text-content-subtle">/{cat.slugUrl}</span>
                            </div>
                            <div className="text-xs text-content-muted mt-0.5">
                              {cat.subCategoryCount} subcategories · {cat.productCount} products
                            </div>
                          </div>

                          <div className="flex items-center gap-1">
                            <button onClick={() => moveCat(cat, -1)} disabled={i === 0}
                              className="p-1.5 text-content-muted hover:text-content disabled:opacity-30">
                              <ArrowUp className="h-4 w-4" />
                            </button>
                            <button onClick={() => moveCat(cat, 1)} disabled={i === cats.length - 1}
                              className="p-1.5 text-content-muted hover:text-content disabled:opacity-30">
                              <ArrowDown className="h-4 w-4" />
                            </button>
                          </div>

                          <label className="flex items-center gap-1.5 text-xs text-content-muted px-2">
                            <input
                              type="checkbox"
                              checked={cat.showInMegaMenu}
                              onChange={(e) => toggleCat.mutate({ id: cat.categoryId, showInMegaMenu: e.target.checked })}
                              className="rounded border-outline"
                            />
                            Mega-menu
                          </label>
                          <label className="flex items-center gap-1.5 text-xs text-content-muted px-2">
                            <input
                              type="checkbox"
                              checked={cat.isActive}
                              onChange={(e) => toggleCat.mutate({ id: cat.categoryId, isActive: e.target.checked })}
                              className="rounded border-outline"
                            />
                            Active
                          </label>

                          <button
                            onClick={() => setEditingCat({
                              categoryId: cat.categoryId,
                              menuId: cat.menuId,
                              categoryName: cat.categoryName,
                              slugUrl: cat.slugUrl,
                              iconUrl: cat.iconUrl ?? '',
                              bannerUrl: cat.bannerUrl ?? '',
                              sortOrder: cat.sortOrder,
                              isFeatured: cat.isFeatured,
                              showInMegaMenu: cat.showInMegaMenu,
                              metaTitle: cat.metaTitle ?? '',
                              metaDescription: cat.metaDescription ?? '',
                            })}
                            className="p-1.5 text-content-muted hover:text-brand-500"
                          >
                            <Edit2 className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => setEditingSub(emptySub(cat.categoryId))}
                            className="px-2 py-1 text-xs font-medium text-brand-600 hover:text-brand-700"
                            title="Add subcategory"
                          >
                            + Sub
                          </button>
                          <button
                            onClick={() => {
                              if (confirm(`Delete "${cat.categoryName}"?`)) deleteCat.mutate(cat.categoryId);
                            }}
                            className="p-1.5 text-content-muted hover:text-red-600"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>

                        {isOpen && (
                          <div className="bg-surface px-4 pb-3">
                            {subs.length === 0 ? (
                              <div className="px-4 py-3 text-xs text-content-muted">No subcategories yet.</div>
                            ) : (
                              <table className="w-full text-sm">
                                <thead>
                                  <tr className="text-xs uppercase tracking-wider text-content-subtle">
                                    <th className="text-left px-3 py-2 w-10"></th>
                                    <th className="text-left px-3 py-2">Subcategory</th>
                                    <th className="text-left px-3 py-2">Slug</th>
                                    <th className="text-right px-3 py-2">Products</th>
                                    <th className="text-center px-3 py-2">Mega-menu</th>
                                    <th className="text-center px-3 py-2">Active</th>
                                    <th className="text-right px-3 py-2 w-32">Actions</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {subs.map((sub, j) => (
                                    <tr key={sub.subCategoryId}
                                        className={`border-t border-outline/40 ${!sub.isActive ? 'opacity-50' : ''}`}>
                                      <td className="px-3 py-2">
                                        <div className="flex flex-col">
                                          <button onClick={() => moveSub(sub, -1)} disabled={j === 0}
                                            className="text-content-muted hover:text-content disabled:opacity-30 leading-none">
                                            <ArrowUp className="h-3.5 w-3.5" />
                                          </button>
                                          <button onClick={() => moveSub(sub, 1)} disabled={j === subs.length - 1}
                                            className="text-content-muted hover:text-content disabled:opacity-30 leading-none">
                                            <ArrowDown className="h-3.5 w-3.5" />
                                          </button>
                                        </div>
                                      </td>
                                      <td className="px-3 py-2 text-content">{sub.subCategoryName}</td>
                                      <td className="px-3 py-2 text-content-subtle text-xs">/{sub.slugUrl}</td>
                                      <td className="px-3 py-2 text-right text-content-muted">{sub.productCount}</td>
                                      <td className="px-3 py-2 text-center">
                                        <input
                                          type="checkbox"
                                          checked={sub.showInMegaMenu}
                                          onChange={(e) => toggleSub.mutate({ id: sub.subCategoryId, showInMegaMenu: e.target.checked })}
                                          className="rounded border-outline"
                                        />
                                      </td>
                                      <td className="px-3 py-2 text-center">
                                        <input
                                          type="checkbox"
                                          checked={sub.isActive}
                                          onChange={(e) => toggleSub.mutate({ id: sub.subCategoryId, isActive: e.target.checked })}
                                          className="rounded border-outline"
                                        />
                                      </td>
                                      <td className="px-3 py-2 text-right">
                                        <button
                                          onClick={() => setVariantsFor({ id: sub.subCategoryId, name: sub.subCategoryName })}
                                          className="p-1.5 text-content-muted hover:text-brand-500"
                                          title="Variant library"
                                        >
                                          <Layers className="h-4 w-4" />
                                        </button>
                                        <button
                                          onClick={() => setEditingSub({
                                            subCategoryId: sub.subCategoryId,
                                            categoryId: sub.categoryId,
                                            subCategoryName: sub.subCategoryName,
                                            slugUrl: sub.slugUrl,
                                            iconUrl: sub.iconUrl ?? '',
                                            sortOrder: sub.sortOrder,
                                            isFeatured: sub.isFeatured,
                                            showInMegaMenu: sub.showInMegaMenu,
                                            metaTitle: sub.metaTitle ?? '',
                                            metaDescription: sub.metaDescription ?? '',
                                          })}
                                          className="p-1.5 text-content-muted hover:text-brand-500"
                                        >
                                          <Edit2 className="h-4 w-4" />
                                        </button>
                                        <button
                                          onClick={() => {
                                            if (confirm(`Delete "${sub.subCategoryName}"?`)) deleteSub.mutate(sub.subCategoryId);
                                          }}
                                          className="p-1.5 text-content-muted hover:text-red-600"
                                        >
                                          <Trash2 className="h-4 w-4" />
                                        </button>
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            )}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </section>
            );
          })}
        </div>
      )}

      {/* Category modal */}
      {editingCat && (
        <Modal title={editingCat.categoryId ? 'Edit Category' : 'Add Category'} onClose={() => setEditingCat(null)}>
          <div className="space-y-3">
            <Field label="Menu">
              <select
                value={editingCat.menuId}
                onChange={(e) => setEditingCat({ ...editingCat, menuId: Number(e.target.value) })}
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
              >
                {menuOptions.map(([id, name]) => <option key={id} value={id}>{name}</option>)}
              </select>
            </Field>
            <Field label="Name">
              <input
                value={editingCat.categoryName}
                onChange={(e) => {
                  const name = e.target.value;
                  setEditingCat({
                    ...editingCat,
                    categoryName: name,
                    slugUrl: editingCat.categoryId ? editingCat.slugUrl : slugify(name),
                  });
                }}
                placeholder="e.g. Casual Wear"
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
              />
            </Field>
            <Field label="Slug">
              <input
                value={editingCat.slugUrl}
                onChange={(e) => setEditingCat({ ...editingCat, slugUrl: e.target.value })}
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm font-mono"
              />
            </Field>
            <div className="grid grid-cols-2 gap-3">
              <Field label="Icon URL">
                <input
                  value={editingCat.iconUrl ?? ''}
                  onChange={(e) => setEditingCat({ ...editingCat, iconUrl: e.target.value })}
                  className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
                />
              </Field>
              <Field label="Banner URL">
                <input
                  value={editingCat.bannerUrl ?? ''}
                  onChange={(e) => setEditingCat({ ...editingCat, bannerUrl: e.target.value })}
                  className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
                />
              </Field>
            </div>
            <Field label="Sort order">
              <input
                type="number"
                value={editingCat.sortOrder}
                onChange={(e) => setEditingCat({ ...editingCat, sortOrder: Number(e.target.value) })}
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
              />
            </Field>
            <div className="flex items-center gap-6">
              <label className="flex items-center gap-2 text-sm text-content">
                <input type="checkbox" checked={editingCat.isFeatured}
                  onChange={(e) => setEditingCat({ ...editingCat, isFeatured: e.target.checked })}
                  className="rounded border-outline" />
                Featured
              </label>
              <label className="flex items-center gap-2 text-sm text-content">
                <input type="checkbox" checked={editingCat.showInMegaMenu}
                  onChange={(e) => setEditingCat({ ...editingCat, showInMegaMenu: e.target.checked })}
                  className="rounded border-outline" />
                Show in mega-menu
              </label>
            </div>
          </div>
          <ModalActions
            onCancel={() => setEditingCat(null)}
            onSave={() => upsertCat.mutate(editingCat)}
            saving={upsertCat.isPending}
            disabled={!editingCat.categoryName.trim() || !editingCat.slugUrl.trim()}
          />
        </Modal>
      )}

      {/* Subcategory modal */}
      {editingSub && (
        <Modal title={editingSub.subCategoryId ? 'Edit Subcategory' : 'Add Subcategory'} onClose={() => setEditingSub(null)}>
          <div className="space-y-3">
            <Field label="Parent category">
              <select
                value={editingSub.categoryId}
                onChange={(e) => setEditingSub({ ...editingSub, categoryId: Number(e.target.value) })}
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
              >
                {(data?.categories ?? []).map((c) => (
                  <option key={c.categoryId} value={c.categoryId}>
                    {c.menuName} · {c.categoryName}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Name">
              <input
                value={editingSub.subCategoryName}
                onChange={(e) => {
                  const name = e.target.value;
                  setEditingSub({
                    ...editingSub,
                    subCategoryName: name,
                    slugUrl: editingSub.subCategoryId ? editingSub.slugUrl : slugify(name),
                  });
                }}
                placeholder="e.g. T-Shirts"
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
              />
            </Field>
            <Field label="Slug">
              <input
                value={editingSub.slugUrl}
                onChange={(e) => setEditingSub({ ...editingSub, slugUrl: e.target.value })}
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm font-mono"
              />
            </Field>
            <Field label="Icon URL">
              <input
                value={editingSub.iconUrl ?? ''}
                onChange={(e) => setEditingSub({ ...editingSub, iconUrl: e.target.value })}
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
              />
            </Field>
            <Field label="Sort order">
              <input
                type="number"
                value={editingSub.sortOrder}
                onChange={(e) => setEditingSub({ ...editingSub, sortOrder: Number(e.target.value) })}
                className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
              />
            </Field>
            <div className="flex items-center gap-6">
              <label className="flex items-center gap-2 text-sm text-content">
                <input type="checkbox" checked={editingSub.isFeatured}
                  onChange={(e) => setEditingSub({ ...editingSub, isFeatured: e.target.checked })}
                  className="rounded border-outline" />
                Featured
              </label>
              <label className="flex items-center gap-2 text-sm text-content">
                <input type="checkbox" checked={editingSub.showInMegaMenu}
                  onChange={(e) => setEditingSub({ ...editingSub, showInMegaMenu: e.target.checked })}
                  className="rounded border-outline" />
                Show in mega-menu
              </label>
            </div>
          </div>
          <ModalActions
            onCancel={() => setEditingSub(null)}
            onSave={() => upsertSub.mutate(editingSub)}
            saving={upsertSub.isPending}
            disabled={!editingSub.subCategoryName.trim() || !editingSub.slugUrl.trim()}
          />
        </Modal>
      )}

      {variantsFor && (
        <SubCategoryVariantsDrawer
          subCategoryId={variantsFor.id}
          subCategoryName={variantsFor.name}
          onClose={() => setVariantsFor(null)}
        />
      )}
    </AdminLayout>
  );
};

const Field: React.FC<{ label: string; children: React.ReactNode }> = ({ label, children }) => (
  <label className="block">
    <span className="text-xs font-medium text-content-muted mb-1 block">{label}</span>
    {children}
  </label>
);

const Modal: React.FC<{ title: string; onClose: () => void; children: React.ReactNode }> = ({ title, onClose, children }) => (
  <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div className="bg-surface-elevated rounded-2xl shadow-soft-lg w-full max-w-lg max-h-[90vh] overflow-y-auto">
      <div className="flex items-center justify-between px-6 py-4 border-b border-outline/60">
        <h3 className="text-lg font-semibold text-content">{title}</h3>
        <button onClick={onClose} className="text-content-muted hover:text-content">
          <X className="h-5 w-5" />
        </button>
      </div>
      <div className="p-6">{children}</div>
    </div>
  </div>
);

const ModalActions: React.FC<{
  onCancel: () => void; onSave: () => void; saving: boolean; disabled?: boolean;
}> = ({ onCancel, onSave, saving, disabled }) => (
  <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-outline/60 mt-2 -mx-6 -mb-6">
    <button onClick={onCancel} className="px-4 py-2 text-sm text-content-muted hover:text-content">
      Cancel
    </button>
    <button
      onClick={onSave}
      disabled={saving || disabled}
      className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 disabled:opacity-50"
    >
      {saving && <Loader2 className="h-4 w-4 animate-spin" />}
      Save
    </button>
  </div>
);
