/*
 * 2026-05-26 — Home data patch
 *
 * Purpose:
 *   Fills in homepage content (featured subcategories with icons + extra
 *   promotional banners) WITHOUT overwriting any admin-curated edits.
 *
 * Safety:
 *   - SubCategory updates run ONLY where IsFeatured = 0 AND IconUrl IS NULL.
 *     Rows admin has already curated are skipped.
 *   - Banner inserts use IF NOT EXISTS guards on BannerId. Existing banners
 *     (IDs 1–10) are never touched.
 *   - Re-runnable. Running this twice is a no-op the second time.
 *
 * How to apply (Docker SQL Server, container name = stopnshop-db):
 *   docker cp db/patches/2026_05_26_home_data.sql stopnshop-db:/tmp/patch.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C \
 *     -d ShopNShop_db -b -I -i /tmp/patch.sql
 */

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '[patch] Starting 2026-05-26 home data patch...';

------------------------------------------------------------------------------
-- 1. Featured SubCategories (only where admin hasn't already curated)
------------------------------------------------------------------------------
PRINT '[patch] Subcategories: filling IsFeatured + IconUrl where empty...';

DECLARE @sc_updated INT = 0;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=800&q=80'
WHERE [SubCategoryId] = 1   AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=800&q=80'
WHERE [SubCategoryId] = 2   AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800&q=80'
WHERE [SubCategoryId] = 3   AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=800&q=80'
WHERE [SubCategoryId] = 4   AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80'
WHERE [SubCategoryId] = 6   AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80'
WHERE [SubCategoryId] = 15  AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800&q=80'
WHERE [SubCategoryId] = 17  AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80'
WHERE [SubCategoryId] = 23  AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80'
WHERE [SubCategoryId] = 25  AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=800&q=80'
WHERE [SubCategoryId] = 26  AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&q=80'
WHERE [SubCategoryId] = 31  AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

UPDATE [dbo].[SubCategories]
SET [IsFeatured] = 1,
    [IconUrl]    = N'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=800&q=80'
WHERE [SubCategoryId] = 34  AND [IsFeatured] = 0 AND [IconUrl] IS NULL;
SET @sc_updated += @@ROWCOUNT;

PRINT CONCAT('[patch] Subcategories updated: ', @sc_updated, ' (already-curated rows skipped)');

------------------------------------------------------------------------------
-- 2. Additional Banners (only insert IDs that don't already exist)
------------------------------------------------------------------------------
PRINT '[patch] Banners: inserting new rows where missing...';

DECLARE @b_inserted INT = 0;

-- IDENTITY_INSERT must be ON to provide explicit BannerId values.
SET IDENTITY_INSERT [dbo].[Banners] ON;

-- ── Hero carousel additions (BannerType = 1) ────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = 11)
BEGIN
    INSERT INTO [dbo].[Banners]
        ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder], [GapBelowPx], [BackgroundColor])
    VALUES
        (11, N'Festive Fits, ready early',
             N'Shop the festive lookbook — handpicked for the season ahead.',
             N'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1920&q=80&auto=format&fit=crop',
             N'/home/products?sortBy=LATEST', 1, 4, 0, NULL);
    SET @b_inserted += 1;
END

IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = 12)
BEGIN
    INSERT INTO [dbo].[Banners]
        ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder], [GapBelowPx], [BackgroundColor])
    VALUES
        (12, N'Premium Watches',
             N'Mechanical movements, smart faces, and everything in between.',
             N'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=1920&q=80&auto=format&fit=crop',
             N'/home/category/watches', 1, 5, 0, NULL);
    SET @b_inserted += 1;
END

-- ── Promo strip pair (BannerType = 2) ───────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = 13)
BEGIN
    INSERT INTO [dbo].[Banners]
        ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder], [GapBelowPx], [BackgroundColor])
    VALUES
        (13, N'Free shipping on ₹999+',
             N'No code needed — applied automatically at checkout.',
             N'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=1600&q=80&auto=format&fit=crop',
             N'/home/products', 2, 2, 32, N'#f4f1ea');
    SET @b_inserted += 1;
END

-- ── Brand spotlight pair (BannerType = 3) ───────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = 14)
BEGIN
    INSERT INTO [dbo].[Banners]
        ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder], [GapBelowPx], [BackgroundColor])
    VALUES
        (14, N'Designer Spotlight',
             N'Fresh from the runway — limited drops every Friday.',
             N'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1600&q=80&auto=format&fit=crop',
             N'/home/products?sortBy=LATEST', 3, 2, 32, NULL);
    SET @b_inserted += 1;
END

-- ── Kids / editorial (BannerType = 5) ───────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = 15)
BEGIN
    INSERT INTO [dbo].[Banners]
        ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder], [GapBelowPx], [BackgroundColor])
    VALUES
        (15, N'Back to School',
             N'Comfortable, durable, and ready for every adventure.',
             N'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=1600&q=80&auto=format&fit=crop',
             N'/home/category/kids', 5, 2, 32, NULL);
    SET @b_inserted += 1;
END

-- ── Beauty (BannerType = 6) ─────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = 16)
BEGIN
    INSERT INTO [dbo].[Banners]
        ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder], [GapBelowPx], [BackgroundColor])
    VALUES
        (16, N'Glow Edit',
             N'Hand-picked routines for radiant skin all year.',
             N'https://images.unsplash.com/photo-1522335789203-aaa9ab6f8a04?w=1600&q=80&auto=format&fit=crop',
             N'/home/category/beauty', 6, 2, 32, N'#fbeae5');
    SET @b_inserted += 1;
END

-- ── Closing accessories strip (BannerType = 7) ──────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = 17)
BEGIN
    INSERT INTO [dbo].[Banners]
        ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder], [GapBelowPx], [BackgroundColor])
    VALUES
        (17, N'Bags & Luggage',
             N'Carry-ons, totes, and weekenders for every trip.',
             N'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=1600&q=80&auto=format&fit=crop',
             N'/home/products?categoryId=8', 7, 2, 48, NULL);
    SET @b_inserted += 1;
END

SET IDENTITY_INSERT [dbo].[Banners] OFF;

-- Reseed identity to highest existing BannerId so the next admin-added banner
-- doesn't collide. Safe to run even if no rows were inserted.
-- (DBCC CHECKIDENT needs a literal, so use dynamic SQL.)
DECLARE @max_id  INT = (SELECT ISNULL(MAX([BannerId]), 0) FROM [dbo].[Banners]);
DECLARE @reseed  NVARCHAR(200) =
    N'DBCC CHECKIDENT (''[dbo].[Banners]'', RESEED, ' + CAST(@max_id AS NVARCHAR(20)) + N')';
EXEC sp_executesql @reseed;

PRINT CONCAT('[patch] Banners inserted: ', @b_inserted, ' (existing rows preserved)');

PRINT '[patch] Done.';
GO
