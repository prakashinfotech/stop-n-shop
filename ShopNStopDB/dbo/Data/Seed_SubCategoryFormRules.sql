SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Backfills the per-subcategory product-form schema by name heuristic.
-- Idempotent: only updates rows whose schema is still NULL (untouched by admin).
-- Admin can override any row from the "Form rules" tab in the categories drawer.

;WITH Rules AS (
    SELECT
        sc.[SubCategoryId],
        sc.[SubCategoryName],
        c.[CategoryName],
        CASE
            -- footwear
            WHEN c.[CategoryName] LIKE N'%Footwear%'
              OR sc.[SubCategoryName] LIKE N'%Shoe%'
              OR sc.[SubCategoryName] LIKE N'%Sneaker%'
              OR sc.[SubCategoryName] LIKE N'%Sandal%'
              OR sc.[SubCategoryName] LIKE N'%Boot%'
              OR sc.[SubCategoryName] LIKE N'%Heel%'
                THEN N'footwear'
            -- apparel-bottom
            WHEN sc.[SubCategoryName] LIKE N'%Jean%'
              OR sc.[SubCategoryName] LIKE N'%Trouser%'
              OR sc.[SubCategoryName] LIKE N'%Pant%'
              OR sc.[SubCategoryName] LIKE N'%Skirt%'
              OR sc.[SubCategoryName] LIKE N'%Short%'
              OR sc.[SubCategoryName] LIKE N'%Legging%'
                THEN N'apparel-bottom'
            -- apparel-top
            WHEN sc.[SubCategoryName] LIKE N'%Shirt%'
              OR sc.[SubCategoryName] LIKE N'%T-Shirt%'
              OR sc.[SubCategoryName] LIKE N'%Tshirt%'
              OR sc.[SubCategoryName] LIKE N'%Top%'
              OR sc.[SubCategoryName] LIKE N'%Dress%'
              OR sc.[SubCategoryName] LIKE N'%Kurta%'
              OR sc.[SubCategoryName] LIKE N'%Jacket%'
              OR sc.[SubCategoryName] LIKE N'%Sweater%'
              OR sc.[SubCategoryName] LIKE N'%Polo%'
              OR sc.[SubCategoryName] LIKE N'%Hoodie%'
                THEN N'apparel-top'
            -- beauty
            WHEN c.[CategoryName] LIKE N'%Beauty%'
              OR c.[CategoryName] LIKE N'%Perfume%'
              OR c.[CategoryName] LIKE N'%Fragrance%'
              OR sc.[SubCategoryName] LIKE N'%Makeup%'
              OR sc.[SubCategoryName] LIKE N'%Lipstick%'
              OR sc.[SubCategoryName] LIKE N'%Skincare%'
              OR sc.[SubCategoryName] LIKE N'%Fragrance%'
              OR sc.[SubCategoryName] LIKE N'%Perfume%'
                THEN N'beauty'
            -- toys
            WHEN c.[CategoryName] LIKE N'%Toy%'
              OR sc.[SubCategoryName] LIKE N'%Toy%'
              OR sc.[SubCategoryName] LIKE N'%Game%'
                THEN N'toys'
            -- home / furniture / luggage
            WHEN c.[CategoryName] LIKE N'%Home%'
              OR c.[CategoryName] LIKE N'%Furniture%'
              OR c.[CategoryName] LIKE N'%Luggage%'
              OR sc.[SubCategoryName] LIKE N'%Sofa%'
              OR sc.[SubCategoryName] LIKE N'%Chair%'
              OR sc.[SubCategoryName] LIKE N'%Table%'
              OR sc.[SubCategoryName] LIKE N'%Bed%'
              OR sc.[SubCategoryName] LIKE N'%Suitcase%'
              OR sc.[SubCategoryName] LIKE N'%Luggage%'
              OR sc.[SubCategoryName] LIKE N'%Backpack%'
                THEN N'home'
            -- watches / accessories / bags / wallets
            WHEN c.[CategoryName] LIKE N'%Watch%'
              OR c.[CategoryName] LIKE N'%Accessor%'
              OR sc.[SubCategoryName] LIKE N'%Watch%'
              OR sc.[SubCategoryName] LIKE N'%Bag%'
              OR sc.[SubCategoryName] LIKE N'%Wallet%'
              OR sc.[SubCategoryName] LIKE N'%Belt%'
              OR sc.[SubCategoryName] LIKE N'%Sunglass%'
                THEN N'accessory'
            ELSE N'other'
        END AS [Bucket]
    FROM [dbo].[SubCategories] sc
    INNER JOIN [dbo].[Categories] c ON c.[CategoryId] = sc.[CategoryId]
    WHERE sc.[IsDeleted] = 0
)
UPDATE sc
SET
    [ImageAngles] = CASE r.[Bucket]
        WHEN N'apparel-top'    THEN N'["front","back","left","right"]'
        WHEN N'apparel-bottom' THEN N'["front","back"]'
        WHEN N'footwear'       THEN N'["front","back","left","right"]'
        WHEN N'beauty'         THEN N'["single"]'
        WHEN N'toys'           THEN N'["front","back"]'
        WHEN N'home'           THEN N'["front","back","left","right"]'
        WHEN N'accessory'      THEN N'["single"]'
        ELSE                        N'["front"]'
    END,
    [SizeScale] = CASE r.[Bucket]
        WHEN N'apparel-top'    THEN N'apparel'
        WHEN N'apparel-bottom' THEN N'apparel'
        WHEN N'footwear'       THEN N'shoe-uk'
        WHEN N'toys'           THEN N'toy'
        ELSE                        N'none'
    END,
    [RequiresGender] = CASE WHEN r.[Bucket] IN (N'apparel-top', N'apparel-bottom', N'footwear') THEN 1 ELSE 0 END,
    [RequiresDimensions] = CASE WHEN r.[Bucket] IN (N'toys', N'home') THEN 1 ELSE 0 END,
    [UpdatedAt] = GETUTCDATE()
FROM [dbo].[SubCategories] sc
INNER JOIN Rules r ON r.[SubCategoryId] = sc.[SubCategoryId]
WHERE sc.[ImageAngles] IS NULL;    -- only seed untouched rows; admin overrides stick
GO
