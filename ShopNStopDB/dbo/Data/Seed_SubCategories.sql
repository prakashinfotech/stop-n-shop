SET IDENTITY_INSERT [dbo].[SubCategories] ON;

-- Adds IsFeatured + IconUrl so the Home "Trending Categories" rail has tiles
-- on a fresh deploy. Admin can re-curate via /admin/categories at any time;
-- the MERGE will overwrite these values on the next dacpac deploy, which is
-- intentional — this file is the source of truth for seed/demo data.
MERGE [dbo].[SubCategories] AS tgt
USING (VALUES
    -- Clothing (CategoryId=1)
    (1,  1, N'T-Shirts',          N't-shirts',          1, 1, N'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=800&q=80'),
    (2,  1, N'Shirts',            N'shirts',            1, 1, N'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=800&q=80'),
    (3,  1, N'Jeans & Trousers',  N'jeans-trousers',    1, 1, N'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800&q=80'),
    (4,  1, N'Dresses',           N'dresses',           1, 1, N'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=800&q=80'),
    (5,  1, N'Ethnic Wear',       N'ethnic-wear',       1, 0, N'https://images.unsplash.com/photo-1622519407650-3df9883f76a5?w=800&q=80'),
    -- Footwear (CategoryId=2)
    (6,  2, N'Sneakers',          N'sneakers',          1, 1, N'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80'),
    (7,  2, N'Formal Shoes',      N'formal-shoes',      1, 0, N'https://images.unsplash.com/photo-1614252369475-531eba835eb1?w=800&q=80'),
    (8,  2, N'Sandals & Slippers',N'sandals-slippers',  1, 0, N'https://images.unsplash.com/photo-1603487742131-4160ec999306?w=800&q=80'),
    -- Electronics (CategoryId=3)
    (9,  3, N'Laptops',           N'laptops',           1, 0, NULL),
    (10, 3, N'Headphones',        N'headphones',        1, 0, NULL),
    (11, 3, N'Cameras',           N'cameras',           1, 0, NULL),
    -- Mobiles & Tablets (CategoryId=4)
    (12, 4, N'Smartphones',       N'smartphones',       1, 0, NULL),
    (13, 4, N'Tablets',           N'tablets',           1, 0, NULL),
    (14, 4, N'Mobile Accessories',N'mobile-accessories',1, 0, NULL),
    -- Beauty (CategoryId=5)
    (15, 5, N'Skincare',          N'skincare',          1, 1, N'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80'),
    (16, 5, N'Haircare',          N'haircare',          1, 0, NULL),
    (17, 5, N'Fragrances',        N'fragrances',        1, 1, N'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800&q=80'),
    -- Home & Living (CategoryId=6)
    (18, 6, N'Furniture',         N'furniture',         1, 0, NULL),
    (19, 6, N'Kitchen & Dining',  N'kitchen-dining',    1, 0, NULL),
    (20, 6, N'Bedding',           N'bedding',           1, 0, N'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=80'),
    -- Sports (CategoryId=7)
    (21, 7, N'Gym & Fitness',     N'gym-fitness',       1, 0, NULL),
    (22, 7, N'Outdoor Sports',    N'outdoor-sports',    1, 0, NULL),
    -- Bags (CategoryId=8)
    (23, 8, N'Handbags',          N'handbags',          1, 1, N'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80'),
    (24, 8, N'Backpacks',         N'backpacks',         1, 0, NULL),
    -- Watches (CategoryId=9)
    (25, 9, N'Watches',           N'watches',           1, 1, N'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80'),
    (26, 9, N'Jewellery',         N'jewellery',         1, 1, N'https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=800&q=80'),
    -- Toys (CategoryId=10)
    (27, 10, N'Toys & Games',     N'toys-games',        1, 0, NULL),
    (28, 10, N'Baby Essentials',  N'baby-essentials',   1, 0, NULL),
    -- Women > Clothing (CategoryId=13)
    (29, 13, N'Dresses',          N'women-dresses',     1, 0, NULL),
    (30, 13, N'Tops',             N'women-tops',        1, 0, NULL),
    (31, 13, N'Sarees',           N'women-sarees',      1, 1, N'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&q=80'),
    (32, 13, N'Kurtas & Kurtis',  N'women-kurtas',      1, 0, NULL),
    (33, 13, N'Ethnic Wear',      N'women-ethnic',      1, 0, NULL),
    -- Women > Footwear (CategoryId=14)
    (34, 14, N'All Shoes',        N'women-shoes',       1, 1, N'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=800&q=80')
) AS src ([SubCategoryId], [CategoryId], [SubCategoryName], [SlugUrl], [IsActive], [IsFeatured], [IconUrl])
ON tgt.[SubCategoryId] = src.[SubCategoryId]
WHEN MATCHED THEN UPDATE SET
    tgt.[CategoryId]      = src.[CategoryId],
    tgt.[SubCategoryName] = src.[SubCategoryName],
    tgt.[SlugUrl]         = src.[SlugUrl],
    tgt.[IsActive]        = src.[IsActive],
    tgt.[IsFeatured]      = src.[IsFeatured],
    tgt.[IconUrl]         = src.[IconUrl]
WHEN NOT MATCHED THEN INSERT
    ([SubCategoryId], [CategoryId], [SubCategoryName], [SlugUrl], [IsActive],
     [IsFeatured], [IconUrl],
     [CreatedAt], [IsDeleted])
VALUES
    (src.[SubCategoryId], src.[CategoryId], src.[SubCategoryName], src.[SlugUrl],
     src.[IsActive], src.[IsFeatured], src.[IconUrl], GETUTCDATE(), 0);

SET IDENTITY_INSERT [dbo].[SubCategories] OFF;

DBCC CHECKIDENT ('[dbo].[SubCategories]', RESEED, 34);
GO
