CREATE PROCEDURE [dbo].[usp_Seller_Warehouse_GetAll]
    @SellerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [SellerWarehouseId], [SellerId], [WarehouseId], [Name], [ContactName], [ContactPhone],
           [AddressLine1], [AddressLine2], [City], [State], [Pincode], [IsPrimary],
           [CreatedAt], [UpdatedAt]
    FROM   [dbo].[SellerWarehouses]
    WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0
    ORDER  BY [IsPrimary] DESC, [CreatedAt] DESC;
END;
GO
