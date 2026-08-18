CREATE PROCEDURE [dbo].[usp_Commerce_Cart_UpdateQuantity]
    @CartId   INT,
    @UserId   INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Quantity < 1
            THROW 50043, N'Quantity must be at least 1.', 1;

        DECLARE @VariantId INT;
        SELECT @VariantId = [VariantId]
        FROM [dbo].[Cart]
        WHERE [CartId] = @CartId AND [UserId] = @UserId AND [IsDeleted] = 0;

        IF @VariantId IS NULL
            THROW 50044, N'Cart item not found.', 1;

        DECLARE @Stock INT;
        SELECT @Stock = [StockQuantity] FROM [dbo].[ProductVariants] WHERE [VariantId] = @VariantId;

        IF @Stock < @Quantity
            THROW 50045, N'Insufficient stock.', 1;

        UPDATE [dbo].[Cart]
        SET    [Quantity]  = @Quantity,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [CartId] = @CartId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
