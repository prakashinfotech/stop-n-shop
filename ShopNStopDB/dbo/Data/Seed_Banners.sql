SET IDENTITY_INSERT [dbo].[Banners] ON;

-- Banner seed — idempotent MERGE on BannerId. Images are curated Unsplash assets
-- (license-clean) tuned for fashion catalogues. Routes target real React Router paths
-- under /home/* and /home/category/<slug> from Seed_Menus.sql.
--
-- BannerType layout (the BannerStack component groups consecutive banners by
-- the `Section` column and renders each group as a single auto-rotating slot):
--   1 = HERO carousel (top of homepage, full-bleed 78vh)
--   2 = First promo strip (right under the Shop-by-Department row)
--   3 = Brand spotlight
--   4 = Category duo (split between two banners)
--   5 = Kids / Editorial
--   6 = Beauty
--   7 = Watches / closing strip
MERGE [dbo].[Banners] AS tgt
USING (VALUES
    -- ── HERO carousel (BannerType = 1) — 5 slides for a real rotation ─────────
    (1,  N'Summer Edit 2026',          N'Up to 60% off across the season''s most-loved styles.',
         N'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1920&q=80&auto=format&fit=crop',
         N'/home/products?sortBy=LATEST', 1, 1, 0, NULL),
    (2,  N'Women''s Statement Looks',  N'Curated drops for every occasion.',
         N'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=1920&q=80&auto=format&fit=crop',
         N'/home/category/women', 1, 2, 0, NULL),
    (3,  N'Men''s Season Edit',         N'From smart casuals to occasion wear — all new arrivals.',
         N'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=1920&q=80&auto=format&fit=crop',
         N'/home/category/men', 1, 3, 0, NULL),
    (11, N'Festive Fits, ready early', N'Shop the festive lookbook — handpicked for the season ahead.',
         N'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1920&q=80&auto=format&fit=crop',
         N'/home/products?sortBy=LATEST', 1, 4, 0, NULL),
    (12, N'Premium Watches',           N'Mechanical movements, smart faces, and everything in between.',
         N'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=1920&q=80&auto=format&fit=crop',
         N'/home/category/watches', 1, 5, 0, NULL),

    -- ── PROMO row (BannerType = 2) — typographic strip pair ───────────────────
    (4,  N'WELCOME10 — 10% off your first order',
         N'Auto-applied at checkout for new members.',
         N'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1600&q=80&auto=format&fit=crop',
         N'/home/products', 2, 1, 20, N'#faf6ec'),
    (13, N'Free shipping on ₹999+',
         N'No code needed — applied automatically at checkout.',
         N'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=1600&q=80&auto=format&fit=crop',
         N'/home/products', 2, 2, 32, N'#f4f1ea'),

    -- ── BRAND spotlight (BannerType = 3) ─────────────────────────────────────
    (5,  N'Premium Brands',             N'Allen Solly, Levi''s, U.S. Polo Assn., and 40+ more.',
         N'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1600&q=80&auto=format&fit=crop',
         N'/home/products', 3, 1, 20, NULL),
    (14, N'Designer Spotlight',         N'Fresh from the runway — limited drops every Friday.',
         N'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1600&q=80&auto=format&fit=crop',
         N'/home/products?sortBy=LATEST', 3, 2, 32, NULL),

    -- ── CATEGORY duo (BannerType = 4) — two-up split ─────────────────────────
    (6,  N'Women''s Fashion',           N'Dresses, kurtas, denim — curated for her.',
         N'https://images.unsplash.com/photo-1485462537746-965f33f7f6a7?w=1600&q=80&auto=format&fit=crop',
         N'/home/category/women', 4, 1, 0, NULL),
    (7,  N'Men''s Essentials',          N'Shirts, chinos, jackets — wardrobe staples.',
         N'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=1600&q=80&auto=format&fit=crop',
         N'/home/category/men', 4, 2, 32, NULL),

    -- ── KIDS + editorial (BannerType = 5) ─────────────────────────────────────
    (8,  N'Little Trendsetters',        N'Playful styles built to last.',
         N'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=1600&q=80&auto=format&fit=crop',
         N'/home/category/kids', 5, 1, 0, NULL),
    (15, N'Back to School',             N'Comfortable, durable, and ready for every adventure.',
         N'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=1600&q=80&auto=format&fit=crop',
         N'/home/category/kids', 5, 2, 32, NULL),

    -- ── BEAUTY (BannerType = 6) ──────────────────────────────────────────────
    (9,  N'Beauty Essentials',          N'Skincare, fragrance, and makeup picks.',
         N'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=1600&q=80&auto=format&fit=crop',
         N'/home/category/beauty', 6, 1, 0, N'#fdf4f4'),
    (16, N'Glow Edit',                   N'Hand-picked routines for radiant skin all year.',
         N'https://images.unsplash.com/photo-1522335789203-aaa9ab6f8a04?w=1600&q=80&auto=format&fit=crop',
         N'/home/category/beauty', 6, 2, 32, N'#fbeae5'),

    -- ── WATCHES + closing accessories (BannerType = 7) ───────────────────────
    (10, N'Watches & Accessories',      N'Mechanical to smart — find your fit.',
         N'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=1600&q=80&auto=format&fit=crop',
         N'/home/category/watches', 7, 1, 0, NULL),
    (17, N'Bags & Luggage',             N'Carry-ons, totes, and weekenders for every trip.',
         N'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=1600&q=80&auto=format&fit=crop',
         N'/home/products?categoryId=8', 7, 2, 48, NULL)
) AS src ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder], [GapBelowPx], [BackgroundColor])
ON tgt.[BannerId] = src.[BannerId]
WHEN MATCHED THEN UPDATE SET
    tgt.[Title]           = src.[Title],
    tgt.[SubTitle]        = src.[SubTitle],
    tgt.[ImageUrl]        = src.[ImageUrl],
    tgt.[LinkUrl]         = src.[LinkUrl],
    tgt.[BannerType]      = src.[BannerType],
    tgt.[SortOrder]       = src.[SortOrder],
    tgt.[GapBelowPx]      = src.[GapBelowPx],
    tgt.[BackgroundColor] = src.[BackgroundColor]
WHEN NOT MATCHED THEN INSERT
    ([BannerId], [Title], [SubTitle], [ImageUrl], [LinkUrl], [BannerType], [SortOrder],
     [GapBelowPx], [BackgroundColor],
     [CreatedAt], [IsActive], [IsDeleted])
VALUES
    (src.[BannerId], src.[Title], src.[SubTitle], src.[ImageUrl], src.[LinkUrl],
     src.[BannerType], src.[SortOrder], src.[GapBelowPx], src.[BackgroundColor],
     GETUTCDATE(), 1, 0);

SET IDENTITY_INSERT [dbo].[Banners] OFF;

DBCC CHECKIDENT ('[dbo].[Banners]', RESEED, 17);
GO
