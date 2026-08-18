CREATE PROCEDURE [dbo].[usp_Commerce_Cart_AddItem]
    @UserId    INT,
    @ProductId INT,
    @VariantId INT,
    @Quantity  INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Validate product is active and approved
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [ProductId] = @ProductId AND [IsDeleted] = 0 AND [IsActive] = 1 AND [ApprovalStatus] = 2
        )
            THROW 50040, N'Product is not available.', 1;

        -- Validate variant
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[ProductVariants]
            WHERE [VariantId] = @VariantId AND [ProductId] = @ProductId AND [IsDeleted] = 0 AND [IsActive] = 1
        )
            THROW 50041, N'Product variant is not available.', 1;

        -- Check stock
        DECLARE @Stock INT;
        SELECT @Stock = [StockQuantity] FROM [dbo].[ProductVariants] WHERE [VariantId] = @VariantId;

        IF @Stock < @Quantity
            THROW 50042, N'Insufficient stock.', 1;

        -- Upsert cart: if same user+variant already in cart, update quantity
        IF EXISTS (SELECT 1 FROM [dbo].[Cart] WHERE [UserId] = @UserId AND [VariantId] = @VariantId AND [IsDeleted] = 0)
        BEGIN
            UPDATE [dbo].[Cart]
            SET    [Quantity]    = [Quantity] + @Quantity,
                   [SavedForLater] = 0,
                   [UpdatedAt]  = GETUTCDATE(),
                   [UpdatedBy]  = @UserId
            WHERE  [UserId]    = @UserId
              AND  [VariantId] = @VariantId
              AND  [IsDeleted] = 0;
        END
        ELSE
        BEGIN
            INSERT INTO [dbo].[Cart]
                ([UserId], [ProductId], [VariantId], [Quantity], [CreatedBy], [UpdatedBy])
            VALUES
                (@UserId, @ProductId, @VariantId, @Quantity, @UserId, @UserId);
        END;

        EXEC [dbo].[usp_Commerce_Cart_GetByUser] @UserId = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
