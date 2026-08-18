CREATE PROCEDURE [dbo].[usp_Seller_PerformanceScore_Recompute]
    @SellerId     INT,
    @SnapshotDate DATE = NULL,
    @WindowDays   INT  = 30
AS
/*
  Computes a rolling-window performance snapshot for a seller and upserts the row for
  (@SellerId, @SnapshotDate). Composite score weights:
    on-time dispatch    40%
    1 - cancellation %  20%
    1 - return %        20%
    avg rating / 5      20%
*/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @SnapshotDate = COALESCE(@SnapshotDate, CAST(GETUTCDATE() AS DATE));
    DECLARE @WindowStart DATE = DATEADD(DAY, -@WindowDays, @SnapshotDate);

    DECLARE @OrdersTotal     INT = 0;
    DECLARE @OrdersDelivered INT = 0;
    DECLARE @OrdersCancelled INT = 0;
    DECLARE @OrdersReturned  INT = 0;
    DECLARE @OnTimePct       DECIMAL(5,2) = 0;
    DECLARE @CancelPct       DECIMAL(5,2) = 0;
    DECLARE @ReturnPct       DECIMAL(5,2) = 0;
    DECLARE @AvgRating       DECIMAL(3,2) = 0;

    SELECT @OrdersTotal     = COUNT(DISTINCT oi.[OrderId]),
           @OrdersDelivered = COUNT(DISTINCT CASE WHEN o.[OrderStatus] = 5 THEN oi.[OrderId] END),
           @OrdersCancelled = COUNT(DISTINCT CASE WHEN o.[OrderStatus] = 6 THEN oi.[OrderId] END),
           @OrdersReturned  = COUNT(DISTINCT CASE WHEN oi.[IsReturned] = 1 THEN oi.[OrderId] END)
    FROM   [dbo].[OrderItems] oi
    INNER  JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
    WHERE  oi.[SellerId]   = @SellerId
       AND oi.[IsDeleted]  = 0
       AND o.[IsDeleted]   = 0
       AND CAST(o.[CreatedAt] AS DATE) BETWEEN @WindowStart AND @SnapshotDate;

    IF @OrdersTotal > 0
    BEGIN
        SET @CancelPct = CAST(@OrdersCancelled AS DECIMAL(9,2)) * 100 / @OrdersTotal;
        SET @ReturnPct = CAST(@OrdersReturned  AS DECIMAL(9,2)) * 100 / @OrdersTotal;
        SET @OnTimePct =
            CASE WHEN @OrdersDelivered = 0 THEN 0
                 ELSE CAST(@OrdersDelivered AS DECIMAL(9,2)) * 100 / NULLIF(@OrdersTotal - @OrdersCancelled, 0)
            END;
    END

    SELECT @AvgRating = COALESCE(AVG(CAST(r.[Rating] AS DECIMAL(3,2))), 0)
    FROM   [dbo].[Reviews] r
    INNER  JOIN [dbo].[Products] p ON p.[ProductId] = r.[ProductId]
    WHERE  p.[SellerId]  = @SellerId
       AND r.[IsDeleted] = 0
       AND CAST(r.[CreatedAt] AS DATE) BETWEEN @WindowStart AND @SnapshotDate;

    DECLARE @Composite DECIMAL(5,2) =
          (@OnTimePct                 * 0.40)
        + ((100 - @CancelPct)         * 0.20)
        + ((100 - @ReturnPct)         * 0.20)
        + ((@AvgRating * 20)          * 0.20);

    DECLARE @Tier NVARCHAR(20) =
        CASE
            WHEN @Composite >= 90 THEN N'Platinum'
            WHEN @Composite >= 80 THEN N'Gold'
            WHEN @Composite >= 70 THEN N'Silver'
            ELSE N'Bronze'
        END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1 FROM [dbo].[SellerPerformanceScores]
            WHERE [SellerId] = @SellerId AND [SnapshotDate] = @SnapshotDate
        )
            UPDATE [dbo].[SellerPerformanceScores]
            SET    [WindowDays]        = @WindowDays,
                   [OrdersTotal]       = @OrdersTotal,
                   [OrdersDelivered]   = @OrdersDelivered,
                   [OrdersCancelled]   = @OrdersCancelled,
                   [OrdersReturned]    = @OrdersReturned,
                   [OnTimeDispatchPct] = @OnTimePct,
                   [CancellationPct]   = @CancelPct,
                   [ReturnPct]         = @ReturnPct,
                   [AvgRating]         = @AvgRating,
                   [CompositeScore]    = @Composite,
                   [Tier]              = @Tier
            WHERE  [SellerId] = @SellerId AND [SnapshotDate] = @SnapshotDate;
        ELSE
            INSERT INTO [dbo].[SellerPerformanceScores]
                ([SellerId], [SnapshotDate], [WindowDays],
                 [OrdersTotal], [OrdersDelivered], [OrdersCancelled], [OrdersReturned],
                 [OnTimeDispatchPct], [CancellationPct], [ReturnPct], [AvgRating],
                 [CompositeScore], [Tier])
            VALUES
                (@SellerId, @SnapshotDate, @WindowDays,
                 @OrdersTotal, @OrdersDelivered, @OrdersCancelled, @OrdersReturned,
                 @OnTimePct, @CancelPct, @ReturnPct, @AvgRating,
                 @Composite, @Tier);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    SELECT [PerformanceScoreId], [SellerId], [SnapshotDate], [WindowDays],
           [OrdersTotal], [OrdersDelivered], [OrdersCancelled], [OrdersReturned],
           [OnTimeDispatchPct], [CancellationPct], [ReturnPct], [AvgRating],
           [CompositeScore], [Tier], [CreatedAt]
    FROM   [dbo].[SellerPerformanceScores]
    WHERE  [SellerId] = @SellerId AND [SnapshotDate] = @SnapshotDate;
END;
GO
