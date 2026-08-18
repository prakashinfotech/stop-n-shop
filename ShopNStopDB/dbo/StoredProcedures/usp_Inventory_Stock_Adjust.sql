-- Manual stock adjustment. Adds @QuantityDelta (signed) to OnHand for (VariantId, WarehouseId).
-- Emits a StockMovement row and refreshes the ProductVariants.StockQuantity cache.
CREATE PROCEDURE [dbo].[usp_Inventory_Stock_Adjust]
    @VariantId     INT,
    @WarehouseId   INT,
    @QuantityDelta INT,
    @Reason        NVARCHAR(500) = NULL,
    @MovementType  TINYINT       = 2,   -- default 2 = Adjustment
    @ReferenceType NVARCHAR(50)  = NULL,
    @ReferenceId   BIGINT        = NULL,
    @ChangedBy     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @QuantityDelta = 0
            THROW 50300, N'QuantityDelta must be non-zero.', 1;

        IF NOT EXISTS (SELECT 1 FROM [dbo].[ProductVariants] WHERE [VariantId] = @VariantId AND [IsDeleted] = 0)
            THROW 50301, N'Variant not found.', 1;

        IF NOT EXISTS (SELECT 1 FROM [dbo].[Warehouses] WHERE [WarehouseId] = @WarehouseId AND [IsDeleted] = 0)
            THROW 50302, N'Warehouse not found.', 1;

        BEGIN TRANSACTION;

        -- Lock or create the Stock row
        DECLARE @StockId INT, @OnHand INT, @Reserved INT;

        SELECT @StockId = [StockId], @OnHand = [OnHand], @Reserved = [Reserved]
        FROM [dbo].[Stock] WITH (UPDLOCK, HOLDLOCK)
        WHERE [VariantId] = @VariantId AND [WarehouseId] = @WarehouseId;

        IF @StockId IS NULL
        BEGIN
            INSERT INTO [dbo].[Stock] ([VariantId], [WarehouseId], [OnHand], [Reserved], [UpdatedBy])
            VALUES (@VariantId, @WarehouseId, 0, 0, @ChangedBy);
            SET @StockId = SCOPE_IDENTITY();
            SET @OnHand = 0;
            SET @Reserved = 0;
        END;

        DECLARE @NewOnHand INT = @OnHand + @QuantityDelta;

        IF @NewOnHand < 0
            THROW 50303, N'Adjustment would drive OnHand negative.', 1;
        IF @NewOnHand < @Reserved
            THROW 50304, N'Adjustment would drop OnHand below Reserved holds.', 1;

        UPDATE [dbo].[Stock]
        SET    [OnHand]    = @NewOnHand,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @ChangedBy
        WHERE  [StockId] = @StockId;

        INSERT INTO [dbo].[StockMovements]
            ([VariantId], [WarehouseId], [MovementType], [QuantityDelta], [ReservedDelta],
             [Reason], [ReferenceType], [ReferenceId], [ChangedBy])
        VALUES
            (@VariantId, @WarehouseId, @MovementType, @QuantityDelta, 0,
             @Reason, @ReferenceType, @ReferenceId, @ChangedBy);

        -- Refresh denormalized cache on ProductVariants
        UPDATE pv
        SET    [StockQuantity] = ISNULL(t.[Total], 0),
               [UpdatedAt]     = GETUTCDATE()
        FROM   [dbo].[ProductVariants] pv
        OUTER APPLY (
            SELECT SUM([OnHand]) AS [Total]
            FROM   [dbo].[Stock]
            WHERE  [VariantId] = @VariantId
        ) t
        WHERE  pv.[VariantId] = @VariantId;

        COMMIT TRANSACTION;

        SELECT @StockId AS [StockId], @NewOnHand AS [OnHand], @Reserved AS [Reserved];

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
