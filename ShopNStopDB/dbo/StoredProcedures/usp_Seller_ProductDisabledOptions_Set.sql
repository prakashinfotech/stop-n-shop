CREATE PROCEDURE [dbo].[usp_Seller_ProductDisabledOptions_Set]
    @ProductId       INT,
    @SellerId        INT,
    @DisabledJson    NVARCHAR(MAX),    -- [{"optionId":12},{"optionId":15}]
    @CurrentUserId   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Authorize: seller can only touch their own product
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [ProductId] = @ProductId
              AND [SellerId]  = @SellerId
              AND [IsDeleted] = 0
        )
            THROW 50221, 'Product not found or not owned by seller.', 1;

        BEGIN TRANSACTION;

        DECLARE @Incoming TABLE ([OptionId] INT NOT NULL PRIMARY KEY);
        INSERT INTO @Incoming ([OptionId])
        SELECT DISTINCT [OptionId]
        FROM OPENJSON(@DisabledJson)
        WITH ([OptionId] INT '$.optionId');

        -- Delete flags no longer in the incoming list
        DELETE d
        FROM [dbo].[ProductDisabledVariantOptions] d
        WHERE d.[ProductId] = @ProductId
          AND d.[OptionId] NOT IN (SELECT [OptionId] FROM @Incoming);

        -- Insert new flags
        INSERT INTO [dbo].[ProductDisabledVariantOptions] ([ProductId], [OptionId], [CreatedBy])
        SELECT @ProductId, i.[OptionId], @CurrentUserId
        FROM @Incoming i
        WHERE NOT EXISTS (
            SELECT 1 FROM [dbo].[ProductDisabledVariantOptions] existing
            WHERE existing.[ProductId] = @ProductId
              AND existing.[OptionId]  = i.[OptionId]
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
