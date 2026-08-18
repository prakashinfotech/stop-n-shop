CREATE PROCEDURE [dbo].[usp_Seller_Order_Cancel]
    @OrderId            INT,
    @SellerId           INT,
    @CancellationReason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Verify the seller owns at least one item in this order
        IF NOT EXISTS (
            SELECT 1
            FROM [dbo].[OrderItems] oi
            INNER JOIN [dbo].[ProductVariants] pv ON pv.[VariantId] = oi.[VariantId]
            INNER JOIN [dbo].[Products] p         ON p.[ProductId]  = pv.[ProductId]
            WHERE oi.[OrderId] = @OrderId
              AND p.[SellerId] = @SellerId
              AND oi.[IsDeleted] = 0
        )
            THROW 50090, N'Order not found or you do not have permission to cancel it.', 1;

        DECLARE @CurrentStatus  TINYINT;
        DECLARE @BuyerUserId    INT;
        DECLARE @PaymentMode    TINYINT;
        DECLARE @TotalAmount    DECIMAL(18,2);
        DECLARE @OrderNumber    NVARCHAR(50);

        SELECT
            @CurrentStatus = [OrderStatus],
            @BuyerUserId   = [UserId],
            @PaymentMode   = [PaymentMode],
            @TotalAmount   = [TotalAmount],
            @OrderNumber   = [OrderNumber]
        FROM [dbo].[Orders]
        WHERE [OrderId] = @OrderId AND [IsDeleted] = 0;

        IF @CurrentStatus IS NULL
            THROW 50091, N'Order not found.', 1;

        -- Seller can cancel Pending (1), Confirmed (2), or Processing (3) orders
        IF @CurrentStatus NOT IN (1, 2, 3)
            THROW 50092, N'Order cannot be cancelled at this stage.', 1;

        BEGIN TRANSACTION;

            -- Cancel the order
            UPDATE [dbo].[Orders]
            SET    [OrderStatus]        = 6,
                   [CancelledAt]        = GETUTCDATE(),
                   [CancellationReason] = @CancellationReason,
                   [UpdatedAt]          = GETUTCDATE(),
                   [UpdatedBy]          = @SellerId
            WHERE  [OrderId] = @OrderId;

            -- Restore stock
            UPDATE pv
            SET    pv.[StockQuantity] = pv.[StockQuantity] + oi.[Quantity],
                   pv.[UpdatedAt]     = GETUTCDATE(),
                   pv.[UpdatedBy]     = @SellerId
            FROM [dbo].[ProductVariants] pv
            INNER JOIN [dbo].[OrderItems] oi ON oi.[VariantId] = pv.[VariantId]
                AND oi.[OrderId] = @OrderId
                AND oi.[IsDeleted] = 0;

            -- Credit wallet if payment was online (PaymentMode = 2)
            IF @PaymentMode = 2
            BEGIN
                MERGE [dbo].[Wallets] AS target
                USING (SELECT @BuyerUserId AS [UserId]) AS source ON target.[UserId] = source.[UserId]
                WHEN MATCHED THEN
                    UPDATE SET [Balance] = [Balance] + @TotalAmount, [UpdatedAt] = GETUTCDATE()
                WHEN NOT MATCHED THEN
                    INSERT ([UserId], [Balance], [CreatedAt], [UpdatedAt])
                    VALUES (@BuyerUserId, @TotalAmount, GETUTCDATE(), GETUTCDATE());

                DECLARE @WalletId INT;
                SELECT @WalletId = [WalletId] FROM [dbo].[Wallets] WHERE [UserId] = @BuyerUserId;

                INSERT INTO [dbo].[WalletTransactions]
                    ([WalletId], [UserId], [Amount], [TransactionType],
                     [ReferenceType], [ReferenceId], [Description], [CreatedAt])
                VALUES
                    (@WalletId, @BuyerUserId, @TotalAmount, 1,
                     N'OrderRefund', @OrderId,
                     N'Refund for cancelled order #' + @OrderNumber,
                     GETUTCDATE());
            END;

            -- Notify buyer
            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerUserId,
                 N'Order Cancelled by Seller',
                 CASE WHEN @PaymentMode = 2
                      THEN N'Your order #' + @OrderNumber + N' has been cancelled by the seller. The amount of ₹' + CAST(@TotalAmount AS NVARCHAR(20)) + N' has been refunded to your wallet.'
                      ELSE N'Your order #' + @OrderNumber + N' has been cancelled by the seller.'
                 END,
                 1, N'Order', @OrderId, 1);

            -- Tracking timeline entry.
            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [Status], [Note], [ChangedBy])
            VALUES (@OrderId, N'CANCELLED',
                    COALESCE(N'Order cancelled by seller. Reason: ' + @CancellationReason,
                             N'Order cancelled by seller.'),
                    @SellerId);

        COMMIT TRANSACTION;

        -- Return order details for email
        SELECT
            @BuyerUserId  AS [BuyerUserId],
            @OrderNumber  AS [OrderNumber],
            @TotalAmount  AS [TotalAmount],
            @PaymentMode  AS [PaymentMode];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
