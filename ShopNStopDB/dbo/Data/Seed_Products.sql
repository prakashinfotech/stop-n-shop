-- Seeds demo products: 2 per subcategory + extra in small categories so every category has >=5.
-- Idempotent: MERGE on Sku. Uses the demo seller seeded in Seed_DemoSeller.sql.

DECLARE @DemoSellerId INT = (
    SELECT s.[SellerId]
    FROM [dbo].[Sellers] s
    INNER JOIN [dbo].[Users] u ON u.[UserId] = s.[UserId]
    WHERE u.[Email] = N'demoseller@stopnshop.com'
);

IF @DemoSellerId IS NULL
BEGIN
    PRINT 'Seed_Products: demo seller not found, skipping.';
    RETURN;
END;

-- Staging: (SubCategoryId, ProductName, BrandId, MRP, SellingPrice)
DECLARE @Staging TABLE (
    SubCategoryId INT, ProductName NVARCHAR(300), BrandId INT,
    MRP DECIMAL(18,2), SellingPrice DECIMAL(18,2), RowIdx INT
);

;WITH P AS (
    SELECT * FROM (VALUES
        -- Clothing (Cat 1)
        (1,  N'Classic Crew Neck T-Shirt',      1,  999,  599, 1),
        (1,  N'Premium Cotton Round Neck Tee',  3,  1199, 749, 2),
        (2,  N'Slim Fit Casual Shirt',          7,  1799, 1199, 1),
        (2,  N'Linen Blend Office Shirt',       8,  2299, 1499, 2),
        (3,  N'Slim Fit Stretch Jeans',         5,  2499, 1599, 1),
        (3,  N'Tapered Chino Trouser',          7,  1999, 1299, 2),
        (4,  N'Floral Summer Dress',            4,  2499, 1799, 1),
        (4,  N'A-Line Midi Dress',              10, 1999, 1399, 2),
        (5,  N'Floral Anarkali Kurta',          9,  2299, 1499, 1),
        (5,  N'Embroidered Cotton Kurti',       10, 1599, 999, 2),
        -- Footwear (Cat 2)
        (6,  N'Air Max Running Sneakers',       1,  6999, 4999, 1),
        (6,  N'Court Lifestyle Sneakers',       2,  4999, 3499, 2),
        (7,  N'Formal Oxford Leather Shoes',    11, 4499, 3199, 1),
        (7,  N'Slip-On Office Loafers',         7,  3499, 2399, 2),
        (8,  N'Comfort Slide Sandals',          6,  1599, 899, 1),
        (8,  N'Casual Flip-Flops',              1,  999,  599, 2),
        -- Electronics (Cat 3)
        (9,  N'14" Ultraslim Laptop i5/16GB',   12, 75999, 64999, 1),
        (9,  N'15" Performance Laptop i7/32GB', 14, 105999,89999, 2),
        (10, N'Wireless Noise-Cancel Headphones',14, 24999,18999, 1),
        (10, N'Studio Over-Ear Headphones',     12, 14999, 9999, 2),
        (11, N'24MP Mirrorless Camera Body',    12, 65999, 54999, 1),
        (11, N'Compact Travel Camera',          14, 35999, 27999, 2),
        -- Mobiles (Cat 4)
        (12, N'Pro Smartphone 256GB',           12, 89999, 74999, 1),
        (12, N'Lite Smartphone 128GB',          14, 22999, 17999, 2),
        (13, N'10.9" Tablet 128GB Wi-Fi',       12, 45999, 37999, 1),
        (13, N'8" Compact Tablet 64GB',         14, 18999, 14999, 2),
        (14, N'Fast Charger 65W',               12, 2499, 1599, 1),
        (14, N'Bluetooth Earbuds',              14, 4999, 2999, 2),
        -- Beauty (Cat 5)
        (15, N'Hydrating Face Serum 30ml',      13, 1299, 899, 1),
        (15, N'Vitamin C Brightening Cream',    14, 1499, 999, 2),
        (16, N'Argan Oil Hair Shampoo 400ml',   14, 799, 549, 1),
        (16, N'Keratin Smooth Conditioner',     13, 899, 599, 2),
        (17, N'Eau de Parfum 100ml Citrus',     4,  3999, 2799, 1),
        (17, N'Body Mist Floral 200ml',         13, 999, 599, 2),
        -- Home (Cat 6)
        (18, N'3-Seater Fabric Sofa',           15, 39999, 29999, 1),
        (18, N'Solid Wood Coffee Table',        15, 12999, 8999, 2),
        (19, N'Stainless Steel Cookware Set',   15, 5999, 3999, 1),
        (19, N'Ceramic Dinner Set 32-Piece',    15, 4499, 2999, 2),
        (20, N'King Size Cotton Bedsheet Set',  3,  2499, 1599, 1),
        (20, N'Microfiber Comforter Queen',     3,  3499, 2299, 2),
        -- Sports (Cat 7) -- extra (3 in subcat 21) to make cat >= 5
        (21, N'Adjustable Dumbbell 10kg',       6,  4999, 3499, 1),
        (21, N'Yoga Mat 6mm Premium',           6,  1999, 1299, 2),
        (21, N'Resistance Bands Set',           2,  1499, 899, 3),
        (22, N'Trekking Backpack 50L',          11, 4999, 3499, 1),
        (22, N'Cricket Bat English Willow',     2,  6999, 5499, 2),
        -- Bags (Cat 8) -- extra in subcat 23
        (23, N'Leather Tote Handbag',           4,  3999, 2499, 1),
        (23, N'Sling Crossbody Bag',            10, 2499, 1599, 2),
        (23, N'Quilted Shoulder Bag',           4,  3499, 2199, 3),
        (24, N'Laptop Backpack 25L',            1,  2999, 1999, 1),
        (24, N'Travel Duffle Bag 60L',          11, 3999, 2599, 2),
        -- Watches (Cat 9) -- extra in subcat 25
        (25, N'Analog Steel Wristwatch',        12, 4999, 3299, 1),
        (25, N'Smart Fitness Watch',            12, 8999, 6499, 2),
        (25, N'Chronograph Sports Watch',       12, 12999, 8999, 3),
        (26, N'Sterling Silver Pendant',        12, 3999, 2499, 1),
        (26, N'Gold-Plated Hoop Earrings',      12, 2499, 1599, 2),
        -- Toys (Cat 10) -- extra in subcat 27
        (27, N'Wooden Educational Puzzle',      15, 1499, 899, 1),
        (27, N'RC Remote Car Toy',              15, 2999, 1999, 2),
        (27, N'Building Blocks Set 250pc',      15, 1999, 1299, 3),
        (28, N'Baby Soft Cotton Onesie Set',    3,  1499, 899, 1),
        (28, N'Newborn Hooded Bath Towel',      3,  999, 649, 2)
    ) v(SubCategoryId, ProductName, BrandId, MRP, SellingPrice, RowIdx)
)
INSERT INTO @Staging SELECT * FROM P;

-- Build MERGE source with computed Sku, SlugUrl, CategoryId
;WITH Src AS (
    SELECT
        s.SubCategoryId,
        sc.[CategoryId],
        s.BrandId,
        s.ProductName,
        s.MRP,
        s.SellingPrice,
        N'SEED-' + RIGHT('00' + CAST(s.SubCategoryId AS NVARCHAR(2)), 2) + N'-' + CAST(s.RowIdx AS NVARCHAR(2)) AS Sku,
        N'seed-' + LOWER(REPLACE(REPLACE(REPLACE(REPLACE(s.ProductName,' ','-'),'"',''),'/',''),'&','and')) + N'-' + CAST(s.SubCategoryId AS NVARCHAR(3)) + N'-' + CAST(s.RowIdx AS NVARCHAR(2)) AS SlugUrl
    FROM @Staging s
    INNER JOIN [dbo].[SubCategories] sc ON sc.[SubCategoryId] = s.SubCategoryId
)
MERGE [dbo].[Products] AS tgt
USING Src AS src
ON tgt.[Sku] = src.Sku
WHEN NOT MATCHED THEN INSERT
    ([SellerId], [BrandId], [CategoryId], [SubCategoryId],
     [ProductName], [SlugUrl], [ShortDescription],
     [MRP], [SellingPrice], [Sku], [ApprovalStatus],
     [CreatedAt], [CreatedBy], [IsActive], [IsDeleted], [PublishedAt])
VALUES
    (@DemoSellerId, src.BrandId, src.CategoryId, src.SubCategoryId,
     src.ProductName, src.SlugUrl, src.ProductName,
     src.MRP, src.SellingPrice, src.Sku, 2,
     GETUTCDATE(), NULL, 1, 0, GETUTCDATE());
GO

-- Attach a category-themed primary image to any seeded product missing one.
-- Uses Unsplash CDN URLs (no auth required, no rate-limit at this volume).
;WITH ImgPerCategory AS (
    SELECT * FROM (VALUES
        (1,  N'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600'),  -- Clothing
        (2,  N'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'),    -- Footwear
        (3,  N'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600'), -- Electronics
        (4,  N'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600'), -- Mobiles
        (5,  N'https://images.unsplash.com/photo-1522335789203-aaa92b86b4ec?w=600'), -- Beauty
        (6,  N'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=600'), -- Home & Living
        (7,  N'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600'), -- Sports
        (8,  N'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'),    -- Bags
        (9,  N'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=600'), -- Watches
        (10, N'https://images.unsplash.com/photo-1558060370-d644479cb6f7?w=600')     -- Toys & Baby
    ) v(CategoryId, ImageUrl)
)
INSERT INTO [dbo].[ProductImages] ([ProductId], [ImageUrl], [IsPrimary], [SortOrder])
SELECT p.[ProductId], ic.[ImageUrl], 1, 0
FROM [dbo].[Products] p
INNER JOIN ImgPerCategory ic ON ic.CategoryId = p.[CategoryId]
LEFT  JOIN [dbo].[ProductImages] pi ON pi.[ProductId] = p.[ProductId] AND pi.[IsPrimary] = 1 AND pi.[IsDeleted] = 0
WHERE p.[Sku] LIKE N'SEED-%' AND pi.[ImageId] IS NULL;
GO

-- Backfill a single default variant for every seeded product that doesn't have
-- one yet. Cart/order flows require a VariantId; without this the add-to-cart
-- API throws "No available variant found for this product."
INSERT INTO [dbo].[ProductVariants]
    ([ProductId], [Color], [ColorHexCode], [Size], [VariantSku],
     [AdditionalPrice], [StockQuantity], [LowStockThreshold], [IsActive], [IsDeleted])
SELECT
    p.[ProductId], N'Default', NULL, NULL,
    N'V' + RIGHT(N'000000' + CAST(p.[ProductId] AS NVARCHAR(10)), 6) + N'-DEFAULT',
    0, 50, 5, 1, 0
FROM [dbo].[Products] p
WHERE p.[IsDeleted] = 0
  AND NOT EXISTS (
      SELECT 1 FROM [dbo].[ProductVariants] pv
      WHERE pv.[ProductId] = p.[ProductId] AND pv.[IsDeleted] = 0 AND pv.[IsActive] = 1
  );
GO
