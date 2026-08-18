CREATE PROCEDURE [dbo].[usp_Commerce_Order_GetById]
    @OrderId INT,
    @UserId  INT = NULL    -- NULL = admin lookup (no user restriction)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            o.[OrderId], o.[OrderNumber], o.[OrderStatus],
            o.[SubTotal], o.[DiscountAmount], o.[CouponDiscount],
            o.[TaxAmount], o.[ShippingCharge], o.[TotalAmount],
            o.[PaymentMode], o.[PaymentStatus], o.[PaymentGatewayRef],
            o.[ExpectedDeliveryDate], o.[DeliveredAt], o.[CancelledAt],
            o.[CancellationReason], o.[CreatedAt] AS [OrderDate],
            -- Address
            ua.[Label]        AS [AddressLabel],
            ua.[AddressLine1], ua.[AddressLine2],
            ua.[City], ua.[State], ua.[PinCode], ua.[Country],
            -- Coupon
            cp.[CouponCode]
        FROM [dbo].[Orders]        o
        INNER JOIN [dbo].[UserAddresses] ua ON ua.[AddressId] = o.[ShippingAddressId]
        LEFT  JOIN [dbo].[Coupons]       cp ON cp.[CouponId]  = o.[CouponId]
        WHERE o.[OrderId]  = @OrderId
          AND o.[IsDeleted] = 0
          AND (@UserId IS NULL OR o.[UserId] = @UserId);

        -- Return order items (incl. per-line fulfilment state)
        SELECT
            oi.[OrderItemId], oi.[ProductId], oi.[VariantId],
            oi.[ProductName], oi.[VariantSnapshot],
            oi.[Quantity], oi.[UnitPrice], oi.[DiscountAmount],
            oi.[TaxAmount], oi.[TotalPrice],
            oi.[CommissionAmount], oi.[SellerEarning],
            oi.[IsReturned], oi.[ReturnReason],
            oi.[OrderStatus]      AS [LineStatus],
            oi.[ConfirmedAt],
            oi.[RejectedAt],
            oi.[RejectionReason],
            b.[BrandName],
            s.[BusinessName] AS [SellerName],
            pi_.[ImageUrl]   AS [ProductImageUrl]
        FROM [dbo].[OrderItems]       oi
        INNER JOIN [dbo].[Brands]         b   ON b.[BrandId]   = oi.[BrandId]
        INNER JOIN [dbo].[Sellers]        s   ON s.[SellerId]  = oi.[SellerId]
        LEFT  JOIN [dbo].[ProductImages]  pi_ ON pi_.[ProductId] = oi.[ProductId]
                                              AND pi_.[IsPrimary] = 1
                                              AND pi_.[IsDeleted] = 0
        WHERE oi.[OrderId]  = @OrderId
          AND oi.[IsDeleted] = 0;

        -- Tracking timeline (append-only). Ordered ascending so the buyer UI
        -- can render the strip left-to-right without re-sorting.
        SELECT
            t.[TrackingId],
            t.[OrderId],
            t.[OrderItemId],
            t.[Status],
            t.[Note],
            t.[ChangedAt],
            t.[ChangedBy]
        FROM [dbo].[OrderTrackings] t
        WHERE t.[OrderId] = @OrderId
        ORDER BY t.[ChangedAt] ASC, t.[TrackingId] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
