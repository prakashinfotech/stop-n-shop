CREATE VIEW [dbo].[vw_CartDetails]
AS
SELECT
    c.[CartId],
    c.[UserId],
    c.[Quantity],
    c.[SavedForLater],
    c.[AddedAt],

    -- Product
    p.[ProductId],
    p.[ProductName],
    p.[SlugUrl]           AS [ProductSlug],
    p.[MRP],
    p.[SellingPrice],
    p.[GstRate],
    p.[IsCODAvailable],
    p.[IsReturnable],
    p.[ApprovalStatus]    AS [ProductApprovalStatus],
    p.[IsActive]          AS [ProductIsActive],

    -- Variant
    pv.[VariantId],
    pv.[Color],
    pv.[ColorHexCode],
    pv.[Size],
    pv.[Material],
    pv.[VariantSku],
    pv.[AdditionalPrice],
    pv.[StockQuantity],
    pv.[LowStockThreshold],
    (p.[SellingPrice] + pv.[AdditionalPrice]) AS [FinalPrice],

    -- Brand
    b.[BrandId],
    b.[BrandName],

    -- Primary image
    pi_.[ImageUrl]        AS [PrimaryImageUrl]

FROM [dbo].[Cart]               c
INNER JOIN [dbo].[Products]        p   ON p.[ProductId]  = c.[ProductId]  AND p.[IsDeleted]  = 0
INNER JOIN [dbo].[ProductVariants] pv  ON pv.[VariantId] = c.[VariantId]  AND pv.[IsDeleted] = 0
INNER JOIN [dbo].[Brands]          b   ON b.[BrandId]    = p.[BrandId]    AND b.[IsDeleted]  = 0
LEFT  JOIN [dbo].[ProductImages]   pi_ ON pi_.[ProductId] = p.[ProductId] AND pi_.[IsPrimary] = 1
                                       AND pi_.[IsDeleted] = 0

WHERE c.[IsDeleted] = 0;
GO
