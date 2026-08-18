-- SKU × Warehouse matrix for the admin/seller inventory page.
-- Returns one row per (Variant, Warehouse) along with totals.
CREATE PROCEDURE [dbo].[usp_Inventory_StockMatrix_Get]
    @SellerId    INT = NULL,
    @WarehouseId INT = NULL,
    @Search      NVARCHAR(200) = NULL,
    @Page        INT = 1,
    @PageSize    INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    ;WITH Filtered AS (
        SELECT
            pv.[VariantId],
            pv.[ProductId],
            pv.[VariantSku],
            pv.[Color],
            pv.[Size],
            pv.[LowStockThreshold],
            p.[ProductName],
            p.[SellerId],
            sl.[BusinessName] AS [SellerName]
        FROM [dbo].[ProductVariants] pv
        INNER JOIN [dbo].[Products] p  ON p.[ProductId] = pv.[ProductId]
        LEFT  JOIN [dbo].[Sellers]  sl ON sl.[SellerId] = p.[SellerId]
        WHERE pv.[IsDeleted] = 0
          AND pv.[IsActive]  = 1
          AND p.[IsDeleted]  = 0
          AND (@SellerId IS NULL OR p.[SellerId] = @SellerId)
          AND (@Search IS NULL
                OR pv.[VariantSku] LIKE N'%' + @Search + N'%'
                OR p.[ProductName] LIKE N'%' + @Search + N'%')
    ),
    PageRows AS (
        SELECT *
        FROM Filtered
        ORDER BY [ProductName], [VariantSku]
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY
    )
    SELECT
        pr.[VariantId],
        pr.[ProductId],
        pr.[VariantSku],
        pr.[ProductName],
        pr.[Color],
        pr.[Size],
        pr.[LowStockThreshold],
        pr.[SellerId],
        pr.[SellerName],
        s.[WarehouseId],
        w.[Code]      AS [WarehouseCode],
        w.[Name]      AS [WarehouseName],
        ISNULL(s.[OnHand],   0)                 AS [OnHand],
        ISNULL(s.[Reserved], 0)                 AS [Reserved],
        ISNULL(s.[OnHand], 0) - ISNULL(s.[Reserved], 0) AS [Available]
    FROM PageRows pr
    LEFT JOIN [dbo].[Stock]      s ON s.[VariantId]   = pr.[VariantId]
                                  AND (@WarehouseId IS NULL OR s.[WarehouseId] = @WarehouseId)
    LEFT JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = s.[WarehouseId] AND w.[IsDeleted] = 0
    ORDER BY pr.[ProductName], pr.[VariantSku], w.[Name];

    SELECT COUNT(1) AS [TotalCount] FROM (
        SELECT pv.[VariantId]
        FROM [dbo].[ProductVariants] pv
        INNER JOIN [dbo].[Products] p ON p.[ProductId] = pv.[ProductId]
        WHERE pv.[IsDeleted] = 0
          AND pv.[IsActive]  = 1
          AND p.[IsDeleted]  = 0
          AND (@SellerId IS NULL OR p.[SellerId] = @SellerId)
          AND (@Search IS NULL
                OR pv.[VariantSku] LIKE N'%' + @Search + N'%'
                OR p.[ProductName] LIKE N'%' + @Search + N'%')
    ) f;
END;
GO
