/*
 * 2026-05-26 — Live-DB patch: refresh usp_Catalog_ProductVariant_Upsert
 *
 * The SSDT source file at ShopNStopDB/dbo/StoredProcedures/usp_Catalog_ProductVariant_Upsert.sql
 * was extended to also write the Stock row when a seller upserts a variant.
 * That source uses `CREATE PROCEDURE` per the SSDT convention. Since the Docker
 * DB doesn't run dacpac publish (post-deploy `:r` lines are commented out), we
 * apply the same body here via DROP + CREATE so the running container picks it
 * up. The SSDT file stays as-is.
 *
 * Idempotent: drops the existing SP first if present.
 *
 * Apply:
 *   docker cp db/patches/2026_05_26_variant_upsert_sp.sql stopnshop-db:/tmp/sp.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C -d ShopNShop_db -b -I -i /tmp/sp.sql
 */

SET NOCOUNT ON;

IF OBJECT_ID(N'[dbo].[usp_Catalog_ProductVariant_Upsert]', N'P') IS NOT NULL
BEGIN
    PRINT '[patch] Dropping existing usp_Catalog_ProductVariant_Upsert...';
    DROP PROCEDURE [dbo].[usp_Catalog_ProductVariant_Upsert];
END
GO

PRINT '[patch] Creating usp_Catalog_ProductVariant_Upsert (with Stock sync)...';
GO

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

        -- Resolve default platform warehouse so every new variant has a Stock row.
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

PRINT '[patch] Done.';
GO
