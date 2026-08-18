-- Returns variants whose total available (across warehouses) is at or below LowStockThreshold.
-- Filters: @SellerId scopes to a seller; NULL = platform-wide (admin view).
CREATE PROCEDURE [dbo].[usp_Inventory_LowStock_Alerts]
    @SellerId    INT = NULL,
    @WarehouseId INT = NULL,
    @Page        INT = 1,
    @PageSize    INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    ;WITH StockTotals AS (
        SELECT
            s.[VariantId],
            SUM(s.[OnHand])                    AS [TotalOnHand],
            SUM(s.[Reserved])                  AS [TotalReserved],
            SUM(s.[OnHand] - s.[Reserved])     AS [TotalAvailable]
        FROM [dbo].[Stock] s
        INNER JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = s.[WarehouseId]
        WHERE w.[IsDeleted] = 0 AND w.[IsActive] = 1
          AND (@WarehouseId IS NULL OR s.[WarehouseId] = @WarehouseId)
        GROUP BY s.[VariantId]
    ),
    Filtered AS (
        SELECT
            pv.[VariantId],
            pv.[ProductId],
            pv.[VariantSku],
            pv.[Color],
            pv.[Size],
            pv.[LowStockThreshold],
            p.[ProductName],
            p.[SellerId],
            sl.[BusinessName] AS [SellerName],
            ISNULL(t.[TotalOnHand],    0) AS [TotalOnHand],
            ISNULL(t.[TotalReserved],  0) AS [TotalReserved],
            ISNULL(t.[TotalAvailable], 0) AS [TotalAvailable]
        FROM [dbo].[ProductVariants] pv
        INNER JOIN [dbo].[Products] p ON p.[ProductId] = pv.[ProductId]
        LEFT  JOIN [dbo].[Sellers]  sl ON sl.[SellerId] = p.[SellerId]
        LEFT  JOIN StockTotals      t  ON t.[VariantId] = pv.[VariantId]
        WHERE pv.[IsDeleted] = 0
          AND pv.[IsActive]  = 1
          AND p.[IsDeleted]  = 0
          AND (@SellerId IS NULL OR p.[SellerId] = @SellerId)
          AND ISNULL(t.[TotalAvailable], 0) <= pv.[LowStockThreshold]
    )
    SELECT *
    FROM Filtered
    ORDER BY [TotalAvailable] ASC, [VariantId] ASC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    SELECT COUNT(1) AS [TotalCount]
    FROM [dbo].[ProductVariants] pv
    INNER JOIN [dbo].[Products] p ON p.[ProductId] = pv.[ProductId]
    LEFT JOIN (
        SELECT [VariantId], SUM([OnHand] - [Reserved]) AS [TotalAvailable]
        FROM [dbo].[Stock] s
        INNER JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = s.[WarehouseId]
        WHERE w.[IsDeleted] = 0 AND w.[IsActive] = 1
          AND (@WarehouseId IS NULL OR s.[WarehouseId] = @WarehouseId)
        GROUP BY [VariantId]
    ) t ON t.[VariantId] = pv.[VariantId]
    WHERE pv.[IsDeleted] = 0
      AND pv.[IsActive]  = 1
      AND p.[IsDeleted]  = 0
      AND (@SellerId IS NULL OR p.[SellerId] = @SellerId)
      AND ISNULL(t.[TotalAvailable], 0) <= pv.[LowStockThreshold];
END;
GO
