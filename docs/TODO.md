# Production Readiness TODO

Tracking items that must be resolved before the StopNShop platform is production-ready.

> Last updated: 2026-05-12

---

## 1. Mega Menu — missing top menus

**Problem:** `/api/menu` only returns MEN, KIDS, HOME, BEAUTY, WATCHES. Missing: WOMEN, HOMESTOP, GIFTS, PERFUMES, BRANDS.

**Root cause:** `sp_GetMegaMenu` uses `INNER JOIN Categories → SubCategories`. Any top menu without at least one Category that has at least one SubCategory is filtered out of the result.

**Fix plan:**
- [ ] Add `Categories` rows for WOMEN (MenuId=2): e.g. Clothing, Footwear, Beauty, Bags, Watches, etc.
- [ ] Add `Categories` rows for HOMESTOP (MenuId=6): e.g. Furniture, Décor, Kitchen, Bath.
- [ ] Add `Categories` rows for GIFTS (MenuId=7): e.g. For Him, For Her, For Kids, Premium.
- [ ] Add `Categories` rows for PERFUMES (MenuId=9): e.g. Men's, Women's, Unisex, Gift Sets.
- [ ] Decide approach for BRANDS (MenuId=10) — likely a different rendering, not category-based (separate endpoint or different SP variant).
- [ ] Add `SubCategories` for each new Category (T-Shirts, Polos, Shirts, etc., per the business requirement).
- [ ] All additions go through `Seed_Categories.sql` and `Seed_SubCategories.sql` (no ad-hoc migrations — see memory rule).

---

## 2. `/api/banners?position=HOME` returns 500

**Root cause:** `sp_GetBanners` is called by `CatalogueRepository.GetBannersAsync()` but **does not exist** in the SSDT project (`ShopNStopDB/dbo/StoredProcedures/`). Endpoint throws on execute.

**Fix plan:**
- [ ] Verify `Banners` table exists in SSDT; create it if missing (columns: Id, Position, ImageUrl, Title, Subtitle, LinkUrl, SortOrder, IsActive, IsDeleted, audit).
- [ ] Create `dbo/StoredProcedures/sp_GetBanners.sql` accepting `@Position NVARCHAR(50)`, returning active banners for that position, ordered by SortOrder.
- [ ] Add `Seed_Banners.sql` with at least HOME, PROMO, CATEGORY position rows (real image URLs / placeholders).
- [ ] Wire `:r .\dbo\Data\Seed_Banners.sql` into `Script.PostDeployment.sql`.
- [ ] Rebuild + publish SSDT; verify endpoint returns 200 with data.

---

## 3. `/api/stores` returns 500

**Root cause:** Same pattern — `sp_GetStores` is missing from SSDT. The endpoint was likely working before because the SP existed in the database manually; the most recent SSDT publish dropped it because SSDT defaults to *drop objects not in source*.

**Fix plan:**
- [ ] Verify `Stores` table exists in SSDT; create if missing.
- [ ] Create `dbo/StoredProcedures/sp_GetStores.sql` accepting optional `@City NVARCHAR(100)`.
- [ ] Add `Seed_Stores.sql` with a few city locations.
- [ ] Wire into `Script.PostDeployment.sql`.
- [ ] Also audit for `sp_GetPincodeDelivery` (same risk — called by repo, likely missing).
- [ ] Consider adding `/p:DropObjectsNotInSource=False` to the SqlPackage publish args in `scripts/deploy-local.ps1` for *dev* mode to prevent accidental drops, while keeping strict behavior for CI/production deploys.

---

## Cross-cutting hygiene
- [ ] Audit `CatalogueRepository` and all other repositories for SP names that don't have corresponding `.sql` files in SSDT.
- [ ] Add a CI step that fails the build if any C# Dapper call references an SP not present in the SSDT project.
