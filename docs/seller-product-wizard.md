# Seller Add/Edit Product — Stepper Wizard

End-to-end reference for the 6-step seller wizard and the admin-owned
per-subcategory form schema that drives it. Landed Phase 4c.

## TL;DR

Every subcategory carries four metadata fields that decide what the seller sees:
`ImageAngles`, `SizeScale`, `RequiresGender`, `RequiresDimensions`. Admin sets
them per-subcategory from the **Form rules** tab in the categories drawer; the
seller wizard fetches them on subcategory pick and adapts steps 2–5 accordingly.

## Step diagram

```
1. Category       Menu / Category / SubCategory cascade (drives everything)
2. Basics         Name, Description, Brand, Gender (if RequiresGender)
3. Pricing        MRP, Selling Price, Stock, Low-stock threshold
4. Variants       <SubCategoryVariantPicker> chips (admin-curated library)
                  <DimensionsBlock> (if RequiresDimensions)
5. Media          <ProductImageUploader> with N labeled slots from ImageAngles
6. Review & Save  Read-only summary + Submit
```

Navigation: strictly linear forward (Next disabled until step validates),
free-click backward through the stepper header. Cancel = navigate away; the
draft persists in localStorage.

## Form-schema fields

| Field | Type | Effect on wizard |
|---|---|---|
| `imageAngles` | JSON `string[]` | Step 5: renders one labeled dropzone per slot. Always include `detail` in the schema if you want an overflow zone. Each non-`detail`/`single` slot is **required** before Next. |
| `sizeScale` | `apparel \| shoe-uk \| shoe-eu \| toy \| none` | Drives which Size chips show on step 4 (via the variant library). `none` hides the size chips entirely. |
| `requiresGender` | `bool` | Step 2 shows / hides the Gender radio chips (Men / Women / Kids / Unisex). |
| `requiresDimensions` | `bool` | Step 4 shows / hides the L × W × H × weight inputs. |

## Image-slot keys

```
front | back | left | right | top | bottom | detail | single
```

- Use `["single"]` for products that only need one photo (perfume, watch, beauty).
- Use `["front","back"]` for items where one side mirrors the other (jeans, basic toys).
- Use `["front","back","left","right"]` for apparel, shoes, furniture, luggage.
- Append `"detail"` to **any** schema to give sellers an overflow zone for
  closeups / fabric texture / packaging shots.

## Draft persistence

| Mode | localStorage key |
|---|---|
| Add | `sns_product_draft_new` |
| Edit | `sns_product_draft_edit_<productId>` |

The draft is written on every state change via [useLocalStorageState](../stopnshop-ui/src/hooks/useLocalStorageState.ts).
On successful Submit the key is cleared. There is **no** server-side draft
persistence — closing the tab and reopening in a different browser starts fresh.

## Validation rules (per step)

| Step | Rule |
|---|---|
| 1 | Menu, Category, SubCategory all chosen. Subcategory may be skipped only when the picked Category has none. |
| 2 | `name.length >= 3`, `description` non-empty, Gender chosen when required. |
| 3 | `mrp > 0`, `sellingPrice > 0`, `sellingPrice <= mrp`, `stockQuantity >= 0`. |
| 4 | None (variant overrides are optional; dimensions are nullable even when section is shown). |
| 5 | All required image slots filled (every non-`detail`/`single` slot in `imageAngles`). |

## Component map

| Layer | File |
|---|---|
| Wizard shell | [stopnshop-ui/src/features/seller/ProductWizard.tsx](../stopnshop-ui/src/features/seller/ProductWizard.tsx) |
| Add wrapper | [SellerAddProductPage.tsx](../stopnshop-ui/src/features/seller/SellerAddProductPage.tsx) |
| Edit wrapper (hydrates draft from product detail) | [SellerEditProductPage.tsx](../stopnshop-ui/src/features/seller/SellerEditProductPage.tsx) |
| Stepper UI | [components/ui/Stepper.tsx](../stopnshop-ui/src/components/ui/Stepper.tsx) (pre-existing) |
| Image uploader | [components/forms/ProductImageUploader.tsx](../stopnshop-ui/src/components/forms/ProductImageUploader.tsx) |
| Gender chips | [components/forms/GenderPicker.tsx](../stopnshop-ui/src/components/forms/GenderPicker.tsx) |
| Dimensions block | [components/forms/DimensionsBlock.tsx](../stopnshop-ui/src/components/forms/DimensionsBlock.tsx) |
| Variant chips | [features/seller/SubCategoryVariantPicker.tsx](../stopnshop-ui/src/features/seller/SubCategoryVariantPicker.tsx) (existing) |
| Draft hook | [hooks/useLocalStorageState.ts](../stopnshop-ui/src/hooks/useLocalStorageState.ts) |
| Admin form-rules editor | tab inside [SubCategoryVariantsDrawer.tsx](../stopnshop-ui/src/features/admin/SubCategoryVariantsDrawer.tsx) |

## Endpoints

```
GET    /api/catalog/subcategories/{id}/form-schema     (anon, cached 5 min)
PATCH  /api/admin/categories/subcategories/{id}/form-rules   (admin, audited)

POST   /api/seller/products            (slot-aware `images: [{url,slot}]`)
PUT    /api/seller/products/{id}       (same payload shape)
POST   /api/seller/products/images/upload    (existing single-file upload)
PUT    /api/seller/products/{id}/variant-options/disabled
```

## Stored procedures

```
usp_Catalog_SubCategory_GetFormSchema       (new — single-row read)
usp_Admin_SubCategory_UpdateFormRules       (new — audited write)
usp_Seller_Product_Create                   (extended: @LengthCm @WidthCm @HeightCm @WeightGm)
usp_Catalog_Product_Update                  (extended: same 4 params)
usp_Seller_ProductImage_Add                 (extended: @ImageSlot)
usp_Catalog_ProductImage_Add                (extended: @ImageSlot)
```

## Schema changes summary

| Table | Added |
|---|---|
| `SubCategories` | `ImageAngles NVARCHAR(200)`, `SizeScale NVARCHAR(30)`, `RequiresGender BIT`, `RequiresDimensions BIT` |
| `Products` | `LengthCm DECIMAL(8,2)`, `WidthCm DECIMAL(8,2)`, `HeightCm DECIMAL(8,2)`, `WeightGm DECIMAL(10,2)` |
| `ProductImages` | `ImageSlot NVARCHAR(20)` (NULL on legacy rows) |

## Seeds

- `Seed_SubCategoryFormRules.sql` — heuristic backfill by subcategory name.
  Apparel-tops get 4-angle/apparel/gender. Jeans get 2-angle/apparel/gender.
  Footwear gets 4-angle/shoe-uk/gender. Beauty gets single. Toys get
  2-angle/toy/dimensions. Home/furniture/luggage gets 4-angle/none/dimensions.
  Watches/accessories get single.
- `Seed_SubCategoryVariantOptions.sql` — extended with shoe-EU (36–46) and
  toy (Small / Medium / Large). Subcategories with `SizeScale = 'shoe-eu'`
  pick up the EU sizes automatically.

## Defaults & fallbacks

- Subcategory with `imageAngles = NULL` falls back to `["single"]` at the API.
- Subcategory with `sizeScale = NULL` falls back to `"none"`.
- Existing products keep working — all new columns are nullable.
- Legacy `ImageUrls: string[]` payload still accepted; treated as slotless.

## Error codes

| # | Meaning |
|---|---|
| 50203 | Subcategory not found (form-rules update target) |
| 50100–50102 | Seller product create errors (seller missing, SKU dup, slug dup) |
| 50221 | Variant disable: product not owned by seller |
