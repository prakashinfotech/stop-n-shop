-- Move @Quantity units of a variant from @FromWarehouseId to @ToWarehouseId.
-- Step 1 of 2: decrements From side, marks transfer InTransit. Receive completes it.
CREATE PROCEDURE [dbo].[usp_Inventory_Transfer_Initiate]
    @VariantId       INT,
    @FromWarehouseId INT,
    @ToWarehouseId   INT,
    @Quantity        INT,
    @Reason          NVARCHAR(500) = NULL,
    @InitiatedBy     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Quantity <= 0
            THROW 50330, N'Quantity must be positive.', 1;
        IF @FromWarehouseId = @ToWarehouseId
            THROW 50331, N'From and To warehouses must differ.', 1;

        BEGIN TRANSACTION;

        DECLARE @OnHand INT, @Reserved INT;

        SELECT @OnHand = [OnHand], @Reserved = [Reserved]
        FROM [dbo].[Stock] WITH (UPDLOCK, HOLDLOCK)
        WHERE [VariantId] = @VariantId AND [WarehouseId] = @FromWarehouseId;

        IF @OnHand IS NULL
            THROW 50332, N'Source warehouse has no stock for this variant.', 1;

        IF (@OnHand - @Reserved) < @Quantity
            THROW 50333, N'Insufficient available stock at source warehouse.', 1;

        UPDATE [dbo].[Stock]
        SET    [OnHand]    = [OnHand] - @Quantity,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @InitiatedBy
        WHERE  [VariantId] = @VariantId AND [WarehouseId] = @FromWarehouseId;

        INSERT INTO [dbo].[StockTransfers]
            ([VariantId], [FromWarehouseId], [ToWarehouseId], [Quantity], [Status], [Reason], [InitiatedBy])
        VALUES
            (@VariantId, @FromWarehouseId, @ToWarehouseId, @Quantity, 1, @Reason, @InitiatedBy);

        DECLARE @TransferId INT = SCOPE_IDENTITY();

        INSERT INTO [dbo].[StockMovements]
            ([VariantId], [WarehouseId], [MovementType], [QuantityDelta], [ReservedDelta],
             [Reason], [ReferenceType], [ReferenceId], [ChangedBy])
        VALUES
            (@VariantId, @FromWarehouseId, 7, -@Quantity, 0,
             ISNULL(@Reason, N'TransferOut'), N'Transfer', @TransferId, @InitiatedBy);

        -- Refresh denormalized cache (totals don't change yet — units in-flight)
        UPDATE pv
        SET    [StockQuantity] = ISNULL(t.[Total], 0),
               [UpdatedAt]     = GETUTCDATE()
        FROM   [dbo].[ProductVariants] pv
        OUTER APPLY (SELECT SUM([OnHand]) AS [Total] FROM [dbo].[Stock] WHERE [VariantId] = @VariantId) t
        WHERE  pv.[VariantId] = @VariantId;

        COMMIT TRANSACTION;
        SELECT @TransferId AS [TransferId];

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
