CREATE PROCEDURE [dbo].[usp_Seller_Order_UpdateStatus]
    @OrderId     INT,
    @SellerId    INT,
    @NewStatus   TINYINT,   -- 3=Processing, 4=Shipped, 5=Delivered
    @UpdatedBy   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Validate the order contains items from this seller
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[OrderItems] oi
            INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
            WHERE oi.[OrderId] = @OrderId AND oi.[SellerId] = @SellerId
              AND oi.[IsDeleted] = 0 AND o.[IsDeleted] = 0
        )
            THROW 50090, N'Order not found or does not belong to this seller.', 1;

        -- Sellers can only move status forward (no cancellation via this SP)
        IF @NewStatus NOT IN (3, 4, 5)
            THROW 50091, N'Invalid status transition. Sellers may set Processing, Shipped, or Delivered.', 1;

        DECLARE @DeliveredAt DATETIME2(0) = CASE WHEN @NewStatus = 5 THEN GETUTCDATE() ELSE NULL END;

        UPDATE [dbo].[Orders]
        SET    [OrderStatus]  = @NewStatus,
               [DeliveredAt] = COALESCE(@DeliveredAt, [DeliveredAt]),
               [UpdatedAt]   = GETUTCDATE(),
               [UpdatedBy]   = @UpdatedBy
        WHERE  [OrderId] = @OrderId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
