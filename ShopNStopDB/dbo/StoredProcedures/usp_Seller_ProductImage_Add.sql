CREATE PROCEDURE [dbo].[usp_Seller_ProductImage_Add]
    @ProductId  INT,
    @ImageUrl   NVARCHAR(500),
    @IsPrimary  BIT = 0,
    @SortOrder  INT = 0,
    @ImageSlot  NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50200, N'Product not found.', 1;

        -- Demote any existing primary if this one is being set primary.
        IF @IsPrimary = 1
        BEGIN
            UPDATE [dbo].[ProductImages]
               SET [IsPrimary] = 0,
                   [UpdatedAt] = GETUTCDATE()
             WHERE [ProductId] = @ProductId
               AND [IsPrimary] = 1
               AND [IsDeleted] = 0;
        END;

        INSERT INTO [dbo].[ProductImages]
            ([ProductId], [ImageUrl], [IsPrimary], [SortOrder], [ImageSlot])
        VALUES
            (@ProductId, @ImageUrl, @IsPrimary, @SortOrder, @ImageSlot);

        SELECT CAST(SCOPE_IDENTITY() AS INT) AS [ImageId];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
