import React, { useMemo } from 'react';
import { useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { sellerApi } from '../../api/sellerApi';
import { catalogueApi } from '../../api/catalogueApi';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { Spinner } from '../../components/ui/Spinner';
import { ProductWizard, emptyDraft, stringToGenderId, type WizardDraft } from './ProductWizard';
import { emptyImageValue, type ProductImageValue } from '../../components/forms/ProductImageUploader';
import type { ImageSlot } from '../../api/catalogueFormSchemaApi';

const KNOWN_SLOTS: ImageSlot[] = ['front', 'back', 'left', 'right', 'top', 'bottom', 'detail', 'single'];

export const SellerEditProductPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const productId = id ? Number(id) : undefined;

  const { data: product, isLoading } = useQuery({
    queryKey: ['seller-product', id],
    queryFn: () => sellerApi.products.getById(Number(id)).then((r) => r.data.data),
    enabled: !!productId,
  });

  // megaMenu is fetched by ProductWizard too; we don't need it here. We just
  // need the categoryId/subCategoryId stored on the product to seed the cascade.
  const { data: megaMenu = [] } = useQuery({
    queryKey: ['mega-menu'],
    queryFn: () => catalogueApi.getMegaMenu().then((r) => r.data.data ?? []),
    staleTime: 1000 * 60 * 10,
  });

  const initialDraft: Partial<WizardDraft> | undefined = useMemo(() => {
    if (!product) return undefined;

    // Reverse-lookup menuId from categoryId by walking the mega-menu tree.
    let menuId: number | undefined;
    const productCategoryId = (product as any).categoryId;
    for (const m of megaMenu) {
      if (m.subCategories?.some((c: any) => c.id === productCategoryId)) {
        menuId = m.id;
        break;
      }
    }

    // Group existing images by slot (legacy rows have no slot — bucket them as 'detail').
    const productImages: Array<{ url?: string; imageUrl?: string; slot?: string; imageSlot?: string }> =
      Array.isArray((product as any).productImages) ? (product as any).productImages
      : Array.isArray((product as any).images)      ? (product as any).images
      : Array.isArray((product as any).imageUrls)   ? (product as any).imageUrls.map((u: string) => ({ url: u }))
      : [];
    const images: ProductImageValue = emptyImageValue();
    productImages.forEach((row) => {
      const url  = row.url ?? row.imageUrl;
      const slot = (row.slot ?? row.imageSlot ?? '').toLowerCase();
      if (!url) return;
      if (slot === 'detail') images.detail.push(url);
      else if (KNOWN_SLOTS.includes(slot as ImageSlot) && slot !== 'detail') {
        (images.slots as any)[slot] = url;
      } else {
        // unknown / legacy → drop into detail overflow
        images.detail.push(url);
      }
    });

    return {
      ...emptyDraft(),
      menuId,
      categoryId:        productCategoryId,
      subCategoryId:     (product as any).subCategoryId ?? undefined,
      name:              product.name ?? '',
      description:       product.description ?? '',
      brandId:           (product as any).brandId ?? undefined,
      genderTypeId:      stringToGenderId((product as any).gender ?? (product as any).genderType),
      mrp:               product.mrp ?? 0,
      sellingPrice:      product.sellingPrice ?? 0,
      costPrice:         (product as any).costPrice ?? undefined,
      stockQuantity:     product.stockQuantity ?? 0,
      lowStockThreshold: product.lowStockThreshold ?? 10,
      images,
      dimensions: {
        lengthCm: (product as any).lengthCm ?? null,
        widthCm:  (product as any).widthCm  ?? null,
        heightCm: (product as any).heightCm ?? null,
        weightGm: (product as any).weightGm ?? null,
      },
      material:         (product as any).material         ?? undefined,
      careInstructions: (product as any).careInstructions ?? undefined,
      fitType:          (product as any).fitType          ?? undefined,
      countryOfOrigin:  (product as any).countryOfOrigin  ?? undefined,
      warrantyInfo:     (product as any).warrantyInfo     ?? undefined,
      deliveryInfo:     (product as any).deliveryInfo     ?? undefined,
      variantMatrix: Array.isArray((product as any).variants)
        ? ((product as any).variants as Array<{ color?: string | null; size?: string | null; stockQuantity?: number; additionalPrice?: number }>)
            .filter((v) => (v.color && v.color.trim()) || (v.size && v.size.trim()))
            .map((v) => ({
              color:           v.color && v.color.trim() ? v.color.trim() : null,
              size:            v.size  && v.size.trim()  ? v.size.trim()  : null,
              stockQuantity:   Math.max(0, Math.floor(v.stockQuantity ?? 0)),
              additionalPrice: v.additionalPrice ?? 0,
            }))
        : [],
    };
  }, [product, megaMenu]);

  if (isLoading || !productId || !initialDraft) {
    return (
      <SellerLayout>
        <div className="min-h-[60vh] flex items-center justify-center">
          <Spinner size="lg" />
        </div>
      </SellerLayout>
    );
  }

  return <ProductWizard mode="edit" productId={productId} initialDraft={initialDraft} />;
};
