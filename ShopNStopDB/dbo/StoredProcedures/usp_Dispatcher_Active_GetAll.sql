-- All currently in-flight assignments for this dispatcher — anything that's
-- claimed but not yet terminal. Drives the "Active deliveries" tab in the
-- dispatcher portal.
--
-- Status buckets returned (mirror OrderItems + DeliveryAssignments):
--   10 PickedUp        — at warehouse, not yet left
--   4  Dispatched      — in transit hub-to-hub
--   9  OutForDelivery  — with last-mile courier (this dispatcher)
--   11 DeliveryFailed  — failed attempt, awaiting retry
-- Excludes terminal states: 5 Delivered, 12 RTO.
CREATE PROCEDURE [dbo].[usp_Dispatcher_Active_GetAll]
    @DispatcherId INT,
    @Page         INT = 1,
    @PageSize     INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        da.[AssignmentId],
        da.[Status]                          AS [AssignmentStatus],
        da.[AssignedAt],
        da.[PickedUpAt],
        da.[OutForDeliveryAt],
        da.[AttemptNumber],
        da.[CodAmount],
        oi.[OrderItemId],
        oi.[OrderId],
        o.[OrderNumber],
        oi.[ProductName],
        oi.[VariantSnapshot],
        oi.[Quantity],
        oi.[TotalPrice],
        oi.[OrderStatus],
        w.[Code]                             AS [WarehouseCode],
        w.[Name]                             AS [WarehouseName],
        u.[FirstName] + N' ' + ISNULL(u.[LastName], N'') AS [BuyerName],
        u.[Mobile]                                       AS [BuyerMobile],
        ua.[AddressLine1]                                AS [BuyerAddressLine1],
        ua.[City]                                        AS [BuyerCity],
        ua.[State]                                       AS [BuyerState],
        ua.[PinCode]                                     AS [BuyerPincode],
        o.[PaymentMode],
        o.[PaymentStatus],
        COUNT(*) OVER()                      AS [TotalCount]
    FROM   [dbo].[DeliveryAssignments] da
    INNER JOIN [dbo].[OrderItems]     oi ON oi.[OrderItemId]   = da.[OrderItemId]
    INNER JOIN [dbo].[Orders]          o  ON o.[OrderId]       = oi.[OrderId]
    INNER JOIN [dbo].[Users]           u  ON u.[UserId]        = o.[UserId]
    LEFT  JOIN [dbo].[UserAddresses]   ua ON ua.[AddressId]    = o.[ShippingAddressId]
    INNER JOIN [dbo].[Warehouses]      w  ON w.[WarehouseId]   = da.[WarehouseId]
    WHERE  da.[DispatcherId] = @DispatcherId
      AND  da.[Status] IN (10, 4, 9, 11)
      AND  oi.[IsDeleted]    = 0
    ORDER BY
        -- OFD first (needs immediate action), then by claim age
        CASE da.[Status] WHEN 9 THEN 0 WHEN 11 THEN 1 WHEN 4 THEN 2 ELSE 3 END,
        da.[AssignedAt] DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
