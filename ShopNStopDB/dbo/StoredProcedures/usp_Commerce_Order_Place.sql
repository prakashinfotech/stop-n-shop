CREATE PROCEDURE [dbo].[usp_Commerce_Order_Place]
    @UserId            INT,
    @ShippingAddressId INT,
    @PaymentMode       TINYINT,      -- 1=COD, 2=Online, 3=Wallet
    @CouponCode        NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Validate address belongs to user
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserAddresses] WHERE [AddressId] = @ShippingAddressId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50060, N'Shipping address not found.', 1;

        -- Load active cart into temp table
        CREATE TABLE #CartItems
        (
            CartId     INT, ProductId INT, VariantId INT, SellerId INT, BrandId INT,
            Quantity   INT, UnitPrice DECIMAL(18,2), AdditionalPrice DECIMAL(18,2),
            FinalPrice DECIMAL(18,2), GstRate DECIMAL(5,2),
            ProductName NVARCHAR(300), VariantSku NVARCHAR(150),
            Color NVARCHAR(100), Size NVARCHAR(50), CommissionRate DECIMAL(5,2)
        );

        INSERT INTO #CartItems
        SELECT
            c.[CartId],
            p.[ProductId],
            pv.[VariantId],
            p.[SellerId],
            p.[BrandId],
            c.[Quantity],
            p.[SellingPrice],
            pv.[AdditionalPrice],
            (p.[SellingPrice] + pv.[AdditionalPrice]) AS [FinalPrice],
            p.[GstRate],
            p.[ProductName],
            pv.[VariantSku],
            pv.[Color],
            pv.[Size],
            s.[CommissionRate]
        FROM [dbo].[Cart]              c
        INNER JOIN [dbo].[Products]        p   ON p.[ProductId]  = c.[ProductId]
        INNER JOIN [dbo].[ProductVariants] pv  ON pv.[VariantId] = c.[VariantId]
        INNER JOIN [dbo].[Sellers]         s   ON s.[SellerId]   = p.[SellerId]
        WHERE c.[UserId]       = @UserId
          AND c.[IsDeleted]    = 0
          AND c.[SavedForLater] = 0
          AND p.[IsDeleted]    = 0
          AND p.[IsActive]     = 1
          AND p.[ApprovalStatus] = 2
          AND pv.[IsDeleted]   = 0
          AND pv.[IsActive]    = 1;

        IF NOT EXISTS (SELECT 1 FROM #CartItems)
            THROW 50061, N'Cart is empty or contains no available items.', 1;

        -- Validate stock (row-level lock to prevent overselling)
        IF EXISTS (
            SELECT 1 FROM #CartItems ci
            INNER JOIN [dbo].[ProductVariants] pv WITH (UPDLOCK, ROWLOCK)
                ON pv.[VariantId] = ci.[VariantId]
            WHERE pv.[StockQuantity] < ci.[Quantity]
        )
            THROW 50062, N'One or more items are out of stock.', 1;

        -- Calculate totals
        DECLARE @SubTotal        DECIMAL(18,2) = (SELECT SUM([FinalPrice] * [Quantity]) FROM #CartItems);
        DECLARE @TaxAmount       DECIMAL(18,2) = (SELECT SUM(([FinalPrice] * [Quantity]) * [GstRate] / 100) FROM #CartItems);
        DECLARE @ShippingCharge  DECIMAL(18,2) = CASE WHEN @SubTotal >= 499 THEN 0 ELSE 49 END;
        DECLARE @DiscountAmount  DECIMAL(18,2) = 0;
        DECLARE @CouponDiscount  DECIMAL(18,2) = 0;
        DECLARE @ResolvedCouponId INT          = NULL;

        -- Apply coupon if provided
        IF @CouponCode IS NOT NULL
        BEGIN
            DECLARE @OfferId          INT;
            DECLARE @OfferType        TINYINT;
            DECLARE @DiscountValue    DECIMAL(18,2);
            DECLARE @MinOrderValue    DECIMAL(18,2);
            DECLARE @MaxDiscountCap   DECIMAL(18,2);
            DECLARE @UsageLimitPerUser TINYINT;
            DECLARE @UsageLimitTotal  INT;
            DECLARE @CurrentUsage     INT;

            SELECT
                @ResolvedCouponId  = cp.[CouponId],
                @OfferId           = o.[OfferId],
                @OfferType         = o.[OfferType],
                @DiscountValue     = o.[DiscountValue],
                @MinOrderValue     = o.[MinOrderValue],
                @MaxDiscountCap    = o.[MaxDiscountCap],
                @UsageLimitPerUser = o.[UsageLimitPerUser],
                @UsageLimitTotal   = o.[UsageLimitTotal],
                @CurrentUsage      = o.[CurrentUsageCount]
            FROM [dbo].[Coupons] cp
            INNER JOIN [dbo].[Offers] o ON o.[OfferId] = cp.[OfferId]
            WHERE cp.[CouponCode] = @CouponCode
              AND cp.[IsDeleted]  = 0
              AND cp.[IsActive]   = 1
              AND o.[IsDeleted]   = 0
              AND o.[IsActive]    = 1
              AND o.[StartDate]   <= GETUTCDATE()
              AND o.[EndDate]     >= GETUTCDATE()
              AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal]);

            IF @ResolvedCouponId IS NULL
                THROW 50063, N'Invalid or expired coupon code.', 1;

            IF @SubTotal < @MinOrderValue
                THROW 50064, N'Order does not meet minimum value for this coupon.', 1;

            -- Check per-user usage
            DECLARE @UserCouponUsage INT = (
                SELECT COUNT(*) FROM [dbo].[Orders]
                WHERE [UserId] = @UserId AND [CouponId] = @ResolvedCouponId AND [IsDeleted] = 0
            );
            IF @UserCouponUsage >= @UsageLimitPerUser
                THROW 50065, N'You have already used this coupon the maximum number of times.', 1;

            -- Calculate coupon discount
            SET @CouponDiscount = [dbo].[fn_CalculateDiscountedPrice](@SubTotal, @OfferType, @DiscountValue, @MaxDiscountCap);
            SET @CouponDiscount = @SubTotal - @CouponDiscount;
        END;

        DECLARE @TotalAmount DECIMAL(18,2) = @SubTotal - @DiscountAmount - @CouponDiscount + @TaxAmount + @ShippingCharge;

        -- Generate order number
        DECLARE @NewOrderId     INT;
        DECLARE @NewOrderNumber NVARCHAR(50);

        BEGIN TRANSACTION;

            -- Insert order
            INSERT INTO [dbo].[Orders]
                ([UserId], [OrderNumber], [OrderStatus], [SubTotal], [DiscountAmount],
                 [CouponId], [CouponDiscount], [TaxAmount], [ShippingCharge], [TotalAmount],
                 [ShippingAddressId], [PaymentMode], [PaymentStatus], [CreatedBy], [UpdatedBy])
            VALUES
                (@UserId, N'PENDING', 1, @SubTotal, @DiscountAmount,
                 @ResolvedCouponId, @CouponDiscount, @TaxAmount, @ShippingCharge, @TotalAmount,
                 @ShippingAddressId, @PaymentMode, 1, @UserId, @UserId);

            SET @NewOrderId = SCOPE_IDENTITY();

            -- Set proper order number (SNS-YYYYMMDD-NNNNN)
            SET @NewOrderNumber = [dbo].[fn_GenerateOrderNumber](@NewOrderId);
            UPDATE [dbo].[Orders] SET [OrderNumber] = @NewOrderNumber WHERE [OrderId] = @NewOrderId;

            -- Open the order's tracking timeline.
            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [Status], [Note], [ChangedBy])
            VALUES (@NewOrderId, N'PLACED', N'Order placed by buyer.', @UserId);

            -- Insert order items
            INSERT INTO [dbo].[OrderItems]
                ([OrderId], [ProductId], [VariantId], [SellerId], [BrandId],
                 [ProductName], [VariantSnapshot], [Quantity], [UnitPrice],
                 [TaxAmount], [TotalPrice],
                 [SellerCommissionRate], [CommissionAmount], [SellerEarning],
                 [CreatedBy], [UpdatedBy])
            SELECT
                @NewOrderId,
                ci.[ProductId],
                ci.[VariantId],
                ci.[SellerId],
                ci.[BrandId],
                ci.[ProductName],
                ci.[VariantSku] + ISNULL(N' | ' + ci.[Color], N'') + ISNULL(N' | ' + ci.[Size], N''),
                ci.[Quantity],
                ci.[FinalPrice],
                (ci.[FinalPrice] * ci.[Quantity]) * ci.[GstRate] / 100,
                ci.[FinalPrice] * ci.[Quantity],
                ci.[CommissionRate],
                ROUND(ci.[FinalPrice] * ci.[Quantity] * ci.[CommissionRate] / 100, 2),
                ROUND(ci.[FinalPrice] * ci.[Quantity] - (ci.[FinalPrice] * ci.[Quantity] * ci.[CommissionRate] / 100), 2),
                @UserId,
                @UserId
            FROM #CartItems ci;

            -- Deduct stock
            UPDATE pv
            SET    pv.[StockQuantity] = pv.[StockQuantity] - ci.[Quantity],
                   pv.[UpdatedAt]     = GETUTCDATE(),
                   pv.[UpdatedBy]     = @UserId
            FROM [dbo].[ProductVariants] pv
            INNER JOIN #CartItems ci ON ci.[VariantId] = pv.[VariantId];

            -- Clear cart
            UPDATE [dbo].[Cart]
            SET    [IsDeleted] = 1, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UserId
            WHERE  [UserId] = @UserId AND [IsDeleted] = 0 AND [SavedForLater] = 0;

            -- Increment coupon usage count
            IF @ResolvedCouponId IS NOT NULL
                UPDATE [dbo].[Offers]
                SET    [CurrentUsageCount] = [CurrentUsageCount] + 1
                WHERE  [OfferId] = @OfferId;

            -- Create in-app notification
            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@UserId,
                 N'Order Placed Successfully',
                 N'Your order ' + @NewOrderNumber + N' has been placed. Total: ₹' + CAST(@TotalAmount AS NVARCHAR(20)),
                 1, N'Order', @NewOrderId, 1);

            -- Record an informational ledger entry so the order shows up in the
            -- buyer's wallet transaction history. Wallet balance is only actually
            -- deducted when PaymentMode = 3 (Wallet).
            DECLARE @WalletId INT;
            SELECT @WalletId = [WalletId] FROM [dbo].[Wallets] WHERE [UserId] = @UserId;
            IF @WalletId IS NULL
            BEGIN
                INSERT INTO [dbo].[Wallets] ([UserId], [Balance]) VALUES (@UserId, 0);
                SET @WalletId = SCOPE_IDENTITY();
            END

            DECLARE @PaymentLabel NVARCHAR(20) =
                CASE @PaymentMode
                     WHEN 1 THEN N'COD'
                     WHEN 2 THEN N'Online'
                     WHEN 3 THEN N'Wallet'
                     ELSE N'Other'
                END;

            INSERT INTO [dbo].[WalletTransactions]
                ([WalletId], [UserId], [Amount], [TransactionType],
                 [ReferenceType], [ReferenceId], [Description], [CreatedAt])
            VALUES
                (@WalletId, @UserId, @TotalAmount, 2,    -- 2 = Debit
                 N'Order', @NewOrderId,
                 N'Order ' + @NewOrderNumber + N' (' + @PaymentLabel + N')',
                 GETUTCDATE());

            -- Only actually deduct the wallet balance for wallet-pay orders.
            IF @PaymentMode = 3
                UPDATE [dbo].[Wallets]
                SET [Balance]   = [Balance] - @TotalAmount,
                    [UpdatedAt] = GETUTCDATE()
                WHERE [WalletId] = @WalletId;

        COMMIT TRANSACTION;

        DROP TABLE #CartItems;

        SELECT
            o.[OrderId],
            o.[OrderNumber],
            o.[OrderStatus],
            o.[TotalAmount],
            o.[PaymentMode],
            o.[PaymentStatus],
            o.[CreatedAt] AS [OrderDate]
        FROM [dbo].[Orders] o
        WHERE o.[OrderId] = @NewOrderId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#CartItems') IS NOT NULL DROP TABLE #CartItems;
        THROW;
    END CATCH;
END;
GO
