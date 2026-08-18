/*
 * 2026-05-26 — Order item status progression
 *
 * Adds status code 9 = "Out for Delivery" to OrderItems.OrderStatus, plus a
 * forward-only transition SP that the seller's fulfilment console uses to
 * walk a confirmed item through:
 *
 *      2 Confirmed → 3 Packed → 4 Dispatched → 9 OutForDelivery → 5 Delivered
 *
 * Also refreshes the queue + counts SPs so they treat 9 as part of the
 * fulfilled bucket alongside 3/4/5.
 *
 * Apply:
 *   docker cp db/patches/2026_05_26_order_status_progression.sql stopnshop-db:/tmp/p.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C -d ShopNShop_db -b -I -i /tmp/p.sql
 */

SET NOCOUNT ON;

-- 1. Extend OrderItems CHECK constraint to allow status 9.
PRINT '[patch] Updating CK_OrderItems_OrderStatus to allow status 9...';
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_OrderItems_OrderStatus'
      AND parent_object_id = OBJECT_ID('dbo.OrderItems')
)
    ALTER TABLE [dbo].[OrderItems] DROP CONSTRAINT [CK_OrderItems_OrderStatus];

ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [CK_OrderItems_OrderStatus]
    CHECK ([OrderStatus] IN (1, 2, 3, 4, 5, 6, 7, 8, 9));
GO

-- 2. Forward-only transition SP.
PRINT '[patch] Refreshing usp_Seller_OrderItem_UpdateStatus...';
IF OBJECT_ID(N'[dbo].[usp_Seller_OrderItem_UpdateStatus]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Seller_OrderItem_UpdateStatus];
GO

CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_UpdateStatus]
    @OrderItemId  INT,
    @SellerId     INT,
    @NewStatus    TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @CurrentStatus TINYINT;
        DECLARE @OrderId       INT;
        DECLARE @OrderNumber   NVARCHAR(50);
        DECLARE @BuyerId       INT;
        DECLARE @ProductName   NVARCHAR(300);

        SELECT @CurrentStatus = oi.[OrderStatus],
               @OrderId       = o.[OrderId],
               @OrderNumber   = o.[OrderNumber],
               @BuyerId       = o.[UserId],
               @ProductName   = oi.[ProductName]
        FROM   [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
        WHERE  oi.[OrderItemId] = @OrderItemId
          AND  oi.[SellerId]    = @SellerId
          AND  oi.[IsDeleted]   = 0;

        IF @CurrentStatus IS NULL
            THROW 50305, N'Order item not found or not owned by seller.', 1;

        DECLARE @Allowed BIT = 0;
        IF (@CurrentStatus = 2 AND @NewStatus = 3) SET @Allowed = 1;
        IF (@CurrentStatus = 3 AND @NewStatus = 4) SET @Allowed = 1;
        IF (@CurrentStatus = 4 AND @NewStatus = 9) SET @Allowed = 1;
        IF (@CurrentStatus = 9 AND @NewStatus = 5) SET @Allowed = 1;

        IF @Allowed = 0
            THROW 50306, N'Invalid transition. Items move Confirmed → Packed → Dispatched → Out for Delivery → Delivered, one step at a time.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[OrderItems]
            SET    [OrderStatus] = @NewStatus,
                   [UpdatedAt]   = GETUTCDATE()
            WHERE  [OrderItemId] = @OrderItemId;

            IF @NewStatus = 5
            BEGIN
                UPDATE [dbo].[Orders]
                SET    [DeliveredAt] = COALESCE([DeliveredAt], GETUTCDATE()),
                       [UpdatedAt]   = GETUTCDATE()
                WHERE  [OrderId] = @OrderId;
            END

            DECLARE @StatusLabel NVARCHAR(40) =
                CASE @NewStatus
                    WHEN 3 THEN N'Packed'
                    WHEN 4 THEN N'Dispatched'
                    WHEN 9 THEN N'Out for Delivery'
                    WHEN 5 THEN N'Delivered'
                END;

            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerId,
                 N'Order Update: ' + @StatusLabel,
                 N'"' + @ProductName + N'" in order ' + @OrderNumber + N' is now ' + @StatusLabel + N'.',
                 2, N'Order', @OrderId, 1);

        COMMIT TRANSACTION;

        SELECT @OrderItemId AS [OrderItemId],
               @NewStatus   AS [OrderStatus],
               @OrderNumber AS [OrderNumber];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 3. Queue SP — include 9 in 'fulfilled' bucket.
PRINT '[patch] Refreshing usp_Seller_OrderItem_GetQueue...';
IF OBJECT_ID(N'[dbo].[usp_Seller_OrderItem_GetQueue]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Seller_OrderItem_GetQueue];
GO

CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_GetQueue]
    @SellerId    INT,
    @StatusFilter NVARCHAR(20) = N'all',
    @Page         INT = 1,
    @PageSize     INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@Page - 1) * @PageSize;

        SELECT
            oi.[OrderItemId],
            oi.[OrderId],
            o.[OrderNumber],
            oi.[ProductId],
            oi.[VariantId],
            oi.[ProductName],
            oi.[VariantSnapshot],
            oi.[Quantity],
            oi.[UnitPrice],
            oi.[TotalPrice],
            oi.[OrderStatus],
            oi.[CreatedAt],
            oi.[ConfirmedAt],
            oi.[RejectedAt],
            oi.[RejectionReason],
            o.[PaymentMode],
            o.[PaymentStatus],
            u.[FirstName] + N' ' + ISNULL(u.[LastName], N'') AS [BuyerName],
            u.[Mobile] AS [BuyerMobile],
            ua.[City]    AS [BuyerCity],
            ua.[PinCode] AS [BuyerPincode],
            (SELECT TOP 1 pi.[ImageUrl]
                FROM   [dbo].[ProductImages] pi
                WHERE  pi.[ProductId] = oi.[ProductId]
                  AND  pi.[IsDeleted] = 0
                ORDER BY pi.[IsPrimary] DESC, pi.[SortOrder] ASC) AS [PrimaryImageUrl],
            COUNT(*) OVER() AS [TotalCount]
        FROM   [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders]        o  ON o.[OrderId] = oi.[OrderId]
        INNER JOIN [dbo].[Users]         u  ON u.[UserId]  = o.[UserId]
        LEFT  JOIN [dbo].[UserAddresses] ua ON ua.[AddressId] = o.[ShippingAddressId]
        WHERE  oi.[SellerId]  = @SellerId
          AND  oi.[IsDeleted] = 0
          AND (
                @StatusFilter = N'all'
             OR (@StatusFilter = N'placed'    AND oi.[OrderStatus] = 1)
             OR (@StatusFilter = N'confirmed' AND oi.[OrderStatus] = 2)
             OR (@StatusFilter = N'rejected'  AND oi.[OrderStatus] = 8)
             OR (@StatusFilter = N'fulfilled' AND oi.[OrderStatus] IN (3, 4, 9, 5))
              )
        ORDER BY
            CASE oi.[OrderStatus] WHEN 1 THEN 0 ELSE 1 END,
            oi.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

-- 4. Counts SP — include 9 in 'fulfilled' bucket.
PRINT '[patch] Refreshing usp_Seller_OrderItem_GetQueueCounts...';
IF OBJECT_ID(N'[dbo].[usp_Seller_OrderItem_GetQueueCounts]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Seller_OrderItem_GetQueueCounts];
GO

CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_GetQueueCounts]
    @SellerId INT
AS
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

PRINT '[patch] Done.';
GO
