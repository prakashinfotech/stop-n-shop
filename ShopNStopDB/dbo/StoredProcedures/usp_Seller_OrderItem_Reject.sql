CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_Reject]
    @OrderItemId  INT,
    @SellerId     INT,
    @Reason       NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Reason IS NULL OR LEN(LTRIM(RTRIM(@Reason))) < 10
            THROW 50302, N'Rejection reason must be at least 10 characters.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM [dbo].[OrderItems]
            WHERE [OrderItemId] = @OrderItemId
              AND [SellerId]    = @SellerId
              AND [IsDeleted]   = 0
        )
            THROW 50300, N'Order item not found or not owned by seller.', 1;

        -- Only un-dispatched lines can be rejected (statuses 1 Placed or 2 Confirmed).
        IF EXISTS (
            SELECT 1
            FROM [dbo].[OrderItems]
            WHERE [OrderItemId] = @OrderItemId
              AND [OrderStatus] NOT IN (1, 2)
        )
            THROW 50303, N'This item can no longer be rejected.', 1;

        DECLARE @VariantId      INT;
        DECLARE @Quantity       INT;
        DECLARE @TotalPrice     DECIMAL(18,2);
        DECLARE @OrderId        INT;
        DECLARE @OrderNumber    NVARCHAR(50);
        DECLARE @BuyerId        INT;
        DECLARE @ProductName    NVARCHAR(300);
        DECLARE @PaymentMode    TINYINT;
        DECLARE @PaymentStatus  TINYINT;

        SELECT @VariantId     = oi.[VariantId],
               @Quantity      = oi.[Quantity],
               @TotalPrice    = oi.[TotalPrice],
               @OrderId       = o.[OrderId],
               @OrderNumber   = o.[OrderNumber],
               @BuyerId       = o.[UserId],
               @ProductName   = oi.[ProductName],
               @PaymentMode   = o.[PaymentMode],
               @PaymentStatus = o.[PaymentStatus]
        FROM   [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
        WHERE  oi.[OrderItemId] = @OrderItemId;

        BEGIN TRANSACTION;

            -- 1) Flip the line to Rejected with reason
            UPDATE [dbo].[OrderItems]
            SET    [OrderStatus]         = 8,                       -- Rejected
                   [RejectedAt]          = GETUTCDATE(),
                   [RejectedBySellerId]  = @SellerId,
                   [RejectionReason]     = @Reason,
                   [UpdatedAt]           = GETUTCDATE()
            WHERE  [OrderItemId] = @OrderItemId;

            -- 2) Restock the variant
            UPDATE [dbo].[ProductVariants]
            SET    [StockQuantity] = [StockQuantity] + @Quantity,
                   [UpdatedAt]     = GETUTCDATE()
            WHERE  [VariantId] = @VariantId;

            -- 3) If buyer already paid, credit their wallet for this line
            IF @PaymentStatus = 2 AND @TotalPrice > 0
            BEGIN
                DECLARE @WalletId   INT;
                DECLARE @NewBalance DECIMAL(18,2);

                MERGE [dbo].[Wallets] AS target
                USING (SELECT @BuyerId AS [UserId]) AS source ON target.[UserId] = source.[UserId]
                WHEN MATCHED THEN
                    UPDATE SET [Balance] = [Balance] + @TotalPrice, [UpdatedAt] = GETUTCDATE()
                WHEN NOT MATCHED THEN
                    INSERT ([UserId], [Balance]) VALUES (@BuyerId, @TotalPrice);

                SELECT @WalletId = [WalletId] FROM [dbo].[Wallets] WHERE [UserId] = @BuyerId;

                INSERT INTO [dbo].[WalletTransactions]
                    ([WalletId], [UserId], [Amount], [TransactionType],
                     [ReferenceType], [ReferenceId], [Description], [CreatedAt])
                VALUES
                    (@WalletId, @BuyerId, @TotalPrice, 1,        -- Credit (refund)
                     N'OrderRefund', @OrderId,
                     N'Refund for rejected item in order ' + @OrderNumber,
                     GETUTCDATE());
            END

            -- 4) Buyer notification with the reason
            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerId,
                 N'Item Cancelled by Seller',
                 N'"' + @ProductName + N'" in order ' + @OrderNumber + N' was cancelled. Reason: ' + @Reason,
                 3, N'Order', @OrderId, 1);

            -- 5) If every line on the parent order is now rejected/cancelled, mark the order itself cancelled.
            IF NOT EXISTS (
                SELECT 1 FROM [dbo].[OrderItems]
                WHERE [OrderId]   = @OrderId
                  AND [IsDeleted] = 0
                  AND [OrderStatus] NOT IN (6, 8)
            )
                UPDATE [dbo].[Orders]
                SET    [OrderStatus] = 6,                          -- Cancelled
                       [UpdatedAt]   = GETUTCDATE()
                WHERE  [OrderId] = @OrderId;

            -- 6) Tracking timeline — record the rejection (with the seller's reason
            --    in the note column for buyer visibility).
            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note])
            VALUES (@OrderId, @OrderItemId, N'REJECTED',
                    N'"' + @ProductName + N'" cancelled by seller. Reason: ' + @Reason);

        COMMIT TRANSACTION;

        SELECT @OrderItemId AS [OrderItemId], 8 AS [OrderStatus], @OrderNumber AS [OrderNumber];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
