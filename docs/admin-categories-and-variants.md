# Admin Categories + Variant Library

End-to-end reference for the dynamic category management and per-subcategory
variant option library, landed 2026-05-19 (Phase 4b).

## TL;DR
- **`/admin/categories`** — admin owns the entire category tree shown on the
  home page mega-menu. Categories and subcategories can be reordered, hidden
  from the mega-menu without disabling them, edited, or soft-deleted.
- **Variant library** — each subcategory carries an admin-curated list of
  values per attribute (Size, Color, Material, Pattern, Fit). Sellers see those
  values pre-selected when adding a product and untick anything that doesn't
  apply to their specific listing.

## Data model

| Table | Purpose |
|---|---|
| `Categories` | + `ShowInMegaMenu` BIT, default 1 |
| `SubCategories` | + `ShowInMegaMenu` BIT, default 1 |
| `VariantAttributes` | Master list — Size / Color / Material / Pattern / Fit |
| `SubCategoryVariantOptions` | `(SubCategoryId, AttributeId, OptionValue)` unique. Color uses `OptionMetadata` for hex. |
| `ProductDisabledVariantOptions` | Per-product opt-out flags. Empty set = product inherits the full library. |

## Stored procedures

### Category admin
- `usp_Admin_MegaMenu_GetTree @IncludeInactive` — two result sets (categories,
  subcategories) with `SubCategoryCount` and `ProductCount` aggregates.
- `usp_Admin_Category_Upsert` / `usp_Admin_SubCategory_Upsert` — insert when
  `Id IS NULL`, update otherwise. Returns the id.
- `usp_Admin_Category_ToggleVisibility @IsActive, @ShowInMegaMenu` —
  either flag is optional; only supplied values change.
- `usp_Admin_Category_Reorder @OrderJson` — accepts
  `[{"categoryId":1,"sortOrder":0},…]`.
- `usp_Admin_Category_Delete` — refuses if any active product still references
  the category (error 50201). Subcategory mirror error: 50204.

### Variant library
- `usp_Admin_VariantAttribute_GetAll`
- `usp_Admin_SubCategoryOption_GetBySubCategory @SubCategoryId @IncludeInactive`
- `usp_Admin_SubCategoryOption_Upsert`
- `usp_Admin_SubCategoryOption_ToggleActive`
- `usp_Admin_SubCategoryOption_Delete` — hard-deletes when no product references,
  soft-deletes (IsActive=0) otherwise.
- `usp_Admin_SubCategoryOption_BulkSet @SubCategoryId @AttributeId @OptionsJson` —
  replace-all for one attribute. Removed values are deactivated, not deleted.
- `usp_Catalog_SubCategoryOption_GetForSeller @SubCategoryId @ProductId` —
  used by seller add/edit pages; `IsDisabledForProduct` flag joined in.
- `usp_Seller_ProductDisabledOptions_Set @ProductId @SellerId @DisabledJson` —
  authorizes against `Products.SellerId`, error 50221 if mismatch.

## Endpoints

```
GET    /api/admin/categories/tree?includeInactive=true
POST   /api/admin/categories
PATCH  /api/admin/categories/{id}/toggle           { isActive?, showInMegaMenu? }
PATCH  /api/admin/categories/reorder               { items: [{categoryId,sortOrder}] }
DELETE /api/admin/categories/{id}

POST   /api/admin/categories/subcategories
PATCH  /api/admin/categories/subcategories/{id}/toggle
PATCH  /api/admin/categories/subcategories/reorder
DELETE /api/admin/categories/subcategories/{id}

GET    /api/admin/variant-library/attributes
GET    /api/admin/variant-library/subcategories/{subCategoryId}/options
POST   /api/admin/variant-library/options
PATCH  /api/admin/variant-library/options/{id}/toggle
DELETE /api/admin/variant-library/options/{id}
PUT    /api/admin/variant-library/options/bulk     { subCategoryId, attributeId, options[] }

GET    /api/catalog/subcategories/{subCategoryId}/variant-options    (anon)
GET    /api/seller/products/{productId}/variant-options?subCategoryId=…  (seller)
PUT    /api/seller/products/{productId}/variant-options/disabled         (seller) { optionIds }
```

All admin writes record an entry in `AuditLogs` via `IAdminRepository.WriteAuditAsync`.

## UI flows

### Admin `/admin/categories`
1. Categories grouped by Menu (MEN, WOMEN, KIDS, …).
2. Per-row toggles: **Mega-menu** (`ShowInMegaMenu`) and **Active** (`IsActive`).
3. Arrows reorder within the menu (writes a 2-row swap to `usp_Admin_Category_Reorder`).
4. `+ Sub` button on a category opens the subcategory editor pre-bound to that parent.
5. Subcategory rows show a **Layers** icon — opens `SubCategoryVariantsDrawer`.

### Variant drawer
1. Tabs across all 5 attributes.
2. Add value: text field + hex color picker (when attribute is `swatch`).
3. Toggle Active per option, or soft-delete with confirm.

### Seller add/edit product
1. Once subcategory is selected, `SubCategoryVariantPicker` fetches the library.
2. All options render as chips, **selected = enabled, deselected = disabled**.
3. **All / None** buttons per attribute for quick bulk ops.
4. On save: product is created/updated first, then the disabled-id list is
   pushed via `PUT …/variant-options/disabled`. If the library save fails the
   product itself is preserved (non-fatal).
5. Subcategories without a library show a friendly placeholder; the legacy
   free-text color/size editor still works as a fallback.

## Defaults & seeds
- 5 attributes seeded via `Seed_VariantAttributes.sql`.
- Apparel-style fashion subcategories (MEN/WOMEN/KIDS minus footwear/accessories)
  get the full size/color/material/pattern/fit library. Footwear gets shoe sizes
  + color + material. See `Seed_SubCategoryVariantOptions.sql` for the matrix.
- Home/Gift/Beauty subcategories intentionally have an empty library — the
  free-text variant editor remains the right tool there.

## Error codes
| # | Meaning |
|---|---|
| 50200 | Category not found |
| 50201 | Category has products — cannot delete |
| 50202 | Parent category not found |
| 50203 | Subcategory not found |
| 50204 | Subcategory has products — cannot delete |
| 50220 | Variant option not found |
| 50221 | Product not owned by seller (PUT disabled-options) |
