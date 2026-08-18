CREATE PROCEDURE [dbo].[usp_Order_CancelByBuyer]
    @OrderId INT,
    @UserId INT,
    @CancellationReason NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus TINYINT;
    DECLARE @OrderUserId INT;

    -- Validate: order exists and belongs to user
    SELECT @CurrentStatus = OrderStatus, @OrderUserId = UserId
    FROM [dbo].[Orders]
    WHERE OrderId = @OrderId AND IsDeleted = 0;

    IF @CurrentStatus IS NULL
    BEGIN
        RAISERROR('Order not found', 16, 1);
        RETURN;
    END;

    IF @OrderUserId <> @UserId
    BEGIN
        RAISERROR('Unauthorized: Order does not belong to this user', 16, 1);
        RETURN;
    END;

    -- Validate: order must be Pending (1) or Confirmed (2)
    -- Cannot cancel if seller has progressed to Processing (3) or beyond
    IF @CurrentStatus > 2
    BEGIN
        RAISERROR('Cannot cancel order after seller has confirmed. Please contact support.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    -- Update order status to Cancelled (6)
    UPDATE [dbo].[Orders]
    SET
        OrderStatus = 6,
        CancelledAt = GETUTCDATE(),
        CancellationReason = @CancellationReason,
        UpdatedAt = GETUTCDATE(),
        UpdatedBy = @UserId
    WHERE OrderId = @OrderId;

    -- Tracking timeline entry.
    INSERT INTO [dbo].[OrderTrackings] ([OrderId], [Status], [Note], [ChangedBy])
    VALUES (@OrderId, N'CANCELLED',
            COALESCE(N'Order cancelled by buyer. Reason: ' + @CancellationReason,
                     N'Order cancelled by buyer.'),
            @UserId);

    COMMIT TRANSACTION;

    -- Return updated order
    SELECT
        OrderId, UserId, OrderNumber, OrderStatus, TotalAmount,
        ShippingAddressId, PaymentMode, ExpectedDeliveryDate,
        CancelledAt, CancellationReason, CreatedAt
    FROM [dbo].[Orders]
    WHERE OrderId = @OrderId;
END;
GO
