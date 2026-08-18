CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_UpdateStatus]
    @OrderItemId  INT,
    @SellerId     INT,
    @NewStatus    TINYINT       -- 3 Packed | 4 Dispatched | 9 OutForDelivery | 5 Delivered
AS
/*
  Forward-only line-item progression for the seller fulfilment console.

  Allowed transitions (current → next):
      2 (Confirmed)        → 3 (Packed)
      3 (Packed)           → 4 (Dispatched)
      4 (Dispatched)       → 9 (OutForDelivery)
      9 (OutForDelivery)   → 5 (Delivered)

  Any other (current, next) pair raises 50306. Backward moves are blocked.
  Caller ownership is enforced — only the seller who owns the line may move it.

  Side effects:
    - When the line reaches 5 (Delivered), Orders.DeliveredAt is stamped if the
      order has any delivered child item (so Settlement_Calculate's date filter
      keeps working at the order header level).
    - Buyer notification is fired on every successful transition.
*/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @CurrentStatus TINYINT;
        DECLARE @OrderId       INT;
        DECLARE @OrderNumber   NVARCHAR(50);
        DECLARE @BuyerId       INT;
        DECLARE @ProductName   NVARCHAR(300);

        SELECT @CurrentStatus = oi.[OrderStatus],
               @OrderId       = o.[OrderId],
               @OrderNumber   = o.[OrderNumber],
               @BuyerId       = o.[UserId],
               @ProductName   = oi.[ProductName]
        FROM   [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
        WHERE  oi.[OrderItemId] = @OrderItemId
          AND  oi.[SellerId]    = @SellerId
          AND  oi.[IsDeleted]   = 0;

        IF @CurrentStatus IS NULL
            THROW 50305, N'Order item not found or not owned by seller.', 1;

        -- Whitelist forward transitions.
        DECLARE @Allowed BIT = 0;
        IF (@CurrentStatus = 2 AND @NewStatus = 3) SET @Allowed = 1;
        IF (@CurrentStatus = 3 AND @NewStatus = 4) SET @Allowed = 1;
        IF (@CurrentStatus = 4 AND @NewStatus = 9) SET @Allowed = 1;
        IF (@CurrentStatus = 9 AND @NewStatus = 5) SET @Allowed = 1;

        IF @Allowed = 0
            THROW 50306, N'Invalid transition. Items move Confirmed → Packed → Dispatched → Out for Delivery → Delivered, one step at a time.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[OrderItems]
            SET    [OrderStatus] = @NewStatus,
                   [UpdatedAt]   = GETUTCDATE()
            WHERE  [OrderItemId] = @OrderItemId;

            -- Stamp Orders.DeliveredAt the moment ANY child line is marked
            -- Delivered (settlement calc reads this date).
            IF @NewStatus = 5
            BEGIN
                UPDATE [dbo].[Orders]
                SET    [DeliveredAt] = COALESCE([DeliveredAt], GETUTCDATE()),
                       [UpdatedAt]   = GETUTCDATE()
                WHERE  [OrderId] = @OrderId;
            END

            DECLARE @StatusLabel NVARCHAR(40) =
                CASE @NewStatus
                    WHEN 3 THEN N'Packed'
                    WHEN 4 THEN N'Dispatched'
                    WHEN 9 THEN N'Out for Delivery'
                    WHEN 5 THEN N'Delivered'
                END;

            -- Machine-friendly status code mirrors the UI label map
            -- (PACKED / DISPATCHED / OUT_FOR_DELIVERY / DELIVERED).
            DECLARE @StatusCode NVARCHAR(40) =
                CASE @NewStatus
                    WHEN 3 THEN N'PACKED'
                    WHEN 4 THEN N'DISPATCHED'
                    WHEN 9 THEN N'OUT_FOR_DELIVERY'
                    WHEN 5 THEN N'DELIVERED'
                END;

            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerId,
                 N'Order Update: ' + @StatusLabel,
                 N'"' + @ProductName + N'" in order ' + @OrderNumber + N' is now ' + @StatusLabel + N'.',
                 2, N'Order', @OrderId, 1);

            -- Append the transition to the order's tracking timeline.
            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note])
            VALUES (@OrderId, @OrderItemId, @StatusCode,
                    N'"' + @ProductName + N'" marked ' + @StatusLabel + N'.');

        COMMIT TRANSACTION;

        SELECT @OrderItemId AS [OrderItemId],
               @NewStatus   AS [OrderStatus],
               @OrderNumber AS [OrderNumber];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
