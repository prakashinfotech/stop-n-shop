CREATE PROCEDURE [dbo].[usp_Inventory_Movement_GetByVariant]
    @VariantId   INT,
    @WarehouseId INT = NULL,
    @Page        INT = 1,
    @PageSize    INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        m.[MovementId],
        m.[VariantId],
        m.[WarehouseId],
        w.[Code]   AS [WarehouseCode],
        w.[Name]   AS [WarehouseName],
        m.[MovementType],
        m.[QuantityDelta],
        m.[ReservedDelta],
        m.[Reason],
        m.[ReferenceType],
        m.[ReferenceId],
        m.[ChangedBy],
        u.[Email]  AS [ChangedByEmail],
        m.[ChangedAt]
    FROM   [dbo].[StockMovements] m
    INNER JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = m.[WarehouseId]
    LEFT  JOIN [dbo].[Users]      u ON u.[UserId]      = m.[ChangedBy]
    WHERE  m.[VariantId] = @VariantId
      AND  (@WarehouseId IS NULL OR m.[WarehouseId] = @WarehouseId)
    ORDER BY m.[ChangedAt] DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    SELECT COUNT(1) AS [TotalCount]
    FROM   [dbo].[StockMovements] m
    WHERE  m.[VariantId] = @VariantId
      AND  (@WarehouseId IS NULL OR m.[WarehouseId] = @WarehouseId);
END;
GO
