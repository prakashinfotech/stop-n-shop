CREATE PROCEDURE [dbo].[usp_Seller_ProductVariant_DeleteByProduct]
    @ProductId INT,
    @SellerId  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [ProductId] = @ProductId AND [SellerId] = @SellerId AND [IsDeleted] = 0
        )
            THROW 50110, N'Product not found for this seller.', 1;

        UPDATE [dbo].[ProductVariants]
        SET    [IsDeleted] = 1,
               [IsActive]  = 0,
               [UpdatedAt] = GETUTCDATE()
        WHERE  [ProductId] = @ProductId
          AND  [IsDeleted] = 0;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
