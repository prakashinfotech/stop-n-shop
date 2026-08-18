CREATE PROCEDURE [dbo].[usp_Admin_Dashboard_GetStats]
    @FromDate DATE = NULL,
    @ToDate   DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @FromDate = COALESCE(@FromDate, DATEADD(DAY, -29, CAST(GETUTCDATE() AS DATE)));
        SET @ToDate   = COALESCE(@ToDate,   CAST(GETUTCDATE() AS DATE));

        -- Platform summary
        SELECT
            (SELECT COUNT(*) FROM [dbo].[Users]    WHERE [IsDeleted] = 0 AND [RoleId] = 2) AS [TotalBuyers],
            (SELECT COUNT(*) FROM [dbo].[Sellers]  WHERE [IsDeleted] = 0)                  AS [TotalSellers],
            (SELECT COUNT(*) FROM [dbo].[Sellers]  WHERE [IsDeleted] = 0 AND [ApprovalStatus] = 1) AS [PendingSellerApprovals],
            (SELECT COUNT(*) FROM [dbo].[Products] WHERE [IsDeleted] = 0)                  AS [TotalProducts],
            (SELECT COUNT(*) FROM [dbo].[Products] WHERE [IsDeleted] = 0 AND [ApprovalStatus] = 1) AS [PendingProductApprovals],
            (SELECT COUNT(*) FROM [dbo].[Orders]   WHERE [IsDeleted] = 0
              AND CAST([CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate) AS [TotalOrders],
            (SELECT ISNULL(SUM([TotalAmount]), 0)
             FROM [dbo].[Orders]
             WHERE [IsDeleted] = 0 AND [OrderStatus] NOT IN (6, 7)
               AND CAST([CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate) AS [TotalRevenue],
            -- Orders with at least one line still awaiting seller confirmation.
            (SELECT COUNT(DISTINCT oi.[OrderId])
             FROM   [dbo].[OrderItems] oi
             INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
             WHERE  oi.[IsDeleted]   = 0
               AND  o.[IsDeleted]    = 0
               AND  oi.[OrderStatus] = 1) AS [UnfulfilledOrders],
            (SELECT COUNT(*)
             FROM   [dbo].[OrderItems]
             WHERE  [IsDeleted]   = 0
               AND  [OrderStatus] = 8) AS [RejectedOrderItems];

        -- Daily order trend
        SELECT
            CAST(o.[CreatedAt] AS DATE)        AS [OrderDate],
            COUNT(*)                           AS [OrderCount],
            ISNULL(SUM(o.[TotalAmount]), 0)    AS [DailyRevenue]
        FROM [dbo].[Orders] o
        WHERE o.[IsDeleted] = 0
          AND o.[OrderStatus] NOT IN (6, 7)
          AND CAST(o.[CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate
        GROUP BY CAST(o.[CreatedAt] AS DATE)
        ORDER BY CAST(o.[CreatedAt] AS DATE) ASC;

        -- Top 5 sellers by revenue
        SELECT TOP 5
            s.[SellerId],
            s.[BusinessName],
            u.[Email],
            SUM(oi.[SellerEarning]) AS [TotalEarnings],
            COUNT(DISTINCT o.[OrderId]) AS [TotalOrders]
        FROM [dbo].[OrderItems]  oi
        INNER JOIN [dbo].[Orders]   o  ON o.[OrderId]  = oi.[OrderId]
        INNER JOIN [dbo].[Sellers]  s  ON s.[SellerId] = oi.[SellerId]
        INNER JOIN [dbo].[Users]    u  ON u.[UserId]   = s.[UserId]
        WHERE oi.[IsDeleted] = 0 AND o.[IsDeleted] = 0
          AND o.[OrderStatus] NOT IN (6, 7)
          AND CAST(o.[CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate
        GROUP BY s.[SellerId], s.[BusinessName], u.[Email]
        ORDER BY SUM(oi.[SellerEarning]) DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
