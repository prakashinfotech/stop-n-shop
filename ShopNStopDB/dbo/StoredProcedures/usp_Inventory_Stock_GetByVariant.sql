CREATE PROCEDURE [dbo].[usp_Inventory_Stock_GetByVariant]
    @VariantId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.[StockId],
        s.[VariantId],
        s.[WarehouseId],
        w.[Code]      AS [WarehouseCode],
        w.[Name]      AS [WarehouseName],
        s.[OnHand],
        s.[Reserved],
        (s.[OnHand] - s.[Reserved]) AS [Available],
        s.[UpdatedAt]
    FROM [dbo].[Stock] s
    INNER JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = s.[WarehouseId]
    WHERE s.[VariantId] = @VariantId
      AND w.[IsDeleted] = 0
    ORDER BY w.[Name];
END;
GO
