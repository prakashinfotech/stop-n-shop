CREATE PROCEDURE [dbo].[usp_Inventory_Warehouse_GetAll]
    @SellerId INT = NULL,           -- NULL = all (admin view)
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        w.[WarehouseId],
        w.[Code],
        w.[Name],
        w.[SellerId],
        s.[BusinessName]    AS [SellerName],
        w.[AddressLine1],
        w.[AddressLine2],
        w.[City],
        w.[State],
        w.[PinCode],
        w.[Country],
        w.[IsActive],
        w.[CreatedAt]
    FROM [dbo].[Warehouses] w
    LEFT JOIN [dbo].[Sellers] s ON s.[SellerId] = w.[SellerId]
    WHERE w.[IsDeleted] = 0
      AND (@SellerId IS NULL OR w.[SellerId] = @SellerId OR w.[SellerId] IS NULL)
      AND (@IncludeInactive = 1 OR w.[IsActive] = 1)
    ORDER BY w.[SellerId], w.[Name];
END;
GO
