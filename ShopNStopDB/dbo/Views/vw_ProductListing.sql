CREATE VIEW [dbo].[vw_ProductListing]
AS
SELECT
    p.[ProductId],
    p.[ProductName],
    p.[SlugUrl],
    p.[ShortDescription],
    p.[MRP],
    p.[SellingPrice],
    p.[GstRate],
    p.[Sku],
    p.[IsFeatured],
    p.[SortOrder],
    p.[ApprovalStatus],
    p.[IsActive],
    p.[IsDeleted],
    p.[PublishedAt],

    -- Brand
    b.[BrandId],
    b.[BrandName],
    b.[SlugUrl]          AS [BrandSlug],
    b.[LogoUrl]          AS [BrandLogoUrl],

    -- Category / SubCategory
    c.[CategoryId],
    c.[CategoryName],
    c.[SlugUrl]          AS [CategorySlug],
    sc.[SubCategoryId],
    sc.[SubCategoryName],
    sc.[SlugUrl]         AS [SubCategorySlug],

    -- Gender
    gt.[GenderTypeId],
    gt.[Name]            AS [GenderType],

    -- Seller
    s.[SellerId],
    s.[BusinessName]     AS [SellerName],

    -- Primary image
    pi_.[ImageUrl]       AS [PrimaryImageUrl],
    pi_.[AltText]        AS [PrimaryImageAlt],

    -- Stock (minimum across all active variants)
    ISNULL(vs.[MinStock], 0) AS [MinStockQuantity],
    ISNULL(vs.[VariantCount], 0) AS [VariantCount]

FROM [dbo].[Products]               p
INNER JOIN [dbo].[Brands]           b   ON b.[BrandId]       = p.[BrandId]       AND b.[IsDeleted] = 0
INNER JOIN [dbo].[Categories]       c   ON c.[CategoryId]    = p.[CategoryId]    AND c.[IsDeleted] = 0
INNER JOIN [dbo].[SubCategories]    sc  ON sc.[SubCategoryId] = p.[SubCategoryId] AND sc.[IsDeleted] = 0
INNER JOIN [dbo].[Sellers]          s   ON s.[SellerId]       = p.[SellerId]      AND s.[IsDeleted] = 0
LEFT  JOIN [dbo].[GenderTypes]      gt  ON gt.[GenderTypeId]  = p.[GenderTypeId]
LEFT  JOIN [dbo].[ProductImages]    pi_ ON pi_.[ProductId]    = p.[ProductId]
                                       AND pi_.[IsPrimary]    = 1
                                       AND pi_.[IsDeleted]    = 0
LEFT  JOIN (
    SELECT
        [ProductId],
        MIN([StockQuantity])   AS [MinStock],
        COUNT([VariantId])     AS [VariantCount]
    FROM [dbo].[ProductVariants]
    WHERE [IsDeleted] = 0 AND [IsActive] = 1
    GROUP BY [ProductId]
) vs ON vs.[ProductId] = p.[ProductId]

WHERE p.[IsDeleted] = 0;
GO
