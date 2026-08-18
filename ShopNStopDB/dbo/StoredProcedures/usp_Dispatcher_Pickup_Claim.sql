-- Dispatcher claims a packed item at the warehouse — first half of the
-- pickup flow. Moves OrderItems.OrderStatus 3 → 10 (PickedUp), creates a
-- DeliveryAssignment row (the dispatcher's "manifest entry"), writes a
-- PICKED_UP tracking entry, and reserves the item so no other dispatcher
-- can grab it.
--
-- The second half (10 → 4 Dispatched) happens via usp_Dispatcher_Pickup_Confirm
-- when the dispatcher leaves the warehouse with the parcel.
CREATE PROCEDURE [dbo].[usp_Dispatcher_Pickup_Claim]
    @OrderItemId  INT,
    @DispatcherId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @CurrentStatus  TINYINT;
        DECLARE @VariantId      INT;
        DECLARE @OrderId        INT;
        DECLARE @OrderNumber    NVARCHAR(50);
        DECLARE @ProductName    NVARCHAR(300);
        DECLARE @WarehouseId    INT;
        DECLARE @PaymentMode    TINYINT;
        DECLARE @PaymentStatus  TINYINT;
        DECLARE @TotalPrice     DECIMAL(18,2);

        -- Capture current state with a row lock so two dispatchers can't both grab it.
        SELECT @CurrentStatus = oi.[OrderStatus],
               @VariantId     = oi.[VariantId],
               @OrderId       = oi.[OrderId],
               @OrderNumber   = o.[OrderNumber],
               @ProductName   = oi.[ProductName],
               @PaymentMode   = o.[PaymentMode],
               @PaymentStatus = o.[PaymentStatus],
               @TotalPrice    = oi.[TotalPrice]
        FROM   [dbo].[OrderItems] oi WITH (UPDLOCK, ROWLOCK)
        INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
        WHERE  oi.[OrderItemId] = @OrderItemId
          AND  oi.[IsDeleted]   = 0;

        IF @CurrentStatus IS NULL
            THROW 50410, N'Order item not found.', 1;

        IF @CurrentStatus <> 3
            THROW 50411, N'Only Packed items can be picked up.', 1;

        -- Resolve the warehouse where this variant is stocked, restricted to
        -- the dispatcher's assigned warehouses.
        SELECT TOP 1 @WarehouseId = s.[WarehouseId]
        FROM   [dbo].[Stock] s
        INNER JOIN [dbo].[DispatcherWarehouseAssignments] dwa
            ON dwa.[WarehouseId] = s.[WarehouseId] AND dwa.[DispatcherId] = @DispatcherId
        WHERE  s.[VariantId] = @VariantId
        ORDER BY s.[OnHand] DESC, s.[WarehouseId];

        IF @WarehouseId IS NULL
            THROW 50412, N'You are not assigned to this item''s warehouse.', 1;

        -- COD amount snapshot for unpaid COD orders
        DECLARE @CodAmount DECIMAL(18,2) =
            CASE WHEN @PaymentMode = 1 AND @PaymentStatus <> 2 THEN @TotalPrice ELSE NULL END;

        BEGIN TRANSACTION;

            -- 1) Create the assignment row
            INSERT INTO [dbo].[DeliveryAssignments]
                ([OrderItemId], [DispatcherId], [WarehouseId], [Status],
                 [PickedUpAt], [CodAmount])
            VALUES
                (@OrderItemId, @DispatcherId, @WarehouseId, 10,
                 GETUTCDATE(), @CodAmount);

            DECLARE @AssignmentId INT = SCOPE_IDENTITY();

            -- 2) Flip the order item to PickedUp
            UPDATE [dbo].[OrderItems]
            SET    [OrderStatus] = 10,
                   [UpdatedAt]   = GETUTCDATE()
            WHERE  [OrderItemId] = @OrderItemId;

            -- 3) Tracking timeline entry
            INSERT INTO [dbo].[OrderTrackings]
                ([OrderId], [OrderItemId], [Status], [Note], [ChangedAt])
            VALUES
                (@OrderId, @OrderItemId, N'PICKED_UP',
                 N'"' + @ProductName + N'" picked up by dispatcher at the warehouse.',
                 GETUTCDATE());

        COMMIT TRANSACTION;

        SELECT @AssignmentId AS [AssignmentId],
               @OrderItemId  AS [OrderItemId],
               10            AS [OrderStatus],
               @OrderNumber  AS [OrderNumber],
               @WarehouseId  AS [WarehouseId];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
