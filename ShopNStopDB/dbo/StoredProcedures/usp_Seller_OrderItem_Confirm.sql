CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_Confirm]
    @OrderItemId  INT,
    @SellerId     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Ownership + state guard. Only "Placed" lines (status 1) can be confirmed.
        IF NOT EXISTS (
            SELECT 1
            FROM [dbo].[OrderItems]
            WHERE [OrderItemId] = @OrderItemId
              AND [SellerId]    = @SellerId
              AND [IsDeleted]   = 0
        )
            THROW 50300, N'Order item not found or not owned by seller.', 1;

        IF EXISTS (
            SELECT 1
            FROM [dbo].[OrderItems]
            WHERE [OrderItemId] = @OrderItemId
              AND [OrderStatus] <> 1
        )
            THROW 50301, N'Only newly placed items can be confirmed.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[OrderItems]
            SET    [OrderStatus]  = 2,                  -- Confirmed
                   [ConfirmedAt]  = GETUTCDATE(),
                   [UpdatedAt]    = GETUTCDATE()
            WHERE  [OrderItemId]  = @OrderItemId;

            -- Buyer notification
            DECLARE @OrderId       INT;
            DECLARE @OrderNumber   NVARCHAR(50);
            DECLARE @BuyerId       INT;
            DECLARE @ProductName   NVARCHAR(300);

            SELECT @OrderId    = o.[OrderId],
                   @OrderNumber= o.[OrderNumber],
                   @BuyerId    = o.[UserId],
                   @ProductName= oi.[ProductName]
            FROM   [dbo].[OrderItems] oi
            INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
            WHERE  oi.[OrderItemId] = @OrderItemId;

            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerId,
                 N'Order Confirmed',
                 N'The seller has confirmed "' + @ProductName + N'" in order ' + @OrderNumber + N'.',
                 2, N'Order', @OrderId, 1);

            -- Append CONFIRMED entry to the order's tracking timeline.
            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note])
            VALUES (@OrderId, @OrderItemId, N'CONFIRMED', N'Seller confirmed "' + @ProductName + N'".');

        COMMIT TRANSACTION;

        SELECT @OrderItemId AS [OrderItemId], 2 AS [OrderStatus], @OrderNumber AS [OrderNumber];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
