CREATE PROCEDURE [dbo].[usp_Seller_ProductVariant_Add]
    @ProductId         INT,
    @Color             NVARCHAR(100)  = NULL,
    @Size              NVARCHAR(50)   = NULL,
    @VariantSku        NVARCHAR(150),
    @StockQuantity     INT            = 0,
    @LowStockThreshold INT            = 5,
    @AdditionalPrice   DECIMAL(18,2)  = 0,
    @CreatedBy         INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50080, N'Product not found.', 1;

        INSERT INTO [dbo].[ProductVariants]
            ([ProductId], [Color], [Size], [VariantSku],
             [StockQuantity], [LowStockThreshold], [AdditionalPrice],
             [CreatedAt], [CreatedBy], [IsActive], [IsDeleted])
        VALUES
            (@ProductId, @Color, @Size, @VariantSku,
             @StockQuantity, @LowStockThreshold, @AdditionalPrice,
             GETUTCDATE(), @CreatedBy, 1, 0);

        SELECT SCOPE_IDENTITY() AS [VariantId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
