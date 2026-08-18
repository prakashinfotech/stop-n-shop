-- Step 2 of 2: marks the transfer Received and credits the destination warehouse.
CREATE PROCEDURE [dbo].[usp_Inventory_Transfer_Receive]
    @TransferId  INT,
    @ReceivedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @VariantId INT, @ToWh INT, @Qty INT, @Status TINYINT;

        SELECT @VariantId = [VariantId], @ToWh = [ToWarehouseId],
               @Qty = [Quantity], @Status = [Status]
        FROM [dbo].[StockTransfers] WITH (UPDLOCK, HOLDLOCK)
        WHERE [TransferId] = @TransferId;

        IF @VariantId IS NULL
            THROW 50340, N'Transfer not found.', 1;

        IF @Status <> 1
            THROW 50341, N'Transfer is not in transit.', 1;

        -- Lock or create destination stock row
        DECLARE @StockId INT;
        SELECT @StockId = [StockId]
        FROM [dbo].[Stock] WITH (UPDLOCK, HOLDLOCK)
        WHERE [VariantId] = @VariantId AND [WarehouseId] = @ToWh;

        IF @StockId IS NULL
        BEGIN
            INSERT INTO [dbo].[Stock] ([VariantId], [WarehouseId], [OnHand], [Reserved], [UpdatedBy])
            VALUES (@VariantId, @ToWh, @Qty, 0, @ReceivedBy);
        END
        ELSE
        BEGIN
            UPDATE [dbo].[Stock]
            SET    [OnHand]    = [OnHand] + @Qty,
                   [UpdatedAt] = GETUTCDATE(),
                   [UpdatedBy] = @ReceivedBy
            WHERE  [StockId] = @StockId;
        END;

        UPDATE [dbo].[StockTransfers]
        SET    [Status]     = 2,
               [ReceivedBy] = @ReceivedBy,
               [ReceivedAt] = GETUTCDATE()
        WHERE  [TransferId] = @TransferId;

        INSERT INTO [dbo].[StockMovements]
            ([VariantId], [WarehouseId], [MovementType], [QuantityDelta], [ReservedDelta],
             [Reason], [ReferenceType], [ReferenceId], [ChangedBy])
        VALUES
            (@VariantId, @ToWh, 8, @Qty, 0,
             N'TransferIn', N'Transfer', @TransferId, @ReceivedBy);

        UPDATE pv
        SET    [StockQuantity] = ISNULL(t.[Total], 0),
               [UpdatedAt]     = GETUTCDATE()
        FROM   [dbo].[ProductVariants] pv
        OUTER APPLY (SELECT SUM([OnHand]) AS [Total] FROM [dbo].[Stock] WHERE [VariantId] = @VariantId) t
        WHERE  pv.[VariantId] = @VariantId;

        COMMIT TRANSACTION;
        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
