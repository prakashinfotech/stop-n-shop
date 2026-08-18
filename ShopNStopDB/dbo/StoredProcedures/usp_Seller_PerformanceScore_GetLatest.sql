CREATE PROCEDURE [dbo].[usp_Seller_PerformanceScore_GetLatest]
    @SellerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
           [PerformanceScoreId], [SellerId], [SnapshotDate], [WindowDays],
           [OrdersTotal], [OrdersDelivered], [OrdersCancelled], [OrdersReturned],
           [OnTimeDispatchPct], [CancellationPct], [ReturnPct], [AvgRating],
           [CompositeScore], [Tier], [CreatedAt]
    FROM   [dbo].[SellerPerformanceScores]
    WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0
    ORDER  BY [SnapshotDate] DESC;
END;
GO
