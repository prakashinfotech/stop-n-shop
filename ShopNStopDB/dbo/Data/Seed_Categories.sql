SET IDENTITY_INSERT [dbo].[Categories] ON;

MERGE [dbo].[Categories] AS tgt
USING (VALUES
    (1,  1,  N'Clothing',              N'clothing',              1, 1),
    (2,  1,  N'Footwear',              N'footwear',              2, 1),
    (3,  4,  N'Electronics',           N'electronics',           3, 1),
    (4,  4,  N'Mobiles & Tablets',     N'mobiles-tablets',       4, 1),
    (5,  5,  N'Beauty & Personal Care',N'beauty-personal-care',  1, 1),
    (6,  4,  N'Home & Living',         N'home-living',           1, 1),
    (7,  1,  N'Sports & Fitness',      N'sports-fitness',        5, 1),
    (8,  1,  N'Bags & Luggage',        N'bags-luggage',          6, 1),
    (9,  8,  N'Watches & Accessories', N'watches-accessories',   1, 1),
    (10, 3,  N'Toys & Baby',           N'toys-baby',             1, 1),
    -- Women > Clothing — hoisted out of Seed_CatalogSample so fresh deploys
    -- have the WOMEN menu populated without depending on the catalog seed.
    (13, 2,  N'Clothing',              N'women-clothing',        1, 1),
    (14, 2,  N'Footwear',              N'women-footwear',        2, 1)
) AS src ([CategoryId], [MenuId], [CategoryName], [SlugUrl], [SortOrder], [IsActive])
ON tgt.[CategoryId] = src.[CategoryId]
WHEN MATCHED THEN UPDATE SET
    tgt.[MenuId]        = src.[MenuId],
    tgt.[CategoryName]  = src.[CategoryName],
    tgt.[SlugUrl]       = src.[SlugUrl],
    tgt.[SortOrder]     = src.[SortOrder],
    tgt.[IsActive]      = src.[IsActive]
WHEN NOT MATCHED THEN INSERT
    ([CategoryId], [MenuId], [CategoryName], [SlugUrl], [SortOrder], [IsActive],
     [CreatedAt], [IsDeleted])
VALUES
    (src.[CategoryId], src.[MenuId], src.[CategoryName], src.[SlugUrl],
     src.[SortOrder], src.[IsActive], GETUTCDATE(), 0);

SET IDENTITY_INSERT [dbo].[Categories] OFF;

-- Reseed identity so new inserts start after the highest seeded id (14)
DBCC CHECKIDENT ('[dbo].[Categories]', RESEED, 14);
GO
