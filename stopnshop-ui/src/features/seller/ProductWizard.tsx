import React, { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft, ArrowRight, Loader2, Save } from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { Stepper } from '../../components/ui/Stepper';
import { PremiumFormInput } from '../../components/forms/PremiumFormInput';
import { PremiumButton } from '../../components/forms/PremiumButton';
import {
  ProductImageUploader, emptyImageValue, flattenImagePayload, type ProductImageValue,
} from '../../components/forms/ProductImageUploader';
import { GenderPicker, genderIdToString, stringToGenderId, type GenderTypeId } from '../../components/forms/GenderPicker';
import { DimensionsBlock, emptyDimensions, type DimensionsValue } from '../../components/forms/DimensionsBlock';
import { sellerApi } from '../../api/sellerApi';
import { catalogueApi } from '../../api/catalogueApi';
import {
  catalogueFormSchemaApi, type SubCategoryFormSchema, type ImageSlot,
} from '../../api/catalogueFormSchemaApi';
import { variantLibraryApi, type SellerVariantOption } from '../../api/variantLibraryApi';
import { useToast } from '../../components/ui/Toast';
import { useLocalStorageState } from '../../hooks/useLocalStorageState';
import { SubCategoryVariantPicker } from './SubCategoryVariantPicker';
import { VariantMatrixEditor, type VariantCell } from './VariantMatrixEditor';
import { TagsInput } from '../../components/forms/TagsInput';
import { ProductPreviewPane } from './ProductPreviewPane';

/** Mirrors api/Repositories/SellerProductRepository.cs Slugify — keep in sync. */
const slugify = (s: string) =>
  s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

const DESC_RECOMMENDED = 600;

const STEPS = [
  { label: 'Category' },
  { label: 'Basics' },
  { label: 'Pricing' },
  { label: 'Variants' },
  { label: 'Media' },
  { label: 'Review' },
];

interface WizardDraft {
  // Step 1
  menuId?: number;
  categoryId?: number;
  subCategoryId?: number;
  // Step 2
  name: string;
  description: string;
  brandId?: number;
  genderTypeId?: GenderTypeId;
  // Step 3
  mrp: number;
  sellingPrice: number;
  costPrice?: number;
  stockQuantity: number;
  lowStockThreshold: number;
  // Step 4
  disabledVariantOptionIds: number[];
  variantMatrix: VariantCell[];
  dimensions: DimensionsValue;
  tags: string[];
  // Step 5
  images: ProductImageValue;
  // Optional compliance / merchandising fields (driven by category — always allowed)
  material?: string;
  careInstructions?: string;
  fitType?: string;
  countryOfOrigin?: string;
  warrantyInfo?: string;
  deliveryInfo?: string;
}

/** Infer a default GenderTypeId from the top-level menu name (MEN/WOMEN/KIDS). */
const inferGenderFromMenu = (menuName?: string): GenderTypeId | undefined => {
  if (!menuName) return undefined;
  const k = menuName.trim().toLowerCase();
  if (k === 'men'   || k.startsWith('men'))   return 1;
  if (k === 'women' || k.startsWith('women')) return 2;
  if (k === 'kids'  || k.startsWith('kid'))   return 3;
  return undefined;
};

const emptyDraft = (): WizardDraft => ({
  name: '',
  description: '',
  mrp: 0,
  sellingPrice: 0,
  stockQuantity: 0,
  lowStockThreshold: 10,
  disabledVariantOptionIds: [],
  variantMatrix: [],
  dimensions: emptyDimensions(),
  tags: [],
  images: emptyImageValue(),
});

interface Props {
  mode: 'add' | 'edit';
  productId?: number;
  initialDraft?: Partial<WizardDraft>;   // hydrated by Edit wrapper
}

export const ProductWizard: React.FC<Props> = ({ mode, productId, initialDraft }) => {
  const navigate = useNavigate();
  const qc = useQueryClient();
  const { showToast } = useToast();

  const storageKey = mode === 'edit'
    ? `sns_product_draft_edit_${productId}`
    : 'sns_product_draft_new';

  const [draft, setDraft, clearDraft] = useLocalStorageState<WizardDraft>(storageKey, {
    ...emptyDraft(),
    ...initialDraft,
  });
  const [step, setStep] = useState(0);
  const [submitting, setSubmitting] = useState(false);

  // ── Reference data ────────────────────────────────────────────
  const { data: megaMenu = [] } = useQuery({
    queryKey: ['mega-menu'],
    queryFn: () => catalogueApi.getMegaMenu().then((r) => r.data.data ?? []),
    staleTime: 1000 * 60 * 10,
  });
  const { data: brands = [] } = useQuery({
    queryKey: ['seller-brands'],
    queryFn: () => sellerApi.catalogue.getBrands().then((r) => r.data.data ?? []),
    staleTime: 1000 * 60 * 10,
  });

  const selectedMenu     = megaMenu.find((m) => m.id === draft.menuId);
  const menuCategories   = selectedMenu?.subCategories ?? [];
  const selectedCategory = menuCategories.find((c) => c.id === draft.categoryId);
  const subCategories    = selectedCategory?.productTypes ?? [];

  const { data: formSchema } = useQuery<SubCategoryFormSchema>({
    queryKey: ['form-schema', draft.subCategoryId],
    queryFn: () => catalogueFormSchemaApi.getFormSchema(draft.subCategoryId!),
    enabled: !!draft.subCategoryId,
    staleTime: 1000 * 60 * 5,
  });

  // Pulled at the wizard level too (the picker already fetches this) so we can
  // derive enabled color/size axes for the variant matrix. React Query dedupes.
  const { data: variantOptions = [] } = useQuery<SellerVariantOption[]>({
    queryKey: ['seller-variant-options', draft.subCategoryId, productId ?? null],
    queryFn: () =>
      productId
        ? variantLibraryApi.getForSellerProduct(productId, draft.subCategoryId!)
        : variantLibraryApi.getForSubCategory(draft.subCategoryId!),
    enabled: !!draft.subCategoryId,
  });

  const { enabledColors, enabledSizes } = useMemo(() => {
    const isOn = (o: SellerVariantOption) => !draft.disabledVariantOptionIds.includes(o.optionId);
    const colors = variantOptions
      .filter((o) => o.attributeKey === 'color' && isOn(o))
      .sort((a, b) => a.sortOrder - b.sortOrder || a.optionValue.localeCompare(b.optionValue))
      .map((o) => ({ value: o.optionValue, hex: o.optionMetadata ?? null }));
    const sizes = variantOptions
      .filter((o) => o.attributeKey === 'size' && isOn(o))
      .sort((a, b) => a.sortOrder - b.sortOrder || a.optionValue.localeCompare(b.optionValue))
      .map((o) => ({ value: o.optionValue, hex: null }));
    return { enabledColors: colors, enabledSizes: sizes };
  }, [variantOptions, draft.disabledVariantOptionIds]);

  // Prune matrix cells whose axis values are no longer enabled (avoids zombie rows in the payload).
  React.useEffect(() => {
    if (draft.variantMatrix.length === 0) return;
    const colorSet = new Set(enabledColors.map((c) => c.value));
    const sizeSet  = new Set(enabledSizes.map((s) => s.value));
    const pruned = draft.variantMatrix.filter((c) =>
      (c.color == null || colorSet.has(c.color)) &&
      (c.size  == null || sizeSet.has(c.size)),
    );
    if (pruned.length !== draft.variantMatrix.length) {
      setDraft({ ...draft, variantMatrix: pruned });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabledColors, enabledSizes]);

  const requiredImageSlots = useMemo(() => {
    if (!formSchema) return [];
    return formSchema.imageAngles.filter((s) => s !== 'detail' && s !== 'single') as Array<
      Exclude<ImageSlot, 'detail' | 'single'>
    >;
  }, [formSchema]);

  // ── Per-step validation ───────────────────────────────────────
  const validateStep = (s: number): string | null => {
    switch (s) {
      case 0:
        if (!draft.menuId)        return 'Pick a menu.';
        if (!draft.categoryId)    return 'Pick a category.';
        if (subCategories.length > 0 && !draft.subCategoryId) return 'Pick a subcategory.';
        return null;
      case 1:
        if (!draft.name.trim())             return 'Product name is required.';
        if (draft.name.trim().length < 3)   return 'Product name must be at least 3 characters.';
        if (!draft.description.trim())      return 'Description is required.';
        if (formSchema?.requiresGender && !draft.genderTypeId) return 'Pick a gender.';
        return null;
      case 2:
        if (!(draft.mrp > 0))                  return 'MRP must be greater than 0.';
        if (!(draft.sellingPrice > 0))         return 'Selling price must be greater than 0.';
        if (draft.sellingPrice > draft.mrp)    return 'Selling price cannot exceed MRP.';
        if (!(draft.stockQuantity >= 0))       return 'Stock quantity must be 0 or more.';
        return null;
      case 3:
        return null;
      case 4: {
        const missing = requiredImageSlots.filter((slot) => !draft.images.slots[slot]);
        if (missing.length > 0) return `Add image(s) for: ${missing.join(', ')}.`;
        return null;
      }
      default:
        return null;
    }
  };

  const stepErrors = useMemo(() => validateStep(step),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [step, draft, subCategories.length, formSchema, requiredImageSlots]);

  // Status for each step header. A step is "valid" once visited AND its predicate passes;
  // "error" when visited but failing; otherwise "pending". The current step never shows
  // ✓/! in the circle (it stays neutral while you edit).
  const stepStatuses = useMemo(() => {
    const furthestVisited = Math.max(step, ...Array.from({ length: STEPS.length }, (_, i) =>
      (draft.menuId && i === 0) ? i : -1));
    return STEPS.map((_, i) => {
      if (i > step) return 'pending' as const;
      const err = validateStep(i);
      if (err && i <= furthestVisited && i !== step) return 'error' as const;
      if (!err && i !== step) return 'valid' as const;
      // For the active step, surface "error" only if the user already hit Next once.
      // We don't track that — leave as pending while editing.
      return 'pending' as const;
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [step, draft, subCategories.length, formSchema, requiredImageSlots]);

  const goNext = () => {
    if (stepErrors) return;
    setStep((s) => Math.min(STEPS.length - 1, s + 1));
  };
  const goBack = () => setStep((s) => Math.max(0, s - 1));

  // ── Submit ────────────────────────────────────────────────────
  const submit = async () => {
    if (stepErrors) return;
    setSubmitting(true);
    try {
      const payload: any = {
        name:              draft.name,
        description:       draft.description,
        brandId:           draft.brandId,
        categoryId:        draft.categoryId,
        subCategoryId:     draft.subCategoryId,
        mrp:               draft.mrp,
        sellingPrice:      draft.sellingPrice,
        stockQuantity:     draft.stockQuantity,
        lowStockThreshold: draft.lowStockThreshold,
        gender:            formSchema?.requiresGender ? genderIdToString(draft.genderTypeId) : undefined,
        tags:              draft.tags.length > 0 ? draft.tags : undefined,
        images:            flattenImagePayload(draft.images),
        costPrice:         draft.costPrice ?? undefined,
        // Compliance / merchandising
        material:          draft.material?.trim()         || undefined,
        careInstructions:  draft.careInstructions?.trim() || undefined,
        fitType:           draft.fitType?.trim()          || undefined,
        countryOfOrigin:   draft.countryOfOrigin?.trim()  || undefined,
        warrantyInfo:      draft.warrantyInfo?.trim()     || undefined,
        deliveryInfo:      draft.deliveryInfo?.trim()     || undefined,
        // Per-cell stock. Server-side this overrides the legacy uniform Colors×Sizes path.
        variantMatrix:     draft.variantMatrix.length > 0 ? draft.variantMatrix : undefined,
        // dimensions (always sent — backend stores nullable values)
        lengthCm: draft.dimensions.lengthCm ?? null,
        widthCm:  draft.dimensions.widthCm  ?? null,
        heightCm: draft.dimensions.heightCm ?? null,
        weightGm: draft.dimensions.weightGm ?? null,
      };

      let newProductId = productId;
      if (mode === 'add') {
        const res = await sellerApi.products.create(payload);
        newProductId = (res as any)?.data?.data?.productId ?? (res as any)?.data?.data?.id;
      } else if (productId) {
        await sellerApi.products.update(productId, payload);
      }

      if (newProductId && draft.subCategoryId) {
        try {
          await variantLibraryApi.setDisabledForProduct(newProductId, draft.disabledVariantOptionIds);
        } catch { /* non-fatal */ }
      }

      clearDraft();
      qc.invalidateQueries({ queryKey: ['seller-products'] });
      if (productId) qc.invalidateQueries({ queryKey: ['seller-product', String(productId)] });
      showToast(mode === 'add' ? 'Product created!' : 'Product updated!', 'success');
      navigate('/seller/products');
    } catch (err: any) {
      showToast(err?.response?.data?.message ?? 'Save failed.', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  // ── Render helpers ────────────────────────────────────────────
  const StepBody = (
    <div className="space-y-6">
      {step === 0 && (
        <>
          <p className="text-sm text-content-muted">
            Tell us where this product belongs. The wizard adapts the remaining steps to the
            subcategory you choose.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-content mb-1.5">Menu</label>
              <select value={draft.menuId ?? ''}
                onChange={(e) => {
                  const newMenuId = Number(e.target.value) || undefined;
                  const newMenu   = megaMenu.find((m) => m.id === newMenuId);
                  const inferred  = inferGenderFromMenu(newMenu?.name);
                  setDraft({
                    ...draft,
                    menuId: newMenuId,
                    categoryId: undefined,
                    subCategoryId: undefined,
                    // Re-seed gender from the new menu. User can override later in step 2.
                    genderTypeId: inferred ?? draft.genderTypeId,
                  });
                }}
                className="w-full px-3 py-2.5 rounded-lg border border-outline-strong bg-surface-elevated text-sm">
                <option value="">Select menu</option>
                {megaMenu.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-content mb-1.5">Category</label>
              <select value={draft.categoryId ?? ''}
                disabled={!draft.menuId}
                onChange={(e) => setDraft({ ...draft, categoryId: Number(e.target.value) || undefined,
                  subCategoryId: undefined })}
                className="w-full px-3 py-2.5 rounded-lg border border-outline-strong bg-surface-elevated text-sm disabled:opacity-60">
                <option value="">{draft.menuId ? 'Select category' : 'Pick a menu first'}</option>
                {menuCategories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-content mb-1.5">Subcategory</label>
              <select value={draft.subCategoryId ?? ''}
                disabled={!draft.categoryId || subCategories.length === 0}
                onChange={(e) => setDraft({ ...draft, subCategoryId: Number(e.target.value) || undefined,
                  disabledVariantOptionIds: [] })}
                className="w-full px-3 py-2.5 rounded-lg border border-outline-strong bg-surface-elevated text-sm disabled:opacity-60">
                <option value="">
                  {!draft.categoryId
                    ? 'Pick a category first'
                    : subCategories.length === 0
                      ? 'No subcategories'
                      : 'Select subcategory'}
                </option>
                {subCategories.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>
          </div>
          {formSchema && (
            <div className="rounded-lg bg-surface px-4 py-3 text-xs text-content-muted">
              <strong className="text-content">Form rules for {formSchema.subCategoryName}:</strong>{' '}
              {formSchema.imageAngles.length} image slot(s),
              size scale <code>{formSchema.sizeScale}</code>,
              gender {formSchema.requiresGender
                ? (inferGenderFromMenu(selectedMenu?.name)
                    ? `auto-set to ${selectedMenu?.name?.toLowerCase()}`
                    : 'required')
                : 'not applicable'},
              dimensions {formSchema.requiresDimensions ? 'required' : 'hidden'}.
            </div>
          )}
        </>
      )}

      {step === 1 && (
        <div className="space-y-5">
          <div>
            <PremiumFormInput
              label="Product name"
              placeholder="e.g. Premium Cotton T-Shirt"
              value={draft.name}
              onChange={(e) => setDraft({ ...draft, name: e.target.value })}
            />
            {draft.name.trim().length >= 3 && (
              <p className="mt-1.5 text-xs text-content-subtle">
                Will be published as <code className="text-content-muted">/products/{slugify(draft.name)}</code>
                <span className="text-content-subtle"> (a short unique suffix is appended on save)</span>
              </p>
            )}
          </div>
          <div>
            <div className="flex items-end justify-between mb-1.5">
              <label className="block text-sm font-medium text-content">Description</label>
              <span className={`text-xs tabular-nums ${
                draft.description.length > DESC_RECOMMENDED ? 'text-amber-600' : 'text-content-subtle'
              }`}>
                {draft.description.length} / {DESC_RECOMMENDED}
              </span>
            </div>
            <textarea
              rows={5}
              value={draft.description}
              onChange={(e) => setDraft({ ...draft, description: e.target.value })}
              placeholder="Tell buyers what makes this product great."
              className="w-full px-4 py-3 rounded-lg border border-outline-strong bg-surface-elevated text-sm focus:ring-2 focus:ring-brand-200 focus:border-transparent"
            />
            <p className="mt-1 text-xs text-content-subtle">
              First ~160 chars show as the meta description in search results.
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-content mb-1.5">Brand</label>
            <select value={draft.brandId ?? ''}
              onChange={(e) => setDraft({ ...draft, brandId: Number(e.target.value) || undefined })}
              className="w-full px-3 py-2.5 rounded-lg border border-outline-strong bg-surface-elevated text-sm">
              <option value="">Select brand</option>
              {brands.map((b: any) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-content mb-1.5">
              Tags <span className="text-content-subtle font-normal">(help buyers find this product)</span>
            </label>
            <TagsInput
              value={draft.tags}
              onChange={(next) => setDraft({ ...draft, tags: next })}
              placeholder="e.g. cotton, summer, casual"
            />
          </div>
          <AdditionalDetailsSection
            draft={draft}
            setDraft={setDraft}
            isApparel={formSchema?.sizeScale === 'apparel'}
          />
          {formSchema?.requiresGender && (
            <div>
              <GenderPicker
                value={draft.genderTypeId}
                onChange={(id) => setDraft({ ...draft, genderTypeId: id })}
                required
              />
              {selectedMenu && inferGenderFromMenu(selectedMenu.name) === draft.genderTypeId && (
                <p className="mt-1.5 text-xs text-content-subtle">
                  Auto-set from <span className="font-medium text-content-muted">{selectedMenu.name}</span> menu — change above if needed.
                </p>
              )}
            </div>
          )}
        </div>
      )}

      {step === 2 && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <PremiumFormInput label="MRP (₹)" type="number" min={0}
              value={draft.mrp || ''}
              onChange={(e) => setDraft({ ...draft, mrp: Number(e.target.value) || 0 })} />
            <PremiumFormInput label="Selling Price (₹)" type="number" min={0}
              value={draft.sellingPrice || ''}
              onChange={(e) => setDraft({ ...draft, sellingPrice: Number(e.target.value) || 0 })} />
            <PremiumFormInput label="Cost Price (₹)  — optional, only you see this" type="number" min={0}
              value={draft.costPrice ?? ''}
              onChange={(e) => {
                const v = e.target.value.trim();
                setDraft({ ...draft, costPrice: v === '' ? undefined : (Number(v) || 0) });
              }} />
            <div /> {/* spacer */}
            <PremiumFormInput label="Stock Quantity" type="number" min={0}
              value={draft.stockQuantity || ''}
              onChange={(e) => setDraft({ ...draft, stockQuantity: Number(e.target.value) || 0 })} />
            <PremiumFormInput label="Low-stock Alert Threshold" type="number" min={0}
              value={draft.lowStockThreshold || ''}
              onChange={(e) => setDraft({ ...draft, lowStockThreshold: Number(e.target.value) || 0 })} />
          </div>
          <PricingInsights mrp={draft.mrp} selling={draft.sellingPrice} cost={draft.costPrice} />
        </div>
      )}

      {step === 3 && (
        <div className="space-y-6">
          {draft.subCategoryId ? (
            <>
              <SubCategoryVariantPicker
                subCategoryId={draft.subCategoryId}
                productId={productId}
                disabledOptionIds={draft.disabledVariantOptionIds}
                onChange={(ids) => setDraft({ ...draft, disabledVariantOptionIds: ids })}
              />
              <VariantMatrixEditor
                colors={enabledColors}
                sizes={enabledSizes}
                value={draft.variantMatrix}
                onChange={(next) => setDraft({ ...draft, variantMatrix: next })}
              />
            </>
          ) : (
            <p className="text-sm text-content-muted">Pick a subcategory first to see variant options.</p>
          )}
          {formSchema?.requiresDimensions && (
            <DimensionsBlock
              value={draft.dimensions}
              onChange={(d) => setDraft({ ...draft, dimensions: d })}
            />
          )}
        </div>
      )}

      {step === 4 && (
        <>
          <p className="text-sm text-content-muted">
            Upload one image per angle. Required slots are marked with{' '}
            <span className="text-red-500">*</span>.
          </p>
          <ProductImageUploader
            slots={formSchema?.imageAngles ?? ['single']}
            value={draft.images}
            onChange={(v) => setDraft({ ...draft, images: v })}
            requiredSlots={requiredImageSlots}
          />
        </>
      )}

      {step === 5 && (
        <ReviewStep draft={draft}
          menuName={selectedMenu?.name}
          categoryName={selectedCategory?.name}
          subCategoryName={formSchema?.subCategoryName ?? subCategories.find((s) => s.id === draft.subCategoryId)?.name}
          brandName={brands.find((b: any) => b.id === draft.brandId)?.name}
        />
      )}
    </div>
  );

  return (
    <SellerLayout>
      <div className="mb-6">
        <button onClick={() => navigate('/seller/products')}
          className="flex items-center text-sm text-content-muted hover:text-brand-500 transition-colors">
          <ArrowLeft size={16} className="mr-1" /> Back to Products
        </button>
        <div className="mt-3 flex flex-wrap items-center gap-3">
          <h1 className="text-3xl font-display font-bold text-content">
            {mode === 'add' ? 'Add Product' : 'Edit Product'}
          </h1>
          <span
            className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-50 text-green-700 border border-green-200"
            title="Your changes are saved locally on every keystroke."
          >
            <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
            Autosaved
          </span>
          {mode === 'add' && (
            <button
              type="button"
              onClick={() => {
                if (confirm('Discard the in-progress draft and start over?')) {
                  clearDraft();
                  setStep(0);
                }
              }}
              className="text-xs text-content-muted hover:text-red-600 underline-offset-2 hover:underline"
            >
              Clear draft
            </button>
          )}
        </div>
        <p className="text-content-muted mt-1">
          Draft is autosaved — close the tab and come back any time.
        </p>
      </div>

      <div className="flex flex-col xl:flex-row xl:items-start xl:gap-6 max-w-7xl">
      <div className="flex-1 bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-8 max-w-4xl">
        <div className="mb-8">
          <Stepper
            steps={STEPS.map((s, i) => ({ ...s, status: stepStatuses[i] }))}
            activeStep={step}
            allowForwardJump
            onStepClick={(i) => {
              if (i === step) return;
              if (i < step) { setStep(i); return; }
              // Forward jump only if every intervening step is valid.
              for (let k = step; k < i; k++) {
                if (validateStep(k) !== null) return;
              }
              setStep(i);
            }}
          />
        </div>

        <div className="min-h-[260px]">{StepBody}</div>

        {stepErrors && step < STEPS.length - 1 && (
          <p className="mt-4 text-sm text-red-600">{stepErrors}</p>
        )}

        <div className="mt-8 flex items-center justify-between border-t border-outline/60 pt-5">
          <PremiumButton variant="ghost" size="md" onClick={goBack} disabled={step === 0 || submitting}>
            <ArrowLeft size={16} className="mr-1" /> Back
          </PremiumButton>

          {step < STEPS.length - 1 ? (
            <PremiumButton
              variant="primary"
              size="md"
              onClick={goNext}
              disabled={!!stepErrors}
            >
              Next <ArrowRight size={16} className="ml-1" />
            </PremiumButton>
          ) : (
            <PremiumButton
              variant="primary"
              size="md"
              onClick={submit}
              disabled={submitting}
            >
              {submitting ? <Loader2 size={16} className="mr-1 animate-spin" /> : <Save size={16} className="mr-1" />}
              {mode === 'add' ? 'Create product' : 'Save changes'}
            </PremiumButton>
          )}
        </div>
      </div>

      {/* Live PDP preview — sticky right rail on xl+, collapses below the wizard on smaller screens. */}
      <aside className="mt-6 xl:mt-0 xl:w-80 xl:sticky xl:top-6 shrink-0">
        <ProductPreviewPane
          name={draft.name}
          brandName={brands.find((b: any) => b.id === draft.brandId)?.name}
          categoryPath={[selectedCategory?.name, subCategories.find((s) => s.id === draft.subCategoryId)?.name]
            .filter(Boolean).join(' › ')}
          gender={genderIdToString(draft.genderTypeId)}
          mrp={draft.mrp}
          sellingPrice={draft.sellingPrice}
          stockTotal={draft.stockQuantity}
          images={draft.images}
          variantMatrix={draft.variantMatrix}
          enabledColorsWithHex={enabledColors}
          enabledSizes={enabledSizes.map((s) => s.value)}
        />
      </aside>
      </div>
    </SellerLayout>
  );
};

// ── Review summary ─────────────────────────────────────────────────────
const ReviewStep: React.FC<{
  draft: WizardDraft;
  menuName?: string;
  categoryName?: string;
  subCategoryName?: string;
  brandName?: string;
}> = ({ draft, menuName, categoryName, subCategoryName, brandName }) => {
  const allImages = flattenImagePayload(draft.images);
  return (
    <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3 text-sm">
      <Row label="Category"      value={[menuName, categoryName, subCategoryName].filter(Boolean).join(' › ') || '—'} />
      <Row label="Brand"         value={brandName ?? '—'} />
      <Row label="Name"          value={draft.name} />
      <Row label="Gender"        value={genderIdToString(draft.genderTypeId) ?? '—'} />
      <Row label="MRP"           value={`₹${draft.mrp.toLocaleString()}`} />
      <Row label="Selling Price" value={`₹${draft.sellingPrice.toLocaleString()}`} />
      <Row label="Stock" value={
        draft.variantMatrix.length > 0
          ? `${draft.variantMatrix.reduce((a, c) => a + (c.stockQuantity || 0), 0)} across ${draft.variantMatrix.filter((c) => c.stockQuantity > 0).length} variant(s) (low alert at ${draft.lowStockThreshold})`
          : `${draft.stockQuantity} (low alert at ${draft.lowStockThreshold})`
      } />
      <Row label="Disabled variant options" value={draft.disabledVariantOptionIds.length} />
      <Row label="Tags" value={draft.tags.length > 0 ? draft.tags.join(', ') : '—'} />
      <Row label="Dimensions"
           value={draft.dimensions.lengthCm
                  ? `${draft.dimensions.lengthCm} × ${draft.dimensions.widthCm} × ${draft.dimensions.heightCm} cm · ${draft.dimensions.weightGm ?? '—'} g`
                  : '—'} />
      <Row label="Images" value={`${allImages.length} (${allImages.map((i) => i.slot).join(', ') || 'none'})`} />
      <div className="sm:col-span-2">
        <dt className="text-xs uppercase tracking-wider text-content-subtle">Description</dt>
        <dd className="mt-1 text-content whitespace-pre-line">{draft.description || '—'}</dd>
      </div>
    </dl>
  );
};

const Row: React.FC<{ label: string; value: React.ReactNode }> = ({ label, value }) => (
  <div>
    <dt className="text-xs uppercase tracking-wider text-content-subtle">{label}</dt>
    <dd className="mt-0.5 text-content">{value}</dd>
  </div>
);

// ── Live pricing insights ─────────────────────────────────────────────────
const PricingInsights: React.FC<{ mrp: number; selling: number; cost?: number }> = ({ mrp, selling, cost }) => {
  const hasMrp     = mrp > 0;
  const hasSelling = selling > 0;
  const hasCost    = cost != null && cost > 0;

  const discountPct = hasMrp && hasSelling && selling <= mrp ? ((mrp - selling) / mrp) * 100 : null;
  const savings     = hasMrp && hasSelling && selling <= mrp ? mrp - selling : null;
  const marginPct   = hasSelling && hasCost ? ((selling - cost!) / selling) * 100 : null;
  const marginAbs   = hasSelling && hasCost ? selling - cost! : null;

  const warnings: string[] = [];
  if (hasMrp && hasSelling && selling > mrp) warnings.push('Selling price is above MRP — buyers will not see a discount badge.');
  if (hasCost && hasSelling && cost! > selling) warnings.push(`Selling price is below cost — you would lose ₹${(cost! - selling).toLocaleString()} per unit.`);
  if (hasCost && hasSelling && marginPct != null && marginPct < 10 && marginPct >= 0) warnings.push('Margin is below 10%. Consider raising the selling price.');

  if (!hasMrp && !hasSelling && !hasCost) return null;

  return (
    <div className="rounded-xl border border-outline/60 bg-surface-sunken p-4">
      <p className="text-xs uppercase tracking-wider text-content-subtle mb-2">Pricing preview</p>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
        <Stat label="Discount" value={discountPct != null ? `${discountPct.toFixed(0)}%` : '—'}
              hint={savings != null ? `Save ₹${savings.toLocaleString()}` : undefined} />
        <Stat label="Margin"   value={marginPct != null ? `${marginPct.toFixed(0)}%` : '—'}
              hint={marginAbs != null ? `₹${marginAbs.toLocaleString()} / unit` : 'Add cost price'} />
        <Stat label="You earn" value={marginAbs != null ? `₹${marginAbs.toLocaleString()}` : '—'} />
        <Stat label="Buyer pays" value={hasSelling ? `₹${selling.toLocaleString()}` : '—'}
              hint={hasMrp && discountPct != null ? `was ₹${mrp.toLocaleString()}` : undefined} />
      </div>
      {warnings.length > 0 && (
        <ul className="mt-3 space-y-1 text-xs text-amber-700">
          {warnings.map((w, i) => <li key={i}>• {w}</li>)}
        </ul>
      )}
    </div>
  );
};

const Stat: React.FC<{ label: string; value: string; hint?: string }> = ({ label, value, hint }) => (
  <div>
    <p className="text-xs text-content-muted">{label}</p>
    <p className="text-base font-semibold text-content tabular-nums">{value}</p>
    {hint && <p className="text-[11px] text-content-subtle">{hint}</p>}
  </div>
);

// ── Additional / compliance details (collapsible) ─────────────────────────
const AdditionalDetailsSection: React.FC<{
  draft: WizardDraft;
  setDraft: (next: WizardDraft) => void;
  isApparel: boolean;
}> = ({ draft, setDraft, isApparel }) => {
  // Open by default if any field has content (edit hydration), else collapsed.
  const anyFilled = !!(draft.material || draft.careInstructions || draft.fitType
    || draft.countryOfOrigin || draft.warrantyInfo || draft.deliveryInfo);
  const [open, setOpen] = useState(anyFilled);

  const filledCount = [draft.material, draft.careInstructions, draft.fitType,
    draft.countryOfOrigin, draft.warrantyInfo, draft.deliveryInfo].filter(Boolean).length;

  return (
    <div className="rounded-xl border border-outline/60">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="w-full flex items-center justify-between px-4 py-3 text-left"
        aria-expanded={open}
      >
        <div>
          <p className="text-sm font-medium text-content">Additional details</p>
          <p className="text-xs text-content-muted mt-0.5">
            Optional — boost buyer trust and reduce returns. {filledCount > 0 && <span className="text-green-600">{filledCount} filled</span>}
          </p>
        </div>
        <span className="text-xs text-content-muted">{open ? 'Hide' : 'Show'}</span>
      </button>
      {open && (
        <div className="border-t border-outline/60 p-4 space-y-3">
          {isApparel && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <DetailField label="Material" placeholder="100% Cotton"
                value={draft.material} onChange={(v) => setDraft({ ...draft, material: v })} />
              <DetailField label="Fit type" placeholder="Regular / Slim / Relaxed"
                value={draft.fitType} onChange={(v) => setDraft({ ...draft, fitType: v })} />
              <DetailTextarea label="Care instructions" placeholder="Machine wash cold, tumble dry low…"
                value={draft.careInstructions} onChange={(v) => setDraft({ ...draft, careInstructions: v })} />
              <DetailField label="Country of origin" placeholder="India"
                value={draft.countryOfOrigin} onChange={(v) => setDraft({ ...draft, countryOfOrigin: v })} />
            </div>
          )}
          {!isApparel && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <DetailField label="Material" placeholder="ABS plastic, stainless steel, etc."
                value={draft.material} onChange={(v) => setDraft({ ...draft, material: v })} />
              <DetailField label="Country of origin" placeholder="India"
                value={draft.countryOfOrigin} onChange={(v) => setDraft({ ...draft, countryOfOrigin: v })} />
            </div>
          )}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <DetailTextarea label="Warranty / Returns"
              placeholder="1-year manufacturer warranty. 7-day easy returns."
              value={draft.warrantyInfo} onChange={(v) => setDraft({ ...draft, warrantyInfo: v })} />
            <DetailTextarea label="Delivery details"
              placeholder="Ships in 24 hours from Mumbai. Free over ₹499."
              value={draft.deliveryInfo} onChange={(v) => setDraft({ ...draft, deliveryInfo: v })} />
          </div>
        </div>
      )}
    </div>
  );
};

const DetailField: React.FC<{ label: string; placeholder?: string; value?: string; onChange: (v: string) => void }> =
  ({ label, placeholder, value, onChange }) => (
  <div>
    <label className="block text-xs font-medium text-content-muted mb-1">{label}</label>
    <input
      type="text"
      value={value ?? ''}
      placeholder={placeholder}
      onChange={(e) => onChange(e.target.value)}
      className="w-full px-3 py-2 rounded-md border border-outline bg-surface-elevated text-sm focus:ring-2 focus:ring-brand-200 focus:border-transparent"
    />
  </div>
);

const DetailTextarea: React.FC<{ label: string; placeholder?: string; value?: string; onChange: (v: string) => void }> =
  ({ label, placeholder, value, onChange }) => (
  <div>
    <label className="block text-xs font-medium text-content-muted mb-1">{label}</label>
    <textarea
      rows={2}
      value={value ?? ''}
      placeholder={placeholder}
      onChange={(e) => onChange(e.target.value)}
      className="w-full px-3 py-2 rounded-md border border-outline bg-surface-elevated text-sm focus:ring-2 focus:ring-brand-200 focus:border-transparent resize-y"
    />
  </div>
);

// Exported draft type so the Edit page can hydrate it.
export type { WizardDraft };
export { emptyDraft, stringToGenderId };
