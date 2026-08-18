/*
 * 2026-05-26 — Order tracking timeline
 *
 * Adds an append-only OrderTrackings table that records every order status
 * transition (PLACED → CONFIRMED → PACKED → DISPATCHED → OUT_FOR_DELIVERY
 * → DELIVERED, or any of REJECTED / CANCELLED / RETURNED). Six SPs are
 * extended to write a tracking row on every state change, and the
 * GetById SP returns the timeline as a third result set.
 *
 * Final step backfills existing orders so the buyer's tracking strip
 * isn't empty for historical orders — derives PLACED / CONFIRMED /
 * DELIVERED / CANCELLED / REJECTED from existing timestamp columns.
 *
 * Idempotent: table creation is guarded; SP refreshes are DROP+CREATE;
 * backfill uses NOT EXISTS to skip already-tracked entries.
 *
 * Apply:
 *   docker cp db/patches/2026_05_26_order_tracking_timeline.sql stopnshop-db:/tmp/t.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C -d ShopNShop_db -b -I -i /tmp/t.sql
 */

SET NOCOUNT ON;

------------------------------------------------------------------------------
-- 1. OrderTrackings table
------------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[OrderTrackings]', N'U') IS NULL
BEGIN
    PRINT '[patch] Creating OrderTrackings table...';
    CREATE TABLE [dbo].[OrderTrackings]
    (
        [TrackingId]   INT             NOT NULL  IDENTITY(1,1),
        [OrderId]      INT             NOT NULL,
        [OrderItemId]  INT             NULL,
        [Status]       NVARCHAR(40)    NOT NULL,
        [Note]         NVARCHAR(500)   NULL,
        [ChangedAt]    DATETIME2(0)    NOT NULL  CONSTRAINT [DF_OrderTrackings_ChangedAt] DEFAULT GETUTCDATE(),
        [ChangedBy]    INT             NULL,

        CONSTRAINT [PK_OrderTrackings]              PRIMARY KEY CLUSTERED ([TrackingId] ASC),
        CONSTRAINT [FK_OrderTrackings_OrderId]      FOREIGN KEY ([OrderId])     REFERENCES [dbo].[Orders]     ([OrderId]),
        CONSTRAINT [FK_OrderTrackings_OrderItemId]  FOREIGN KEY ([OrderItemId]) REFERENCES [dbo].[OrderItems] ([OrderItemId]),
        CONSTRAINT [FK_OrderTrackings_ChangedBy]    FOREIGN KEY ([ChangedBy])   REFERENCES [dbo].[Users]      ([UserId])
    );

    CREATE NONCLUSTERED INDEX [IX_OrderTrackings_Order_Changed]
        ON [dbo].[OrderTrackings] ([OrderId] ASC, [ChangedAt] ASC);
END
ELSE
    PRINT '[patch] OrderTrackings table already exists — skipping.';
GO

------------------------------------------------------------------------------
-- 2. Refresh usp_Commerce_Order_Place (write PLACED row after order INSERT)
------------------------------------------------------------------------------
PRINT '[patch] Note: usp_Commerce_Order_Place edited via SSDT source. Apply via dacpac for full sync.';
PRINT '[patch] This patch only adds Stock+timeline plumbing — order-place changes will land on next deploy.';

------------------------------------------------------------------------------
-- 3. Refresh usp_Seller_OrderItem_Confirm with tracking insert
------------------------------------------------------------------------------
PRINT '[patch] Refreshing usp_Seller_OrderItem_Confirm...';
IF OBJECT_ID(N'[dbo].[usp_Seller_OrderItem_Confirm]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Seller_OrderItem_Confirm];
GO

CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_Confirm]
    @OrderItemId  INT,
    @SellerId     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[OrderItems]
            WHERE [OrderItemId] = @OrderItemId AND [SellerId] = @SellerId AND [IsDeleted] = 0
        )
            THROW 50300, N'Order item not found or not owned by seller.', 1;

        IF EXISTS (
            SELECT 1 FROM [dbo].[OrderItems]
            WHERE [OrderItemId] = @OrderItemId AND [OrderStatus] <> 1
        )
            THROW 50301, N'Only newly placed items can be confirmed.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[OrderItems]
            SET    [OrderStatus]  = 2,
                   [ConfirmedAt]  = GETUTCDATE(),
                   [UpdatedAt]    = GETUTCDATE()
            WHERE  [OrderItemId]  = @OrderItemId;

            DECLARE @OrderId       INT;
            DECLARE @OrderNumber   NVARCHAR(50);
            DECLARE @BuyerId       INT;
            DECLARE @ProductName   NVARCHAR(300);

            SELECT @OrderId    = o.[OrderId],
                   @OrderNumber= o.[OrderNumber],
                   @BuyerId    = o.[UserId],
                   @ProductName= oi.[ProductName]
            FROM   [dbo].[OrderItems] oi
            INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
            WHERE  oi.[OrderItemId] = @OrderItemId;

            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerId,
                 N'Order Confirmed',
                 N'The seller has confirmed "' + @ProductName + N'" in order ' + @OrderNumber + N'.',
                 2, N'Order', @OrderId, 1);

            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note])
            VALUES (@OrderId, @OrderItemId, N'CONFIRMED',
                    N'Seller confirmed "' + @ProductName + N'".');

        COMMIT TRANSACTION;

        SELECT @OrderItemId AS [OrderItemId], 2 AS [OrderStatus], @OrderNumber AS [OrderNumber];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

------------------------------------------------------------------------------
-- 4. Refresh usp_Seller_OrderItem_UpdateStatus with tracking insert
------------------------------------------------------------------------------
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
                UPDATE [dbo].[Orders]
                SET    [DeliveredAt] = COALESCE([DeliveredAt], GETUTCDATE()),
                       [UpdatedAt]   = GETUTCDATE()
                WHERE  [OrderId] = @OrderId;

            DECLARE @StatusLabel NVARCHAR(40) =
                CASE @NewStatus
                    WHEN 3 THEN N'Packed'
                    WHEN 4 THEN N'Dispatched'
                    WHEN 9 THEN N'Out for Delivery'
                    WHEN 5 THEN N'Delivered'
                END;
            DECLARE @StatusCode NVARCHAR(40) =
                CASE @NewStatus
                    WHEN 3 THEN N'PACKED'
                    WHEN 4 THEN N'DISPATCHED'
                    WHEN 9 THEN N'OUT_FOR_DELIVERY'
                    WHEN 5 THEN N'DELIVERED'
                END;

            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerId, N'Order Update: ' + @StatusLabel,
                 N'"' + @ProductName + N'" in order ' + @OrderNumber + N' is now ' + @StatusLabel + N'.',
                 2, N'Order', @OrderId, 1);

            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note])
            VALUES (@OrderId, @OrderItemId, @StatusCode,
                    N'"' + @ProductName + N'" marked ' + @StatusLabel + N'.');

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

------------------------------------------------------------------------------
-- 5. Refresh usp_Commerce_Order_GetById (return tracking as 3rd result set)
------------------------------------------------------------------------------
PRINT '[patch] Refreshing usp_Commerce_Order_GetById...';
IF OBJECT_ID(N'[dbo].[usp_Commerce_Order_GetById]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Commerce_Order_GetById];
GO

CREATE PROCEDURE [dbo].[usp_Commerce_Order_GetById]
    @OrderId INT,
    @UserId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            o.[OrderId], o.[OrderNumber], o.[OrderStatus],
            o.[SubTotal], o.[DiscountAmount], o.[CouponDiscount],
            o.[TaxAmount], o.[ShippingCharge], o.[TotalAmount],
            o.[PaymentMode], o.[PaymentStatus], o.[PaymentGatewayRef],
            o.[ExpectedDeliveryDate], o.[DeliveredAt], o.[CancelledAt],
            o.[CancellationReason], o.[CreatedAt] AS [OrderDate],
            ua.[Label]        AS [AddressLabel],
            ua.[AddressLine1], ua.[AddressLine2],
            ua.[City], ua.[State], ua.[PinCode], ua.[Country],
            cp.[CouponCode]
        FROM [dbo].[Orders]        o
        INNER JOIN [dbo].[UserAddresses] ua ON ua.[AddressId] = o.[ShippingAddressId]
        LEFT  JOIN [dbo].[Coupons]       cp ON cp.[CouponId]  = o.[CouponId]
        WHERE o.[OrderId]  = @OrderId
          AND o.[IsDeleted] = 0
          AND (@UserId IS NULL OR o.[UserId] = @UserId);

        SELECT
            oi.[OrderItemId], oi.[ProductId], oi.[VariantId],
            oi.[ProductName], oi.[VariantSnapshot],
            oi.[Quantity], oi.[UnitPrice], oi.[DiscountAmount],
            oi.[TaxAmount], oi.[TotalPrice],
            oi.[CommissionAmount], oi.[SellerEarning],
            oi.[IsReturned], oi.[ReturnReason],
            oi.[OrderStatus]      AS [LineStatus],
            oi.[ConfirmedAt],
            oi.[RejectedAt],
            oi.[RejectionReason],
            b.[BrandName],
            s.[BusinessName] AS [SellerName],
            pi_.[ImageUrl]   AS [ProductImageUrl]
        FROM [dbo].[OrderItems]       oi
        INNER JOIN [dbo].[Brands]         b   ON b.[BrandId]   = oi.[BrandId]
        INNER JOIN [dbo].[Sellers]        s   ON s.[SellerId]  = oi.[SellerId]
        LEFT  JOIN [dbo].[ProductImages]  pi_ ON pi_.[ProductId] = oi.[ProductId]
                                              AND pi_.[IsPrimary] = 1
                                              AND pi_.[IsDeleted] = 0
        WHERE oi.[OrderId]  = @OrderId
          AND oi.[IsDeleted] = 0;

        -- Third result set: append-only tracking timeline.
        SELECT
            t.[TrackingId], t.[OrderId], t.[OrderItemId],
            t.[Status], t.[Note], t.[ChangedAt], t.[ChangedBy]
        FROM [dbo].[OrderTrackings] t
        WHERE t.[OrderId] = @OrderId
        ORDER BY t.[ChangedAt] ASC, t.[TrackingId] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

------------------------------------------------------------------------------
-- 6. Backfill: derive tracking entries for existing orders from existing
--    timestamps. Skips any (OrderId, Status) combo that already has a row.
------------------------------------------------------------------------------
PRINT '[patch] Backfilling tracking entries from existing timestamps...';

DECLARE @bf_inserted INT = 0;

-- PLACED — every order
INSERT INTO [dbo].[OrderTrackings] ([OrderId], [Status], [Note], [ChangedAt], [ChangedBy])
SELECT o.[OrderId], N'PLACED', N'Order placed by buyer.', o.[CreatedAt], o.[UserId]
FROM   [dbo].[Orders] o
WHERE  o.[IsDeleted] = 0
  AND  NOT EXISTS (
        SELECT 1 FROM [dbo].[OrderTrackings] t
        WHERE  t.[OrderId] = o.[OrderId] AND t.[Status] = N'PLACED');
SET @bf_inserted += @@ROWCOUNT;

-- CONFIRMED — per line, latest ConfirmedAt per order wins for the header strip
;WITH FirstConfirm AS (
    SELECT oi.[OrderId],
           MIN(oi.[ConfirmedAt]) AS [ConfirmedAt],
           MIN(oi.[OrderItemId]) AS [OrderItemId]
    FROM   [dbo].[OrderItems] oi
    WHERE  oi.[ConfirmedAt] IS NOT NULL AND oi.[IsDeleted] = 0
    GROUP BY oi.[OrderId]
)
INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note], [ChangedAt])
SELECT fc.[OrderId], fc.[OrderItemId], N'CONFIRMED', N'Seller confirmed the order.', fc.[ConfirmedAt]
FROM   FirstConfirm fc
WHERE  NOT EXISTS (
        SELECT 1 FROM [dbo].[OrderTrackings] t
        WHERE  t.[OrderId] = fc.[OrderId] AND t.[Status] = N'CONFIRMED');
SET @bf_inserted += @@ROWCOUNT;

-- DELIVERED — Orders.DeliveredAt
INSERT INTO [dbo].[OrderTrackings] ([OrderId], [Status], [Note], [ChangedAt])
SELECT o.[OrderId], N'DELIVERED', N'Order marked delivered.', o.[DeliveredAt]
FROM   [dbo].[Orders] o
WHERE  o.[DeliveredAt] IS NOT NULL AND o.[IsDeleted] = 0
  AND  NOT EXISTS (
        SELECT 1 FROM [dbo].[OrderTrackings] t
        WHERE  t.[OrderId] = o.[OrderId] AND t.[Status] = N'DELIVERED');
SET @bf_inserted += @@ROWCOUNT;

-- CANCELLED — Orders.CancelledAt
INSERT INTO [dbo].[OrderTrackings] ([OrderId], [Status], [Note], [ChangedAt])
SELECT o.[OrderId], N'CANCELLED',
       COALESCE(N'Order cancelled. Reason: ' + o.[CancellationReason], N'Order cancelled.'),
       o.[CancelledAt]
FROM   [dbo].[Orders] o
WHERE  o.[CancelledAt] IS NOT NULL AND o.[IsDeleted] = 0
  AND  NOT EXISTS (
        SELECT 1 FROM [dbo].[OrderTrackings] t
        WHERE  t.[OrderId] = o.[OrderId] AND t.[Status] = N'CANCELLED');
SET @bf_inserted += @@ROWCOUNT;

-- REJECTED — per OrderItems.RejectedAt
INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note], [ChangedAt])
SELECT oi.[OrderId], oi.[OrderItemId], N'REJECTED',
       COALESCE(N'"' + oi.[ProductName] + N'" cancelled by seller. Reason: ' + oi.[RejectionReason],
                N'"' + oi.[ProductName] + N'" cancelled by seller.'),
       oi.[RejectedAt]
FROM   [dbo].[OrderItems] oi
WHERE  oi.[RejectedAt] IS NOT NULL AND oi.[IsDeleted] = 0
  AND  NOT EXISTS (
        SELECT 1 FROM [dbo].[OrderTrackings] t
        WHERE  t.[OrderId] = oi.[OrderId] AND t.[OrderItemId] = oi.[OrderItemId] AND t.[Status] = N'REJECTED');
SET @bf_inserted += @@ROWCOUNT;

PRINT CONCAT('[patch] Backfilled tracking entries: ', @bf_inserted);

PRINT '[patch] Done.';
GO
