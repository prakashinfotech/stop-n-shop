CREATE PROCEDURE [dbo].[usp_SellerOrder_UpdateStatus]
    @OrderId INT,
    @SellerId INT,
    @NewStatus TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus TINYINT;
    DECLARE @SellerHasItems BIT;
    DECLARE @OrderUserId INT;

    -- Validate: order exists
    SELECT @CurrentStatus = OrderStatus, @OrderUserId = UserId
    FROM [dbo].[Orders]
    WHERE OrderId = @OrderId AND IsDeleted = 0;

    IF @CurrentStatus IS NULL
    BEGIN
        RAISERROR('Order not found', 16, 1);
        RETURN;
    END;

    -- Validate: seller has items in this order
    SELECT @SellerHasItems = COUNT(*)
    FROM [dbo].[OrderItems]
    WHERE OrderId = @OrderId AND SellerId = @SellerId AND IsDeleted = 0;

    IF @SellerHasItems = 0
    BEGIN
        RAISERROR('Unauthorized: You did not sell items in this order', 16, 1);
        RETURN;
    END;

    -- Validate: status transition is valid
    -- Valid: 1→2, 2→3, 3→4, 4→5, anything→6
    IF @NewStatus NOT IN (1, 2, 3, 4, 5, 6)
    BEGIN
        RAISERROR('Invalid order status', 16, 1);
        RETURN;
    END;

    IF @NewStatus <> 6 AND @NewStatus <= @CurrentStatus
    BEGIN
        RAISERROR('Cannot revert order status. Only forward progression or cancellation allowed.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    -- Update order status
    UPDATE [dbo].[Orders]
    SET
        OrderStatus = @NewStatus,
        UpdatedAt = GETUTCDATE(),
        UpdatedBy = @SellerId
    WHERE OrderId = @OrderId;

    -- If delivered, set delivery timestamp
    IF @NewStatus = 5
    BEGIN
        UPDATE [dbo].[Orders]
        SET DeliveredAt = GETUTCDATE()
        WHERE OrderId = @OrderId AND DeliveredAt IS NULL;
    END;

    COMMIT TRANSACTION;

    -- Return updated order
    SELECT
        OrderId, UserId, OrderNumber, OrderStatus, TotalAmount,
        ShippingAddressId, PaymentMode, ExpectedDeliveryDate,
        DeliveredAt, CreatedAt, UpdatedAt
    FROM [dbo].[Orders]
    WHERE OrderId = @OrderId;
END;
GO
