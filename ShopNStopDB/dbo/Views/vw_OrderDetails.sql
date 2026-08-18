CREATE VIEW [dbo].[vw_OrderDetails]
AS
SELECT
    o.[OrderId],
    o.[OrderNumber],
    o.[OrderStatus],
    o.[SubTotal],
    o.[DiscountAmount],
    o.[CouponDiscount],
    o.[TaxAmount],
    o.[ShippingCharge],
    o.[TotalAmount],
    o.[PaymentMode],
    o.[PaymentStatus],
    o.[ExpectedDeliveryDate],
    o.[DeliveredAt],
    o.[CancelledAt],
    o.[CancellationReason],
    o.[CreatedAt]           AS [OrderDate],

    -- Buyer
    u.[UserId],
    u.[Email]               AS [BuyerEmail],
    u.[FirstName]           AS [BuyerFirstName],
    u.[LastName]            AS [BuyerLastName],

    -- Shipping Address
    ua.[AddressLine1],
    ua.[AddressLine2],
    ua.[City],
    ua.[State],
    ua.[PinCode],
    ua.[Country],

    -- Coupon (if any)
    cp.[CouponCode],

    -- Order Items
    oi.[OrderItemId],
    oi.[ProductId],
    oi.[VariantId],
    oi.[SellerId],
    oi.[BrandId],
    oi.[ProductName],
    oi.[VariantSnapshot],
    oi.[Quantity],
    oi.[UnitPrice],
    oi.[DiscountAmount]     AS [ItemDiscountAmount],
    oi.[TaxAmount]          AS [ItemTaxAmount],
    oi.[TotalPrice],
    oi.[CommissionAmount],
    oi.[SellerEarning],
    oi.[IsReturned]

FROM [dbo].[Orders]        o
INNER JOIN [dbo].[Users]           u   ON u.[UserId]    = o.[UserId]            AND u.[IsDeleted]    = 0
INNER JOIN [dbo].[UserAddresses]   ua  ON ua.[AddressId] = o.[ShippingAddressId]
INNER JOIN [dbo].[OrderItems]      oi  ON oi.[OrderId]   = o.[OrderId]          AND oi.[IsDeleted]   = 0
LEFT  JOIN [dbo].[Coupons]         cp  ON cp.[CouponId]  = o.[CouponId]

WHERE o.[IsDeleted] = 0;
GO
