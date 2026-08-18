-- ============================================================
-- Get Order Detail for Seller (Multiple Result Sets)
-- ============================================================
-- Purpose: Retrieve complete order information including items and address
-- Returns: 3 result sets (Order, Items, Address)
-- ============================================================

CREATE PROCEDURE [dbo].[sp_SellerGetOrderDetail]
    @SellerId   INT,
    @OrderId    INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Order Header
    SELECT
        o.[OrderId],
        o.[OrderNumber],
        o.[UserId],
        o.[OrderStatus] AS [Status],
        o.[PaymentMode] AS [PaymentMethod],
        o.[PaymentStatus],
        o.[SubTotal] AS [TotalMRP],
        o.[DiscountAmount],
        o.[CouponDiscount],
        ISNULL('', '') AS [CouponCode],
        o.[TaxAmount],
        o.[ShippingCharge],
        o.[TotalAmount],
        CAST(o.[CreatedAt] AS DATE) AS [OrderDate],
        o.[CreatedAt],
        ISNULL(CONCAT(u.[FirstName], ' ', u.[LastName]), '') AS [ShipToName],
        ISNULL(u.[Mobile], '') AS [ShipToMobile],
        ISNULL(ua.[AddressLine1], '') AS [AddressLine1],
        ISNULL(ua.[AddressLine2], '') AS [AddressLine2],
        ISNULL(ua.[City], '') AS [City],
        ISNULL(ua.[State], '') AS [State],
        ISNULL(ua.[PinCode], '') AS [Pincode]
    FROM [dbo].[Orders] o
    INNER JOIN [dbo].[Users] u ON o.[UserId] = u.[UserId]
    LEFT JOIN [dbo].[UserAddresses] ua ON o.[ShippingAddressId] = ua.[AddressId]
    WHERE o.[OrderId] = @OrderId
      AND o.[IsDeleted] = 0
      AND EXISTS (
          SELECT 1 FROM [dbo].[OrderItems] oi
          WHERE oi.[OrderId] = o.[OrderId]
            AND oi.[SellerId] = @SellerId
            AND oi.[IsDeleted] = 0
      );

    -- Result Set 2: Order Items
    SELECT
        oi.[OrderItemId],
        oi.[ProductId],
        oi.[OrderId],
        oi.[Quantity],
        oi.[UnitPrice],
        oi.[DiscountAmount],
        oi.[TaxAmount],
        oi.[TotalPrice],
        o.[OrderStatus] AS [Status],
        oi.[ProductName],
        b.[BrandName],
        ISNULL(pi.[ImageUrl], '') AS [ImageUrl],
        oi.[CreatedAt]
    FROM [dbo].[OrderItems] oi
    INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
    INNER JOIN [dbo].[Brands] b ON oi.[BrandId] = b.[BrandId]
    LEFT JOIN [dbo].[ProductImages] pi ON oi.[ProductId] = pi.[ProductId] AND pi.[IsPrimary] = 1
    WHERE oi.[OrderId] = @OrderId
      AND oi.[SellerId] = @SellerId
      AND oi.[IsDeleted] = 0
    ORDER BY oi.[OrderItemId];

    -- Result Set 3: Address (structured)
    SELECT
        ISNULL(CONCAT(u.[FirstName], ' ', u.[LastName]), '') AS [Name],
        ISNULL(u.[Mobile], '') AS [Mobile],
        ISNULL(ua.[AddressLine1], '') AS [Line1],
        ISNULL(ua.[AddressLine2], '') AS [Line2],
        ISNULL(ua.[City], '') AS [City],
        ISNULL(ua.[State], '') AS [State],
        ISNULL(ua.[PinCode], '') AS [Pincode],
        ISNULL(ua.[Country], 'India') AS [Country]
    FROM [dbo].[Orders] o
    INNER JOIN [dbo].[Users] u ON o.[UserId] = u.[UserId]
    LEFT JOIN [dbo].[UserAddresses] ua ON o.[ShippingAddressId] = ua.[AddressId]
    WHERE o.[OrderId] = @OrderId
      AND o.[IsDeleted] = 0;
END;
GO
