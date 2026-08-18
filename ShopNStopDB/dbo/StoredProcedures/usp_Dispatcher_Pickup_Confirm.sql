-- Dispatcher confirms all picked-up items left the warehouse — second half of
-- the pickup flow. Bulk transition: every item currently at status 10
-- (PickedUp) claimed BY THIS dispatcher moves to status 4 (Dispatched), the
-- assignment row mirrors the move, and a DISPATCHED tracking entry is written
-- per item.
--
-- Returns the count of items confirmed. Designed for the "I'm leaving the
-- warehouse" button on the dispatcher portal.
CREATE PROCEDURE [dbo].[usp_Dispatcher_Pickup_Confirm]
    @DispatcherId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Snapshot the items we're confirming for tracking entries.
            DECLARE @Affected TABLE (
                AssignmentId INT,
                OrderItemId  INT,
                OrderId      INT,
                ProductName  NVARCHAR(300)
            );

            INSERT INTO @Affected (AssignmentId, OrderItemId, OrderId, ProductName)
            SELECT da.[AssignmentId], oi.[OrderItemId], oi.[OrderId], oi.[ProductName]
            FROM   [dbo].[DeliveryAssignments] da
            INNER JOIN [dbo].[OrderItems]      oi ON oi.[OrderItemId] = da.[OrderItemId]
            WHERE  da.[DispatcherId] = @DispatcherId
              AND  da.[Status]       = 10
              AND  oi.[OrderStatus]  = 10
              AND  oi.[IsDeleted]    = 0;

            DECLARE @Count INT = (SELECT COUNT(*) FROM @Affected);

            IF @Count = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS [Confirmed];
                RETURN;
            END

            -- Flip assignments to Dispatched
            UPDATE da
            SET    da.[Status]    = 4,
                   da.[UpdatedAt] = GETUTCDATE()
            FROM   [dbo].[DeliveryAssignments] da
            INNER JOIN @Affected a ON a.AssignmentId = da.[AssignmentId];

            -- Flip order items to Dispatched
            UPDATE oi
            SET    oi.[OrderStatus] = 4,
                   oi.[UpdatedAt]   = GETUTCDATE()
            FROM   [dbo].[OrderItems] oi
            INNER JOIN @Affected a ON a.OrderItemId = oi.[OrderItemId];

            -- One tracking entry per item
            INSERT INTO [dbo].[OrderTrackings]
                ([OrderId], [OrderItemId], [Status], [Note])
            SELECT a.OrderId, a.OrderItemId, N'DISPATCHED',
                   N'"' + a.ProductName + N'" left the warehouse and is in transit.'
            FROM   @Affected a;

        COMMIT TRANSACTION;

        SELECT @Count AS [Confirmed];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
