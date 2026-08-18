CREATE PROCEDURE [dbo].[usp_Seller_Settlement_DueSellers]
    @CutoffDate DATE
AS
/*
  Returns sellers with at least one delivered, unsettled order-item whose DeliveredAt <= @CutoffDate.
  Used by SellerSettlementWorker to decide which sellers to settle in the nightly sweep.
*/
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT oi.[SellerId]
    FROM   [dbo].[OrderItems] oi
    INNER  JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
    LEFT   JOIN [dbo].[SellerSettlementLines] ssl ON ssl.[OrderItemId] = oi.[OrderItemId]
    WHERE  oi.[IsDeleted]   = 0
       AND oi.[IsReturned]  = 0
       AND o.[IsDeleted]    = 0
       AND o.[OrderStatus]  = 5
       AND CAST(o.[DeliveredAt] AS DATE) <= @CutoffDate
       AND ssl.[SettlementLineId] IS NULL;
END;
GO
