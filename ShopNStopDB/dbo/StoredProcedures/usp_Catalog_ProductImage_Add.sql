CREATE PROCEDURE [dbo].[usp_Catalog_ProductImage_Add]
    @ProductId  INT,
    @ImageUrl   NVARCHAR(500),
    @AltText    NVARCHAR(200) = NULL,
    @IsPrimary  BIT           = 0,
    @SortOrder  INT           = 0,
    @ImageSlot  NVARCHAR(20)  = NULL,
    @CreatedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50080, N'Product not found.', 1;

        BEGIN TRANSACTION;

            IF @IsPrimary = 1
                UPDATE [dbo].[ProductImages]
                SET    [IsPrimary] = 0,
                       [UpdatedAt] = GETUTCDATE(),
                       [UpdatedBy] = @CreatedBy
                WHERE  [ProductId] = @ProductId AND [IsDeleted] = 0;

            INSERT INTO [dbo].[ProductImages]
                ([ProductId], [ImageUrl], [AltText], [IsPrimary], [SortOrder], [ImageSlot],
                 [CreatedAt], [CreatedBy], [IsDeleted])
            VALUES
                (@ProductId, @ImageUrl, @AltText, @IsPrimary, @SortOrder, @ImageSlot,
                 GETUTCDATE(), @CreatedBy, 0);

        COMMIT TRANSACTION;

        SELECT SCOPE_IDENTITY() AS [ProductImageId];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
