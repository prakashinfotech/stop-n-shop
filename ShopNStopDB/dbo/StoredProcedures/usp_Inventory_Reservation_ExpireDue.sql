-- Background worker hook: releases all Active reservations whose ExpiresAt has passed.
-- Returns the count of reservations expired.
CREATE PROCEDURE [dbo].[usp_Inventory_Reservation_ExpireDue]
    @BatchSize INT = 200
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Expired TABLE (
            [ReservationId] BIGINT,
            [VariantId]     INT,
            [WarehouseId]   INT,
            [Quantity]      INT
        );

        ;WITH Due AS (
            SELECT TOP (@BatchSize)
                   [ReservationId], [VariantId], [WarehouseId], [Quantity], [Status], [ReleasedAt]
            FROM [dbo].[StockReservations] WITH (READPAST, UPDLOCK)
            WHERE [Status] = 1 AND [ExpiresAt] <= GETUTCDATE()
            ORDER BY [ExpiresAt] ASC
        )
        UPDATE Due
        SET [Status]     = 4,
            [ReleasedAt] = GETUTCDATE()
        OUTPUT inserted.[ReservationId], inserted.[VariantId], inserted.[WarehouseId], inserted.[Quantity]
        INTO @Expired;

        -- Decrement Reserved on each touched Stock row
        UPDATE s
        SET [Reserved]  = s.[Reserved] - g.[TotalQty],
            [UpdatedAt] = GETUTCDATE()
        FROM [dbo].[Stock] s
        INNER JOIN (
            SELECT [VariantId], [WarehouseId], SUM([Quantity]) AS [TotalQty]
            FROM @Expired
            GROUP BY [VariantId], [WarehouseId]
        ) g
            ON g.[VariantId]   = s.[VariantId]
           AND g.[WarehouseId] = s.[WarehouseId];

        INSERT INTO [dbo].[StockMovements]
            ([VariantId], [WarehouseId], [MovementType], [QuantityDelta], [ReservedDelta],
             [Reason], [ReferenceType], [ReferenceId], [ChangedBy])
        SELECT [VariantId], [WarehouseId], 4, 0, -[Quantity],
               N'Reservation expired', N'Reservation', [ReservationId], NULL
        FROM @Expired;

        DECLARE @Count INT = (SELECT COUNT(1) FROM @Expired);

        COMMIT TRANSACTION;
        SELECT @Count AS [ExpiredCount];

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
