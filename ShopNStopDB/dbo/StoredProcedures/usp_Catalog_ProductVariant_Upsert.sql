CREATE PROCEDURE [dbo].[usp_Catalog_ProductVariant_Upsert]
    @ProductId      INT,
    @VariantId      INT            = NULL,  -- NULL = insert
    @Size           NVARCHAR(50)   = NULL,
    @Color          NVARCHAR(50)   = NULL,
    @Material       NVARCHAR(100)  = NULL,
    @StockQuantity  INT,
    @AdditionalPrice DECIMAL(18,2) = 0.00,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50070, N'Product not found.', 1;

        -- Resolve the default platform warehouse (WH-MUM-01) so every new variant
        -- has a Stock row to track against. Fall back to the first non-deleted
        -- warehouse if Mumbai DC is absent.
        DECLARE @DefaultWarehouseId INT = (
            SELECT TOP 1 [WarehouseId]
            FROM [dbo].[Warehouses]
            WHERE [Code] = N'WH-MUM-01' AND [IsDeleted] = 0
        );

        IF @DefaultWarehouseId IS NULL
            SET @DefaultWarehouseId = (
                SELECT TOP 1 [WarehouseId]
                FROM [dbo].[Warehouses]
                WHERE [IsDeleted] = 0 AND [IsActive] = 1
                ORDER BY [WarehouseId]
            );

        DECLARE @NewVariantId INT;

        IF @VariantId IS NULL
        BEGIN
            INSERT INTO [dbo].[ProductVariants]
                ([ProductId], [Size], [Color], [Material], [StockQuantity],
                 [AdditionalPrice], [CreatedAt], [CreatedBy], [IsDeleted])
            VALUES
                (@ProductId, @Size, @Color, @Material, @StockQuantity,
                 @AdditionalPrice, GETUTCDATE(), @UpdatedBy, 0);

            SET @NewVariantId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM [dbo].[ProductVariants]
                WHERE [VariantId] = @VariantId AND [ProductId] = @ProductId AND [IsDeleted] = 0
            )
                THROW 50071, N'Variant not found for this product.', 1;

            UPDATE [dbo].[ProductVariants]
            SET    [Size]            = @Size,
                   [Color]           = @Color,
                   [Material]        = @Material,
                   [StockQuantity]   = @StockQuantity,
                   [AdditionalPrice] = @AdditionalPrice,
                   [UpdatedAt]       = GETUTCDATE(),
                   [UpdatedBy]       = @UpdatedBy
            WHERE  [VariantId] = @VariantId;

            SET @NewVariantId = @VariantId;
        END

        -- Sync Stock at the default warehouse so the inventory matrix reflects
        -- the StockQuantity the seller entered. Reserved is preserved on updates.
        -- Skipped only if there are no warehouses configured yet (cold-start
        -- environments) — the patch-driven Stock init will fill those in later.
        IF @DefaultWarehouseId IS NOT NULL
        BEGIN
            MERGE [dbo].[Stock] AS tgt
            USING (SELECT @NewVariantId AS [VariantId], @DefaultWarehouseId AS [WarehouseId]) AS src
            ON tgt.[VariantId] = src.[VariantId] AND tgt.[WarehouseId] = src.[WarehouseId]
            WHEN MATCHED THEN UPDATE SET
                tgt.[OnHand]    = @StockQuantity,
                tgt.[UpdatedAt] = GETUTCDATE(),
                tgt.[UpdatedBy] = @UpdatedBy
            WHEN NOT MATCHED THEN INSERT
                ([VariantId], [WarehouseId], [OnHand], [Reserved], [UpdatedBy])
            VALUES
                (src.[VariantId], src.[WarehouseId], @StockQuantity, 0, @UpdatedBy);
        END

        SELECT @NewVariantId AS [VariantId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
