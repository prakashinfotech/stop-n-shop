-- Placeholder seller performance snapshot.
-- Computed live from Orders/OrderItems/Reviews until the dedicated
-- SellerPerformanceScore table lands in Phase 3.
CREATE PROCEDURE [dbo].[usp_Admin_Seller_ScoreGet]
    @SellerId  INT,
    @FromDate  DATE = NULL,
    @ToDate    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ToDate   IS NULL SET @ToDate   = CAST(GETUTCDATE() AS DATE);
    IF @FromDate IS NULL SET @FromDate = DATEADD(DAY, -30, @ToDate);

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
        THROW 50140, N'Seller not found.', 1;

    DECLARE @TotalOrders     INT = 0;
    DECLARE @CancelledOrders INT = 0;
    DECLARE @DeliveredOrders INT = 0;
    DECLARE @GMV             DECIMAL(18,2) = 0;
    DECLARE @AvgRating       DECIMAL(3,2) = 0;
    DECLARE @ReviewCount     INT = 0;

    SELECT
        @TotalOrders     = COUNT(DISTINCT o.[OrderId]),
        @CancelledOrders = SUM(CASE WHEN o.[OrderStatus] = 6 THEN 1 ELSE 0 END),
        @DeliveredOrders = SUM(CASE WHEN o.[OrderStatus] = 5 THEN 1 ELSE 0 END),
        @GMV             = ISNULL(SUM(oi.[UnitPrice] * oi.[Quantity]), 0)
    FROM [dbo].[Orders]     o
    INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderId]  = o.[OrderId]
    INNER JOIN [dbo].[Products]   p  ON p.[ProductId] = oi.[ProductId]
    WHERE p.[SellerId] = @SellerId
      AND o.[CreatedAt] >= @FromDate
      AND o.[CreatedAt] <  DATEADD(DAY, 1, @ToDate)
      AND o.[IsDeleted] = 0;

    SELECT
        @AvgRating   = ISNULL(AVG(CAST(r.[Rating] AS DECIMAL(3,2))), 0),
        @ReviewCount = COUNT(1)
    FROM [dbo].[Reviews]  r
    INNER JOIN [dbo].[Products] p ON p.[ProductId] = r.[ProductId]
    WHERE p.[SellerId] = @SellerId
      AND r.[IsApproved] = 1
      AND r.[IsDeleted]  = 0;

    SELECT
        @SellerId         AS [SellerId],
        @FromDate         AS [FromDate],
        @ToDate           AS [ToDate],
        @TotalOrders      AS [TotalOrders],
        @DeliveredOrders  AS [DeliveredOrders],
        @CancelledOrders  AS [CancelledOrders],
        @GMV              AS [Gmv],
        @AvgRating        AS [AverageRating],
        @ReviewCount      AS [ReviewCount],
        CASE
            WHEN @TotalOrders = 0 THEN 0
            ELSE CAST((@DeliveredOrders * 100.0) / @TotalOrders AS DECIMAL(5,2))
        END                AS [DeliveryRatePct],
        CASE
            WHEN @TotalOrders = 0 THEN 0
            ELSE CAST((@CancelledOrders * 100.0) / @TotalOrders AS DECIMAL(5,2))
        END                AS [CancellationRatePct];
END;
GO
