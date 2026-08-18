CREATE PROCEDURE [dbo].[usp_Commerce_Cart_GetByUser]
    @UserId        INT,
    @SavedForLater BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            c.[CartId],
            c.[UserId],
            c.[Quantity],
            c.[SavedForLater],

            p.[ProductId],
            p.[ProductName],
            p.[SlugUrl]        AS [ProductSlug],
            p.[MRP],
            p.[SellingPrice],
            p.[GstRate],
            p.[IsCODAvailable],
            p.[IsReturnable],
            p.[ApprovalStatus] AS [ProductApprovalStatus],
            p.[IsActive]       AS [ProductIsActive],

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
            ((p.[SellingPrice] + pv.[AdditionalPrice]) * c.[Quantity]) AS [LineTotal],

            b.[BrandId],
            b.[BrandName],

            pi_.[ImageUrl]     AS [PrimaryImageUrl]

        FROM [dbo].[Cart]              c
        INNER JOIN [dbo].[Products]        p   ON p.[ProductId]  = c.[ProductId]
        INNER JOIN [dbo].[ProductVariants] pv  ON pv.[VariantId] = c.[VariantId]
        INNER JOIN [dbo].[Brands]          b   ON b.[BrandId]    = p.[BrandId]
        LEFT  JOIN [dbo].[ProductImages]   pi_ ON pi_.[ProductId] = p.[ProductId]
                                               AND pi_.[IsPrimary] = 1
                                               AND pi_.[IsDeleted] = 0
        WHERE c.[UserId]       = @UserId
          AND c.[IsDeleted]    = 0
          AND c.[SavedForLater] = @SavedForLater
        ORDER BY c.[AddedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
