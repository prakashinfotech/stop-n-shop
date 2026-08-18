SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Seeds a sensible default variant library for fashion-style subcategories.
-- Skips Home/Gift/Beauty subcategories (no Size/Color picker makes sense).
-- Idempotent: re-running won't duplicate rows (uses NOT EXISTS).

DECLARE @attrSize     INT = (SELECT [AttributeId] FROM [dbo].[VariantAttributes] WHERE [AttributeKey] = N'size');
DECLARE @attrColor    INT = (SELECT [AttributeId] FROM [dbo].[VariantAttributes] WHERE [AttributeKey] = N'color');
DECLARE @attrMaterial INT = (SELECT [AttributeId] FROM [dbo].[VariantAttributes] WHERE [AttributeKey] = N'material');
DECLARE @attrPattern  INT = (SELECT [AttributeId] FROM [dbo].[VariantAttributes] WHERE [AttributeKey] = N'pattern');
DECLARE @attrFit      INT = (SELECT [AttributeId] FROM [dbo].[VariantAttributes] WHERE [AttributeKey] = N'fit');

IF @attrSize IS NULL RETURN;  -- variant attributes not yet seeded

-- Identify apparel-style subcategories
DECLARE @apparel TABLE ([SubCategoryId] INT NOT NULL PRIMARY KEY);
INSERT INTO @apparel ([SubCategoryId])
SELECT sc.[SubCategoryId]
FROM [dbo].[SubCategories] sc
INNER JOIN [dbo].[Categories]   c ON c.[CategoryId] = sc.[CategoryId]
WHERE sc.[IsDeleted] = 0
  AND c.[IsDeleted]  = 0
  AND c.[MenuId] IN (1, 2, 3)   -- MEN, WOMEN, KIDS
  AND c.[CategoryName] NOT LIKE N'%Footwear%'
  AND sc.[SubCategoryName] NOT LIKE N'%Bag%'
  AND sc.[SubCategoryName] NOT LIKE N'%Wallet%'
  AND sc.[SubCategoryName] NOT LIKE N'%Watch%'
  AND sc.[SubCategoryName] NOT LIKE N'%Accessory%'
  AND sc.[SubCategoryName] NOT LIKE N'%Accessories%';

-- Footwear subcategories
DECLARE @footwear TABLE ([SubCategoryId] INT NOT NULL PRIMARY KEY);
INSERT INTO @footwear ([SubCategoryId])
SELECT sc.[SubCategoryId]
FROM [dbo].[SubCategories] sc
INNER JOIN [dbo].[Categories]   c ON c.[CategoryId] = sc.[CategoryId]
WHERE sc.[IsDeleted] = 0
  AND c.[IsDeleted]  = 0
  AND (c.[CategoryName] LIKE N'%Footwear%' OR sc.[SubCategoryName] LIKE N'%Shoe%'
       OR sc.[SubCategoryName] LIKE N'%Sneaker%' OR sc.[SubCategoryName] LIKE N'%Sandal%'
       OR sc.[SubCategoryName] LIKE N'%Boot%' OR sc.[SubCategoryName] LIKE N'%Heel%');

-- Common apparel sizes (XS–XXL)
DECLARE @apparelSizes TABLE ([Val] NVARCHAR(100) NOT NULL, [Sort] INT NOT NULL);
INSERT INTO @apparelSizes VALUES (N'XS', 1), (N'S', 2), (N'M', 3), (N'L', 4), (N'XL', 5), (N'XXL', 6), (N'XXXL', 7);

-- Footwear sizes (UK)
DECLARE @shoeSizes TABLE ([Val] NVARCHAR(100) NOT NULL, [Sort] INT NOT NULL);
INSERT INTO @shoeSizes VALUES
    (N'5', 1), (N'6', 2), (N'7', 3), (N'8', 4), (N'9', 5), (N'10', 6), (N'11', 7), (N'12', 8);

-- Color palette
DECLARE @colors TABLE ([Val] NVARCHAR(100) NOT NULL, [Meta] NVARCHAR(200) NULL, [Sort] INT NOT NULL);
INSERT INTO @colors VALUES
    (N'Black',  N'#0F172A', 1),
    (N'White',  N'#F8FAFC', 2),
    (N'Red',    N'#DC2626', 3),
    (N'Blue',   N'#2563EB', 4),
    (N'Navy',   N'#1E3A8A', 5),
    (N'Green',  N'#16A34A', 6),
    (N'Beige',  N'#D6C8A6', 7),
    (N'Grey',   N'#6B7280', 8),
    (N'Brown',  N'#78350F', 9),
    (N'Pink',   N'#EC4899', 10),
    (N'Yellow', N'#EAB308', 11);

-- Materials
DECLARE @materials TABLE ([Val] NVARCHAR(100) NOT NULL, [Sort] INT NOT NULL);
INSERT INTO @materials VALUES
    (N'Cotton',    1),
    (N'Polyester', 2),
    (N'Linen',     3),
    (N'Wool',      4),
    (N'Denim',     5),
    (N'Silk',      6),
    (N'Leather',   7);

-- Patterns
DECLARE @patterns TABLE ([Val] NVARCHAR(100) NOT NULL, [Sort] INT NOT NULL);
INSERT INTO @patterns VALUES
    (N'Solid',    1),
    (N'Striped',  2),
    (N'Printed',  3),
    (N'Checked',  4),
    (N'Floral',   5),
    (N'Graphic',  6);

-- Fits
DECLARE @fits TABLE ([Val] NVARCHAR(100) NOT NULL, [Sort] INT NOT NULL);
INSERT INTO @fits VALUES
    (N'Slim',     1),
    (N'Regular',  2),
    (N'Relaxed',  3),
    (N'Oversized',4);

-- Helper: insert any missing option for a (subcat, attribute, value)
;WITH ApparelOptions AS (
    SELECT sc.[SubCategoryId], @attrSize AS [AttributeId], s.[Val] AS [OptionValue], CAST(NULL AS NVARCHAR(200)) AS [Meta], s.[Sort] AS [SortOrder]
        FROM @apparel sc CROSS JOIN @apparelSizes s
    UNION ALL
    SELECT sc.[SubCategoryId], @attrColor, c.[Val], c.[Meta], c.[Sort]
        FROM @apparel sc CROSS JOIN @colors c
    UNION ALL
    SELECT sc.[SubCategoryId], @attrMaterial, m.[Val], CAST(NULL AS NVARCHAR(200)), m.[Sort]
        FROM @apparel sc CROSS JOIN @materials m
    UNION ALL
    SELECT sc.[SubCategoryId], @attrPattern, p.[Val], CAST(NULL AS NVARCHAR(200)), p.[Sort]
        FROM @apparel sc CROSS JOIN @patterns p
    UNION ALL
    SELECT sc.[SubCategoryId], @attrFit, f.[Val], CAST(NULL AS NVARCHAR(200)), f.[Sort]
        FROM @apparel sc CROSS JOIN @fits f
), FootwearOptions AS (
    SELECT sc.[SubCategoryId], @attrSize AS [AttributeId], s.[Val] AS [OptionValue], CAST(NULL AS NVARCHAR(200)) AS [Meta], s.[Sort] AS [SortOrder]
        FROM @footwear sc CROSS JOIN @shoeSizes s
    UNION ALL
    SELECT sc.[SubCategoryId], @attrColor, c.[Val], c.[Meta], c.[Sort]
        FROM @footwear sc CROSS JOIN @colors c
    UNION ALL
    SELECT sc.[SubCategoryId], @attrMaterial, m.[Val], CAST(NULL AS NVARCHAR(200)), m.[Sort]
        FROM @footwear sc CROSS JOIN @materials m
), AllOptions AS (
    SELECT * FROM ApparelOptions
    UNION ALL
    SELECT * FROM FootwearOptions
)
INSERT INTO [dbo].[SubCategoryVariantOptions]
    ([SubCategoryId], [AttributeId], [OptionValue], [OptionMetadata], [SortOrder])
SELECT a.[SubCategoryId], a.[AttributeId], a.[OptionValue], a.[Meta], a.[SortOrder]
FROM AllOptions a
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[SubCategoryVariantOptions] existing
    WHERE existing.[SubCategoryId] = a.[SubCategoryId]
      AND existing.[AttributeId]   = a.[AttributeId]
      AND existing.[OptionValue]   = a.[OptionValue]
);
GO

-- ─── Extra size scales: shoe-EU (36–46) + toy (Small/Medium/Large) ───
-- Targets subcategories whose SizeScale was set by Seed_SubCategoryFormRules.sql.
-- Idempotent via NOT EXISTS.

DECLARE @attrSizeId INT = (SELECT [AttributeId] FROM [dbo].[VariantAttributes] WHERE [AttributeKey] = N'size');
IF @attrSizeId IS NULL RETURN;

DECLARE @euSizes TABLE ([Val] NVARCHAR(100) NOT NULL, [Sort] INT NOT NULL);
INSERT INTO @euSizes VALUES
    (N'36', 1), (N'37', 2), (N'38', 3), (N'39', 4), (N'40', 5),
    (N'41', 6), (N'42', 7), (N'43', 8), (N'44', 9), (N'45', 10), (N'46', 11);

DECLARE @toySizes TABLE ([Val] NVARCHAR(100) NOT NULL, [Sort] INT NOT NULL);
INSERT INTO @toySizes VALUES
    (N'Small', 1), (N'Medium', 2), (N'Large', 3);

-- Shoe-EU
INSERT INTO [dbo].[SubCategoryVariantOptions]
    ([SubCategoryId], [AttributeId], [OptionValue], [OptionMetadata], [SortOrder])
SELECT sc.[SubCategoryId], @attrSizeId, s.[Val], NULL, s.[Sort]
FROM [dbo].[SubCategories] sc
CROSS JOIN @euSizes s
WHERE sc.[SizeScale] = N'shoe-eu'
  AND sc.[IsDeleted] = 0
  AND NOT EXISTS (
      SELECT 1 FROM [dbo].[SubCategoryVariantOptions] existing
      WHERE existing.[SubCategoryId] = sc.[SubCategoryId]
        AND existing.[AttributeId]   = @attrSizeId
        AND existing.[OptionValue]   = s.[Val]
  );

-- Toy
INSERT INTO [dbo].[SubCategoryVariantOptions]
    ([SubCategoryId], [AttributeId], [OptionValue], [OptionMetadata], [SortOrder])
SELECT sc.[SubCategoryId], @attrSizeId, s.[Val], NULL, s.[Sort]
FROM [dbo].[SubCategories] sc
CROSS JOIN @toySizes s
WHERE sc.[SizeScale] = N'toy'
  AND sc.[IsDeleted] = 0
  AND NOT EXISTS (
      SELECT 1 FROM [dbo].[SubCategoryVariantOptions] existing
      WHERE existing.[SubCategoryId] = sc.[SubCategoryId]
        AND existing.[AttributeId]   = @attrSizeId
        AND existing.[OptionValue]   = s.[Val]
  );
GO
