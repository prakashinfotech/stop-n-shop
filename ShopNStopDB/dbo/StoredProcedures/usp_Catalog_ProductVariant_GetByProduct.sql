CREATE PROCEDURE [dbo].[usp_Catalog_ProductVariant_GetByProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            pv.[VariantId],
            pv.[ProductId],
            pv.[Color],
            pv.[ColorHexCode],
            pv.[Size],
            pv.[Material],
            pv.[Pattern],
            pv.[FitType],
            pv.[VariantSku],
            pv.[AdditionalPrice],
            pv.[StockQuantity],
            pv.[LowStockThreshold],
            pv.[Weight],
            pv.[Dimensions],
            pv.[BarCode],
            pv.[IsActive],
            (p.[SellingPrice] + pv.[AdditionalPrice]) AS [FinalPrice]
        FROM [dbo].[ProductVariants] pv
        INNER JOIN [dbo].[Products] p ON p.[ProductId] = pv.[ProductId]
        WHERE pv.[ProductId] = @ProductId
          AND pv.[IsDeleted] = 0
        ORDER BY pv.[Size] ASC, pv.[Color] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
