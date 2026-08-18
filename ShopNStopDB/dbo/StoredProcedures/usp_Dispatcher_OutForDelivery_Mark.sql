-- Dispatcher marks a dispatched parcel as Out for Delivery (status 4 → 9).
-- This is the gate that unlocks the delivery-OTP flow: only OFD parcels can
-- have a delivery OTP generated. Moves both DeliveryAssignments.Status and
-- OrderItems.OrderStatus to 9, stamps OutForDeliveryAt, writes an
-- OUT_FOR_DELIVERY tracking entry.
CREATE PROCEDURE [dbo].[usp_Dispatcher_OutForDelivery_Mark]
    @AssignmentId INT,
    @DispatcherId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @CurrentStatus TINYINT;
        DECLARE @OrderItemId   INT;
        DECLARE @OrderId       INT;
        DECLARE @OrderNumber   NVARCHAR(50);
        DECLARE @ProductName   NVARCHAR(300);

        SELECT @CurrentStatus = da.[Status],
               @OrderItemId   = da.[OrderItemId],
               @OrderId       = oi.[OrderId],
               @OrderNumber   = o.[OrderNumber],
               @ProductName   = oi.[ProductName]
        FROM   [dbo].[DeliveryAssignments] da WITH (UPDLOCK, ROWLOCK)
        INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderItemId] = da.[OrderItemId]
        INNER JOIN [dbo].[Orders]     o  ON o.[OrderId]      = oi.[OrderId]
        WHERE  da.[AssignmentId] = @AssignmentId
          AND  da.[DispatcherId] = @DispatcherId;

        IF @CurrentStatus IS NULL
            THROW 50420, N'Assignment not found or not owned by you.', 1;

        IF @CurrentStatus <> 4
            THROW 50421, N'Only Dispatched parcels can be marked Out for Delivery.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[DeliveryAssignments]
            SET    [Status]           = 9,
                   [OutForDeliveryAt] = GETUTCDATE(),
                   [UpdatedAt]        = GETUTCDATE()
            WHERE  [AssignmentId] = @AssignmentId;

            UPDATE [dbo].[OrderItems]
            SET    [OrderStatus] = 9,
                   [UpdatedAt]   = GETUTCDATE()
            WHERE  [OrderItemId] = @OrderItemId;

            INSERT INTO [dbo].[OrderTrackings]
                ([OrderId], [OrderItemId], [Status], [Note], [ChangedAt])
            VALUES
                (@OrderId, @OrderItemId, N'OUT_FOR_DELIVERY',
                 N'"' + @ProductName + N'" is out for delivery.', GETUTCDATE());

        COMMIT TRANSACTION;

        SELECT @AssignmentId AS [AssignmentId],
               @OrderItemId  AS [OrderItemId],
               9             AS [Status],
               @OrderNumber  AS [OrderNumber];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
