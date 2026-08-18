-- Pickup queue for the dispatcher portal.
--
-- Returns OrderItems that are:
--   • Currently Packed (status 3) — no dispatcher has claimed them yet, OR
--   • Already claimed by THIS dispatcher (status 10) — so they show as
--     "ready to confirm pickup" in the same list
-- AND located at a warehouse the dispatcher is assigned to.
--
-- Warehouse for an item is resolved via the Stock row (uniquely-keyed by
-- variant+warehouse). For demo seller orders there's exactly one Stock row
-- per variant, so this is a clean 1:1 join. Multi-warehouse scenarios pick
-- the row with the highest OnHand (good enough for the queue display).
CREATE PROCEDURE [dbo].[usp_Dispatcher_Pickup_GetQueue]
    @DispatcherId INT,
    @Page         INT = 1,
    @PageSize     INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    ;WITH MyWarehouses AS (
        SELECT [WarehouseId]
        FROM   [dbo].[DispatcherWarehouseAssignments]
        WHERE  [DispatcherId] = @DispatcherId
    ),
    -- One warehouse per variant (highest stock row).
    VariantWarehouse AS (
        SELECT s.[VariantId], s.[WarehouseId],
               ROW_NUMBER() OVER (PARTITION BY s.[VariantId] ORDER BY s.[OnHand] DESC, s.[WarehouseId]) AS rn
        FROM   [dbo].[Stock] s
        INNER JOIN MyWarehouses mw ON mw.[WarehouseId] = s.[WarehouseId]
    ),
    -- Latest assignment per item (so we know who claimed it, if anyone).
    LatestAssignment AS (
        SELECT da.[OrderItemId], da.[AssignmentId], da.[DispatcherId], da.[Status],
               ROW_NUMBER() OVER (PARTITION BY da.[OrderItemId] ORDER BY da.[AssignedAt] DESC) AS rn
        FROM   [dbo].[DeliveryAssignments] da
    )
    SELECT
        oi.[OrderItemId],
        oi.[OrderId],
        o.[OrderNumber],
        oi.[ProductName],
        oi.[VariantSnapshot],
        oi.[Quantity],
        oi.[TotalPrice],
        oi.[OrderStatus],
        oi.[CreatedAt]                       AS [OrderItemCreatedAt],
        vw.[WarehouseId],
        w.[Code]                             AS [WarehouseCode],
        w.[Name]                             AS [WarehouseName],
        w.[City]                             AS [WarehouseCity],
        o.[PaymentMode],
        o.[PaymentStatus],
        CASE WHEN o.[PaymentMode] = 1 AND o.[PaymentStatus] <> 2
             THEN oi.[TotalPrice] ELSE NULL END AS [CodAmount],
        u.[FirstName] + N' ' + ISNULL(u.[LastName], N'') AS [BuyerName],
        u.[Mobile]                                       AS [BuyerMobile],
        ua.[AddressLine1]                                AS [BuyerAddressLine1],
        ua.[City]                                        AS [BuyerCity],
        ua.[State]                                       AS [BuyerState],
        ua.[PinCode]                                     AS [BuyerPincode],
        la.[AssignmentId],                                 -- non-null if already claimed
        la.[Status]                          AS [AssignmentStatus],
        COUNT(*) OVER ()                                 AS [TotalCount]
    FROM   [dbo].[OrderItems]               oi
    INNER JOIN [dbo].[Orders]                o  ON o.[OrderId]  = oi.[OrderId]
    INNER JOIN [dbo].[Users]                 u  ON u.[UserId]   = o.[UserId]
    LEFT  JOIN [dbo].[UserAddresses]         ua ON ua.[AddressId] = o.[ShippingAddressId]
    INNER JOIN VariantWarehouse              vw ON vw.[VariantId] = oi.[VariantId] AND vw.rn = 1
    INNER JOIN [dbo].[Warehouses]            w  ON w.[WarehouseId] = vw.[WarehouseId]
    LEFT  JOIN LatestAssignment              la ON la.[OrderItemId] = oi.[OrderItemId] AND la.rn = 1
    WHERE  oi.[IsDeleted] = 0
      AND  o.[IsDeleted]  = 0
      -- show unclaimed Packed items, or items already claimed BY THIS dispatcher
      AND  (
            (oi.[OrderStatus] = 3 AND la.[AssignmentId] IS NULL)
         OR (oi.[OrderStatus] = 10 AND la.[DispatcherId] = @DispatcherId)
           )
    ORDER BY
        -- Already-claimed items first (so dispatcher sees what to do next)
        CASE WHEN la.[DispatcherId] = @DispatcherId THEN 0 ELSE 1 END,
        oi.[CreatedAt] ASC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
