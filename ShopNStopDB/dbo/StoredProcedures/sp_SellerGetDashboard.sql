CREATE PROCEDURE [dbo].[sp_SellerGetDashboard]
    @SellerId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalProducts INT = 0;
    DECLARE @ActiveProducts INT = 0;
    DECLARE @LowStockCount INT = 0;
    DECLARE @TotalOrders INT = 0;
    DECLARE @TotalSales DECIMAL(18,2) = 0;

    -- Total products for this seller
    SELECT @TotalProducts = COUNT(*)
    FROM [dbo].[Products]
    WHERE [SellerId] = @SellerId AND [IsDeleted] = 0;

    -- Active products (IsActive = 1 and ApprovalStatus = 2 for approved)
    SELECT @ActiveProducts = COUNT(*)
    FROM [dbo].[Products]
    WHERE [SellerId] = @SellerId AND [IsActive] = 1 AND [ApprovalStatus] = 2 AND [IsDeleted] = 0;

    -- Low stock products (any variant with StockQuantity < LowStockThreshold)
    SELECT @LowStockCount = COUNT(DISTINCT p.[ProductId])
    FROM [dbo].[Products] p
    INNER JOIN [dbo].[ProductVariants] pv ON pv.[ProductId] = p.[ProductId]
    WHERE p.[SellerId] = @SellerId
      AND p.[IsDeleted] = 0
      AND pv.[StockQuantity] < ISNULL(pv.[LowStockThreshold], 10)
      AND pv.[IsDeleted] = 0;

    -- Total orders from this seller's items
    SELECT @TotalOrders = COUNT(DISTINCT oi.[OrderId])
    FROM [dbo].[OrderItems] oi
    WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0;

    -- Total sales from this seller
    SELECT @TotalSales = ISNULL(SUM(oi.[UnitPrice] * oi.[Quantity]), 0)
    FROM [dbo].[OrderItems] oi
    WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0;

    -- Return dashboard metrics
    SELECT
        @TotalProducts AS [TotalProducts],
        @ActiveProducts AS [ActiveProducts],
        @LowStockCount AS [LowStockCount],
        @TotalOrders AS [TotalOrders],
        @TotalSales AS [TotalSales];
END;
GO
