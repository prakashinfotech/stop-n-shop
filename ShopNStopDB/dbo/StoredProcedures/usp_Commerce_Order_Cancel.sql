CREATE PROCEDURE [dbo].[usp_Commerce_Order_Cancel]
    @OrderId            INT,
    @UserId             INT,
    @CancellationReason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @CurrentStatus TINYINT;
        SELECT @CurrentStatus = [OrderStatus]
        FROM [dbo].[Orders]
        WHERE [OrderId] = @OrderId AND [UserId] = @UserId AND [IsDeleted] = 0;

        IF @CurrentStatus IS NULL
            THROW 50070, N'Order not found.', 1;

        -- Can only cancel Pending or Confirmed orders
        IF @CurrentStatus NOT IN (1, 2)
            THROW 50071, N'Order cannot be cancelled at this stage.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[Orders]
            SET    [OrderStatus]        = 6,   -- Cancelled
                   [CancelledAt]        = GETUTCDATE(),
                   [CancellationReason] = @CancellationReason,
                   [UpdatedAt]          = GETUTCDATE(),
                   [UpdatedBy]          = @UserId
            WHERE  [OrderId] = @OrderId;

            -- Restore stock
            UPDATE pv
            SET    pv.[StockQuantity] = pv.[StockQuantity] + oi.[Quantity],
                   pv.[UpdatedAt]     = GETUTCDATE(),
                   pv.[UpdatedBy]     = @UserId
            FROM [dbo].[ProductVariants] pv
            INNER JOIN [dbo].[OrderItems] oi ON oi.[VariantId] = pv.[VariantId] AND oi.[OrderId] = @OrderId AND oi.[IsDeleted] = 0;

            -- Notification
            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@UserId,
                 N'Order Cancelled',
                 N'Your order has been cancelled.',
                 1, N'Order', @OrderId, 1);

            -- Tracking timeline.
            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [Status], [Note], [ChangedBy])
            VALUES (@OrderId, N'CANCELLED',
                    COALESCE(N'Order cancelled by buyer. Reason: ' + @CancellationReason,
                             N'Order cancelled by buyer.'),
                    @UserId);

        COMMIT TRANSACTION;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
