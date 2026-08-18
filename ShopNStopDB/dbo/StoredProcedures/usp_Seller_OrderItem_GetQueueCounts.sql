CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_GetQueueCounts]
    @SellerId INT
AS
/*
  Returns the per-tab counts for the seller fulfilment queue in a single row.
  Bucket mapping mirrors usp_Seller_OrderItem_GetQueue:
    placed    → OrderStatus = 1
    confirmed → OrderStatus = 2
    rejected  → OrderStatus = 8
    fulfilled → OrderStatus IN (3, 4, 5)   -- Packed | Dispatched | Delivered
    all       → every non-deleted line for this seller (no status filter)

  One SELECT, one index scan on IX_OrderItems_SellerQueue. Designed to be
  polled every 30s by the UI without putting load on the box.
*/
BEGIN
    SET NOCOUNT ON;

    SELECT
        SUM(CASE WHEN oi.[OrderStatus] = 1              THEN 1 ELSE 0 END) AS [Placed],
        SUM(CASE WHEN oi.[OrderStatus] = 2              THEN 1 ELSE 0 END) AS [Confirmed],
        SUM(CASE WHEN oi.[OrderStatus] = 8              THEN 1 ELSE 0 END) AS [Rejected],
        SUM(CASE WHEN oi.[OrderStatus] IN (3, 4, 9, 5)  THEN 1 ELSE 0 END) AS [Fulfilled],
        COUNT(*)                                                            AS [All]
    FROM [dbo].[OrderItems] oi
    WHERE oi.[SellerId]  = @SellerId
      AND oi.[IsDeleted] = 0;
END;
GO
