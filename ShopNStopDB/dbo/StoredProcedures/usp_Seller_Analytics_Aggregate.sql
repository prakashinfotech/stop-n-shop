-- Called by a scheduled job (e.g., SQL Agent) nightly to populate SellerAnalyticsDaily.
CREATE PROCEDURE [dbo].[usp_Seller_Analytics_Aggregate]
    @AggregateDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @AggregateDate = COALESCE(@AggregateDate, CAST(DATEADD(DAY, -1, GETUTCDATE()) AS DATE));

        BEGIN TRANSACTION;

            MERGE [dbo].[SellerAnalyticsDaily] AS tgt
            USING (
                SELECT
                    oi.[SellerId],
                    @AggregateDate                  AS [AnalyticsDate],
                    COUNT(DISTINCT o.[OrderId])     AS [TotalOrders],
                    SUM(oi.[TotalPrice])            AS [TotalRevenue],
                    SUM(oi.[CommissionAmount])      AS [TotalCommission],
                    SUM(oi.[SellerEarning])         AS [TotalEarnings],
                    ISNULL(pv.[TotalViews], 0)      AS [TotalProductViews],
                    ISNULL(pv.[UniqueVisitors], 0)  AS [TotalUniqueVisitors]
                FROM [dbo].[OrderItems] oi
                INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
                LEFT JOIN (
                    SELECT
                        p.[SellerId],
                        COUNT(*)                          AS [TotalViews],
                        COUNT(DISTINCT pvl.[SessionId])   AS [UniqueVisitors]
                    FROM [dbo].[ProductViewLogs] pvl
                    INNER JOIN [dbo].[Products] p ON p.[ProductId] = pvl.[ProductId]
                    WHERE CAST(pvl.[ViewedAt] AS DATE) = @AggregateDate
                    GROUP BY p.[SellerId]
                ) pv ON pv.[SellerId] = oi.[SellerId]
                WHERE oi.[IsDeleted]  = 0
                  AND o.[IsDeleted]   = 0
                  AND o.[OrderStatus] NOT IN (6, 7)
                  AND CAST(o.[CreatedAt] AS DATE) = @AggregateDate
                GROUP BY oi.[SellerId], pv.[TotalViews], pv.[UniqueVisitors]
            ) AS src
            ON tgt.[SellerId] = src.[SellerId] AND tgt.[AnalyticsDate] = src.[AnalyticsDate]
            WHEN MATCHED THEN UPDATE SET
                tgt.[TotalOrders]         = src.[TotalOrders],
                tgt.[TotalRevenue]        = src.[TotalRevenue],
                tgt.[TotalCommission]     = src.[TotalCommission],
                tgt.[TotalEarnings]       = src.[TotalEarnings],
                tgt.[TotalProductViews]   = src.[TotalProductViews],
                tgt.[TotalUniqueVisitors] = src.[TotalUniqueVisitors],
                tgt.[UpdatedAt]           = GETUTCDATE()
            WHEN NOT MATCHED THEN INSERT
                ([SellerId], [AnalyticsDate], [TotalOrders], [TotalRevenue],
                 [TotalCommission], [TotalEarnings], [TotalProductViews], [TotalUniqueVisitors])
            VALUES
                (src.[SellerId], src.[AnalyticsDate], src.[TotalOrders], src.[TotalRevenue],
                 src.[TotalCommission], src.[TotalEarnings], src.[TotalProductViews], src.[TotalUniqueVisitors]);

        COMMIT TRANSACTION;

        SELECT @@ROWCOUNT AS [UpsertedRows];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
