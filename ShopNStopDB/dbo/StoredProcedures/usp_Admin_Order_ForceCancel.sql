-- Admin-driven order cancellation. Unlike buyer cancel, this bypasses the
-- "only PLACED/CONFIRMED may cancel" guard but still refuses terminal states.
CREATE PROCEDURE [dbo].[usp_Admin_Order_ForceCancel]
    @OrderId     INT,
    @AdminUserId INT,
    @Reason      NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @CurrentStatus TINYINT;
        SELECT @CurrentStatus = [OrderStatus]
        FROM   [dbo].[Orders]
        WHERE  [OrderId] = @OrderId AND [IsDeleted] = 0;

        IF @CurrentStatus IS NULL
            THROW 50150, N'Order not found.', 1;

        IF @CurrentStatus IN (5, 6, 7)  -- Delivered / Cancelled / Returned
            THROW 50151, N'Order is in a terminal state and cannot be force-cancelled.', 1;

        UPDATE [dbo].[Orders]
        SET    [OrderStatus]        = 6,
               [CancelledAt]        = GETUTCDATE(),
               [CancellationReason] = @Reason,
               [UpdatedAt]          = GETUTCDATE(),
               [UpdatedBy]          = @AdminUserId
        WHERE  [OrderId] = @OrderId;

        SELECT 1 AS [Success];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
