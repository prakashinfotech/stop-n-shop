-- Atomically reserve @Quantity units of a variant at a warehouse.
-- Picks the row under UPDLOCK,HOLDLOCK; fails fast if insufficient availability.
-- Returns the new ReservationId. ExpiresAt is computed from @TtlMinutes.
CREATE PROCEDURE [dbo].[usp_Inventory_Stock_Reserve]
    @VariantId    INT,
    @WarehouseId  INT,
    @Quantity     INT,
    @UserId       INT          = NULL,
    @CartLineId   INT          = NULL,
    @TtlMinutes   INT          = 15,
    @ChangedBy    INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Quantity <= 0
            THROW 50310, N'Quantity must be positive.', 1;
        IF @TtlMinutes <= 0
            THROW 50311, N'TtlMinutes must be positive.', 1;

        BEGIN TRANSACTION;

        DECLARE @OnHand INT, @Reserved INT;

        SELECT @OnHand = [OnHand], @Reserved = [Reserved]
        FROM [dbo].[Stock] WITH (UPDLOCK, HOLDLOCK)
        WHERE [VariantId] = @VariantId AND [WarehouseId] = @WarehouseId;

        IF @OnHand IS NULL
            THROW 50312, N'No stock record exists for the given variant/warehouse.', 1;

        IF (@OnHand - @Reserved) < @Quantity
            THROW 50313, N'Insufficient available stock to reserve.', 1;

        UPDATE [dbo].[Stock]
        SET    [Reserved]  = [Reserved] + @Quantity,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @ChangedBy
        WHERE  [VariantId] = @VariantId AND [WarehouseId] = @WarehouseId;

        DECLARE @ExpiresAt DATETIME2(0) = DATEADD(MINUTE, @TtlMinutes, GETUTCDATE());

        INSERT INTO [dbo].[StockReservations]
            ([VariantId], [WarehouseId], [UserId], [CartLineId], [Quantity], [Status], [ExpiresAt])
        VALUES
            (@VariantId, @WarehouseId, @UserId, @CartLineId, @Quantity, 1, @ExpiresAt);

        DECLARE @ReservationId BIGINT = SCOPE_IDENTITY();

        INSERT INTO [dbo].[StockMovements]
            ([VariantId], [WarehouseId], [MovementType], [QuantityDelta], [ReservedDelta],
             [Reason], [ReferenceType], [ReferenceId], [ChangedBy])
        VALUES
            (@VariantId, @WarehouseId, 3, 0, @Quantity,
             N'Reserve', N'Reservation', @ReservationId, @ChangedBy);

        COMMIT TRANSACTION;

        SELECT @ReservationId AS [ReservationId], @ExpiresAt AS [ExpiresAt];

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
