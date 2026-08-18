import React, { useEffect, useMemo, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { X, Plus, Trash2, Loader2, Save } from 'lucide-react';
import {
  variantLibraryApi,
  type VariantAttribute,
  type SubCategoryVariantOption,
} from '../../api/variantLibraryApi';
import { adminCategoryApi } from '../../api/adminCategoryApi';
import { useToast } from '../../components/ui/Toast';

interface Props {
  subCategoryId: number;
  subCategoryName: string;
  onClose: () => void;
}

export const SubCategoryVariantsDrawer: React.FC<Props> = ({ subCategoryId, subCategoryName, onClose }) => {
  const qc = useQueryClient();
  const { showToast } = useToast();
  const [tab, setTab] = useState<'variants' | 'form-rules'>('variants');
  const [activeAttr, setActiveAttr] = useState<number | null>(null);
  const [newValue, setNewValue] = useState('');
  const [newMeta, setNewMeta] = useState('');

  const { data: attributes = [] } = useQuery({
    queryKey: ['variant-attributes'],
    queryFn: () => variantLibraryApi.getAttributes(),
  });

  const { data: options = [], isLoading } = useQuery({
    queryKey: ['variant-options', subCategoryId],
    queryFn: () => variantLibraryApi.getAdminOptions(subCategoryId),
  });

  const activeAttribute: VariantAttribute | undefined =
    attributes.find((a) => a.attributeId === activeAttr) ?? attributes[0];

  // Default-select first attribute once loaded
  React.useEffect(() => {
    if (activeAttr === null && attributes.length > 0) {
      setActiveAttr(attributes[0].attributeId);
    }
  }, [attributes, activeAttr]);

  const optionsForAttr: SubCategoryVariantOption[] = useMemo(() => {
    if (!activeAttribute) return [];
    return options
      .filter((o) => o.attributeId === activeAttribute.attributeId)
      .sort((a, b) => a.sortOrder - b.sortOrder || a.optionValue.localeCompare(b.optionValue));
  }, [options, activeAttribute]);

  const invalidate = () => qc.invalidateQueries({ queryKey: ['variant-options', subCategoryId] });

  const addOption = useMutation({
    mutationFn: () =>
      variantLibraryApi.upsertOption({
        subCategoryId,
        attributeId: activeAttribute!.attributeId,
        optionValue: newValue.trim(),
        optionMetadata: activeAttribute!.inputType === 'swatch' ? newMeta.trim() || null : null,
        sortOrder: (optionsForAttr[optionsForAttr.length - 1]?.sortOrder ?? 0) + 1,
      }),
    onSuccess: () => { invalidate(); setNewValue(''); setNewMeta(''); },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Add failed.', 'error'),
  });

  const toggleOption = useMutation({
    mutationFn: ({ id, isActive }: { id: number; isActive: boolean }) =>
      variantLibraryApi.toggleOption(id, isActive),
    onSuccess: invalidate,
  });

  const deleteOption = useMutation({
    mutationFn: (id: number) => variantLibraryApi.deleteOption(id),
    onSuccess: () => { invalidate(); showToast('Removed.', 'success'); },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Delete failed.', 'error'),
  });

  return (
    <div className="fixed inset-0 z-50 flex items-stretch justify-end bg-black/50">
      <aside className="w-full max-w-2xl bg-surface-elevated shadow-soft-lg h-full overflow-y-auto">
        <header className="sticky top-0 z-10 bg-surface-elevated border-b border-outline/60 px-6 py-4 flex items-center justify-between">
          <div>
            <p className="text-xs uppercase tracking-wider text-content-subtle">Variant library</p>
            <h2 className="text-lg font-semibold text-content">{subCategoryName}</h2>
          </div>
          <button onClick={onClose} className="text-content-muted hover:text-content">
            <X className="h-5 w-5" />
          </button>
        </header>

        {/* Top-level tab strip */}
        <div className="px-6 pt-4 flex gap-4 border-b border-outline/60">
          <button onClick={() => setTab('variants')}
            className={`pb-3 text-sm font-medium border-b-2 ${
              tab === 'variants' ? 'border-brand-500 text-brand-600' : 'border-transparent text-content-muted hover:text-content'
            }`}>
            Variant library
          </button>
          <button onClick={() => setTab('form-rules')}
            className={`pb-3 text-sm font-medium border-b-2 ${
              tab === 'form-rules' ? 'border-brand-500 text-brand-600' : 'border-transparent text-content-muted hover:text-content'
            }`}>
            Form rules
          </button>
        </div>

        {tab === 'form-rules' && (
          <FormRulesTab subCategoryId={subCategoryId} />
        )}

        {tab === 'variants' && (
        <div className="px-6 py-4">
          <p className="text-sm text-content-muted mb-4">
            Define the option values sellers can choose from for products in this subcategory.
            Disabling an option keeps existing product variants intact but hides it from new product wizards.
          </p>

          {/* Attribute tabs */}
          <div className="flex gap-1 border-b border-outline/60 overflow-x-auto">
            {attributes.map((a) => (
              <button
                key={a.attributeId}
                onClick={() => setActiveAttr(a.attributeId)}
                className={`px-4 py-2 text-sm font-medium border-b-2 whitespace-nowrap ${
                  activeAttribute?.attributeId === a.attributeId
                    ? 'border-brand-500 text-brand-600'
                    : 'border-transparent text-content-muted hover:text-content'
                }`}
              >
                {a.displayName}
              </button>
            ))}
          </div>

          {/* Add */}
          {activeAttribute && (
            <div className="mt-4 flex items-end gap-2">
              <label className="flex-1">
                <span className="text-xs font-medium text-content-muted block mb-1">Value</span>
                <input
                  value={newValue}
                  onChange={(e) => setNewValue(e.target.value)}
                  placeholder={
                    activeAttribute.attributeKey === 'size' ? 'e.g. XXL'
                    : activeAttribute.attributeKey === 'color' ? 'e.g. Maroon'
                    : 'e.g. Linen'
                  }
                  className="w-full px-3 py-2 rounded-lg border border-outline bg-surface-sunken text-sm"
                />
              </label>
              {activeAttribute.inputType === 'swatch' && (
                <label>
                  <span className="text-xs font-medium text-content-muted block mb-1">Hex</span>
                  <input
                    type="color"
                    value={newMeta || '#000000'}
                    onChange={(e) => setNewMeta(e.target.value.toUpperCase())}
                    className="h-10 w-16 rounded-lg border border-outline cursor-pointer"
                  />
                </label>
              )}
              <button
                onClick={() => addOption.mutate()}
                disabled={!newValue.trim() || addOption.isPending}
                className="inline-flex items-center gap-1 px-3 py-2 rounded-lg bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 disabled:opacity-50"
              >
                {addOption.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
                Add
              </button>
            </div>
          )}

          {/* Chips */}
          <div className="mt-6">
            {isLoading ? (
              <div className="flex items-center justify-center py-12">
                <Loader2 className="h-5 w-5 animate-spin text-content-muted" />
              </div>
            ) : optionsForAttr.length === 0 ? (
              <p className="text-sm text-content-muted py-8 text-center">
                No values defined yet. Add the first one above.
              </p>
            ) : (
              <ul className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {optionsForAttr.map((o) => (
                  <li
                    key={o.optionId}
                    className={`flex items-center gap-2 px-3 py-2 rounded-lg border ${
                      o.isActive ? 'border-outline bg-surface' : 'border-outline/40 bg-surface opacity-50'
                    }`}
                  >
                    {activeAttribute?.inputType === 'swatch' && (
                      <span
                        className="h-4 w-4 rounded-full border border-outline flex-shrink-0"
                        style={{ backgroundColor: o.optionMetadata ?? '#ccc' }}
                      />
                    )}
                    <span className="flex-1 text-sm text-content truncate">{o.optionValue}</span>
                    <label className="text-xs text-content-muted">
                      <input
                        type="checkbox"
                        checked={o.isActive}
                        onChange={(e) => toggleOption.mutate({ id: o.optionId, isActive: e.target.checked })}
                        className="rounded border-outline mr-1"
                      />
                      On
                    </label>
                    <button
                      onClick={() => {
                        if (confirm(`Remove "${o.optionValue}"?`)) deleteOption.mutate(o.optionId);
                      }}
                      className="text-content-muted hover:text-red-600"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
        )}
      </aside>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────
// Form rules tab — controls the seller wizard rendering per subcategory
// ─────────────────────────────────────────────────────────────────────

const ALL_SLOTS = ['front', 'back', 'left', 'right', 'top', 'bottom', 'detail'] as const;
const SIZE_SCALES = [
  { value: 'apparel',  label: 'Apparel (XS–XXXL)' },
  { value: 'shoe-uk',  label: 'Footwear (UK 5–12)' },
  { value: 'shoe-eu',  label: 'Footwear (EU 36–46)' },
  { value: 'toy',      label: 'Toys (Small/Medium/Large)' },
  { value: 'none',     label: 'None (no size picker)' },
];

const FormRulesTab: React.FC<{ subCategoryId: number }> = ({ subCategoryId }) => {
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data, isLoading } = useQuery({
    queryKey: ['admin-form-schema', subCategoryId],
    queryFn: () => adminCategoryApi.getFormSchema(subCategoryId),
  });

  type LocalState = {
    angleMode: 'multi' | 'single';
    angles: Set<string>;
    sizeScale: string;
    requiresGender: boolean;
    requiresDimensions: boolean;
  };
  const [state, setState] = useState<LocalState | null>(null);

  useEffect(() => {
    if (!data) return;
    const isSingle = data.imageAngles.length === 1 && data.imageAngles[0] === 'single';
    setState({
      angleMode:           isSingle ? 'single' : 'multi',
      angles:              new Set(isSingle ? [] : data.imageAngles),
      sizeScale:           data.sizeScale ?? 'none',
      requiresGender:      data.requiresGender,
      requiresDimensions:  data.requiresDimensions,
    });
  }, [data]);

  const save = useMutation({
    mutationFn: () => {
      if (!state) return Promise.resolve();
      const imageAngles = state.angleMode === 'single' ? ['single'] : Array.from(state.angles);
      return adminCategoryApi.updateFormRules(subCategoryId, {
        imageAngles,
        sizeScale: state.sizeScale,
        requiresGender: state.requiresGender,
        requiresDimensions: state.requiresDimensions,
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-form-schema', subCategoryId] });
      qc.invalidateQueries({ queryKey: ['form-schema', subCategoryId] });
      showToast('Form rules saved.', 'success');
    },
    onError: (e: any) => showToast(e?.response?.data?.message ?? 'Save failed.', 'error'),
  });

  if (isLoading || !state) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-5 w-5 animate-spin text-content-muted" />
      </div>
    );
  }

  return (
    <div className="px-6 py-5 space-y-6">
      <p className="text-sm text-content-muted">
        Controls how the seller add/edit wizard renders for this subcategory.
      </p>

      <div>
        <p className="text-sm font-medium text-content mb-2">Image angles</p>
        <div className="flex gap-2 mb-3">
          <button
            onClick={() => setState({ ...state, angleMode: 'multi' })}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium ${
              state.angleMode === 'multi' ? 'bg-brand-500 text-white' : 'bg-surface-sunken text-content'
            }`}>
            Multi-angle
          </button>
          <button
            onClick={() => setState({ ...state, angleMode: 'single' })}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium ${
              state.angleMode === 'single' ? 'bg-brand-500 text-white' : 'bg-surface-sunken text-content'
            }`}>
            Single image
          </button>
        </div>
        {state.angleMode === 'multi' && (
          <div className="flex flex-wrap gap-3">
            {ALL_SLOTS.map((slot) => (
              <label key={slot} className="flex items-center gap-2 text-sm text-content">
                <input
                  type="checkbox"
                  checked={state.angles.has(slot)}
                  onChange={(e) => {
                    const next = new Set(state.angles);
                    if (e.target.checked) next.add(slot);
                    else                  next.delete(slot);
                    setState({ ...state, angles: next });
                  }}
                  className="rounded border-outline"
                />
                {slot}
              </label>
            ))}
          </div>
        )}
      </div>

      <div>
        <p className="text-sm font-medium text-content mb-2">Size scale</p>
        <select value={state.sizeScale}
          onChange={(e) => setState({ ...state, sizeScale: e.target.value })}
          className="w-full px-3 py-2 rounded-lg border border-outline-strong bg-surface-sunken text-sm">
          {SIZE_SCALES.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
        </select>
      </div>

      <div className="flex items-center gap-6">
        <label className="flex items-center gap-2 text-sm text-content">
          <input type="checkbox"
            checked={state.requiresGender}
            onChange={(e) => setState({ ...state, requiresGender: e.target.checked })}
            className="rounded border-outline" />
          Requires gender
        </label>
        <label className="flex items-center gap-2 text-sm text-content">
          <input type="checkbox"
            checked={state.requiresDimensions}
            onChange={(e) => setState({ ...state, requiresDimensions: e.target.checked })}
            className="rounded border-outline" />
          Requires dimensions
        </label>
      </div>

      <div className="pt-2">
        <button
          onClick={() => save.mutate()}
          disabled={save.isPending || (state.angleMode === 'multi' && state.angles.size === 0)}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 disabled:opacity-50"
        >
          {save.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          Save form rules
        </button>
      </div>
    </div>
  );
};
