CREATE PROCEDURE [dbo].[usp_Seller_Dashboard_GetAnalytics]
    @SellerId INT,
    @FromDate DATE = NULL,
    @ToDate   DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @FromDate = COALESCE(@FromDate, DATEADD(DAY, -29, CAST(GETUTCDATE() AS DATE)));
    SET @ToDate   = COALESCE(@ToDate,   CAST(GETUTCDATE() AS DATE));

    DECLARE @TotalRevenue DECIMAL(18,2) = 0;
    DECLARE @TotalOrders INT = 0;
    DECLARE @TotalUnitsSold INT = 0;
    DECLARE @AverageOrderValue DECIMAL(18,2) = 0;
    DECLARE @NewOrders INT = 0;
    DECLARE @ProcessingOrders INT = 0;
    DECLARE @ShippedOrders INT = 0;
    DECLARE @DeliveredOrders INT = 0;
    DECLARE @CancelledOrders INT = 0;

    -- Revenue / orders / units — restricted to Delivered + Paid line items so
    -- this number aligns with what SellerSettlements gross sales actually pay
    -- out. Uses TotalPrice (post-discount, incl. tax) so the basis matches
    -- usp_Seller_Settlement_Calculate exactly.
    SELECT @TotalRevenue   = ISNULL(SUM(oi.[TotalPrice]), 0),
           @TotalOrders    = COUNT(DISTINCT oi.[OrderId]),
           @TotalUnitsSold = ISNULL(SUM(oi.[Quantity]), 0)
    FROM   [dbo].[OrderItems] oi
    INNER  JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
    WHERE  oi.[SellerId]     = @SellerId
       AND oi.[IsDeleted]    = 0
       AND oi.[IsReturned]   = 0
       AND o.[IsDeleted]     = 0
       AND o.[OrderStatus]   = 5   -- Delivered
       AND o.[PaymentStatus] = 2   -- Paid
       AND CAST(o.[CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate;

    -- Average order value
    SET @AverageOrderValue = CASE
        WHEN @TotalOrders > 0 THEN @TotalRevenue / @TotalOrders
        ELSE 0
    END;

    -- Orders by status (current status, regardless of date)
    SELECT @NewOrders = COUNT(DISTINCT oi.[OrderId])
    FROM [dbo].[OrderItems] oi
    INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
    WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 1;

    SELECT @ProcessingOrders = COUNT(DISTINCT oi.[OrderId])
    FROM [dbo].[OrderItems] oi
    INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
    WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 3;

    SELECT @ShippedOrders = COUNT(DISTINCT oi.[OrderId])
    FROM [dbo].[OrderItems] oi
    INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
    WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 4;

    SELECT @DeliveredOrders = COUNT(DISTINCT oi.[OrderId])
    FROM [dbo].[OrderItems] oi
    INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
    WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 5;

    SELECT @CancelledOrders = COUNT(DISTINCT oi.[OrderId])
    FROM [dbo].[OrderItems] oi
    INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
    WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 6;

    -- Return single result set with all analytics
    SELECT
        @FromDate AS [FromDate],
        @ToDate AS [ToDate],
        @TotalRevenue AS [TotalRevenue],
        @TotalOrders AS [TotalOrders],
        @TotalUnitsSold AS [TotalUnitsSold],
        @AverageOrderValue AS [AverageOrderValue],
        @NewOrders AS [NewOrders],
        @ProcessingOrders AS [ProcessingOrders],
        @ShippedOrders AS [ShippedOrders],
        @DeliveredOrders AS [DeliveredOrders],
        @CancelledOrders AS [CancelledOrders];
END;
GO
