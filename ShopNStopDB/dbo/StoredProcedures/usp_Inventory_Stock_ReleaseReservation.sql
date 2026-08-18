-- Releases an Active reservation (or marks it Committed when @CommitToOrderId provided).
-- For Commit: also decrements Stock.OnHand by the reserved quantity (the actual ship/decrement).
CREATE PROCEDURE [dbo].[usp_Inventory_Stock_ReleaseReservation]
    @ReservationId    BIGINT,
    @CommitToOrderId  INT = NULL,   -- when supplied: commit (decrement OnHand) instead of release
    @Reason           NVARCHAR(500) = NULL,
    @ChangedBy        INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @VariantId INT, @WarehouseId INT, @Quantity INT, @Status TINYINT;

        SELECT @VariantId = [VariantId], @WarehouseId = [WarehouseId],
               @Quantity = [Quantity], @Status = [Status]
        FROM   [dbo].[StockReservations] WITH (UPDLOCK, HOLDLOCK)
        WHERE  [ReservationId] = @ReservationId;

        IF @VariantId IS NULL
            THROW 50320, N'Reservation not found.', 1;

        IF @Status <> 1   -- already terminal
        BEGIN
            COMMIT TRANSACTION;
            SELECT @Status AS [Status], 0 AS [Changed];
            RETURN;
        END;

        -- Lock the matching Stock row
        DECLARE @OnHand INT, @Reserved INT;
        SELECT @OnHand = [OnHand], @Reserved = [Reserved]
        FROM   [dbo].[Stock] WITH (UPDLOCK, HOLDLOCK)
        WHERE  [VariantId] = @VariantId AND [WarehouseId] = @WarehouseId;

        IF @CommitToOrderId IS NULL
        BEGIN
            -- Release path: -Reserved
            UPDATE [dbo].[Stock]
            SET    [Reserved]  = [Reserved] - @Quantity,
                   [UpdatedAt] = GETUTCDATE(),
                   [UpdatedBy] = @ChangedBy
            WHERE  [VariantId] = @VariantId AND [WarehouseId] = @WarehouseId;

            UPDATE [dbo].[StockReservations]
            SET    [Status]     = 3,
                   [ReleasedAt] = GETUTCDATE()
            WHERE  [ReservationId] = @ReservationId;

            INSERT INTO [dbo].[StockMovements]
                ([VariantId], [WarehouseId], [MovementType], [QuantityDelta], [ReservedDelta],
                 [Reason], [ReferenceType], [ReferenceId], [ChangedBy])
            VALUES
                (@VariantId, @WarehouseId, 4, 0, -@Quantity,
                 ISNULL(@Reason, N'Release'), N'Reservation', @ReservationId, @ChangedBy);
        END
        ELSE
        BEGIN
            -- Commit path: -Reserved AND -OnHand (the actual decrement)
            UPDATE [dbo].[Stock]
            SET    [OnHand]    = [OnHand]   - @Quantity,
                   [Reserved]  = [Reserved] - @Quantity,
                   [UpdatedAt] = GETUTCDATE(),
                   [UpdatedBy] = @ChangedBy
            WHERE  [VariantId] = @VariantId AND [WarehouseId] = @WarehouseId;

            UPDATE [dbo].[StockReservations]
            SET    [Status]     = 2,
                   [OrderId]    = @CommitToOrderId,
                   [ReleasedAt] = GETUTCDATE()
            WHERE  [ReservationId] = @ReservationId;

            INSERT INTO [dbo].[StockMovements]
                ([VariantId], [WarehouseId], [MovementType], [QuantityDelta], [ReservedDelta],
                 [Reason], [ReferenceType], [ReferenceId], [ChangedBy])
            VALUES
                (@VariantId, @WarehouseId, 5, -@Quantity, -@Quantity,
                 ISNULL(@Reason, N'Ship'), N'Order', @CommitToOrderId, @ChangedBy);

            -- Refresh denormalized cache
            UPDATE pv
            SET    [StockQuantity] = ISNULL(t.[Total], 0),
                   [UpdatedAt]     = GETUTCDATE()
            FROM   [dbo].[ProductVariants] pv
            OUTER APPLY (
                SELECT SUM([OnHand]) AS [Total] FROM [dbo].[Stock] WHERE [VariantId] = @VariantId
            ) t
            WHERE  pv.[VariantId] = @VariantId;
        END;

        COMMIT TRANSACTION;
        SELECT (CASE WHEN @CommitToOrderId IS NULL THEN 3 ELSE 2 END) AS [Status], 1 AS [Changed];

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
