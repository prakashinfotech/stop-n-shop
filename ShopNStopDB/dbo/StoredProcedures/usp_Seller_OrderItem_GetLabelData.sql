CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_GetLabelData]
    @OrderItemId  INT,
    @SellerId     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Authorize: seller can only generate labels for their own items, and only
        -- after the line has been confirmed (or further along the lifecycle).
        IF NOT EXISTS (
            SELECT 1
            FROM [dbo].[OrderItems]
            WHERE [OrderItemId] = @OrderItemId
              AND [SellerId]    = @SellerId
              AND [IsDeleted]   = 0
        )
            THROW 50310, N'Order item not found or not owned by seller.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM [dbo].[OrderItems]
            WHERE [OrderItemId] = @OrderItemId
              AND [OrderStatus] IN (2, 3, 4, 5)   -- Confirmed, Packed, Dispatched, Delivered
        )
            THROW 50311, N'Label is only available after the item is confirmed.', 1;

        SELECT
            oi.[OrderItemId],
            oi.[OrderStatus]          AS [LineStatus],
            o.[OrderId],
            o.[OrderNumber],
            o.[CreatedAt]             AS [OrderDate],
            o.[PaymentMode],
            o.[PaymentStatus],
            -- Line totals
            oi.[ProductName],
            oi.[VariantSnapshot],
            oi.[Quantity],
            oi.[UnitPrice],
            oi.[TaxAmount],
            oi.[TotalPrice],
            pv.[VariantSku],
            pv.[Color],
            pv.[Size],
            pv.[Weight]               AS [VariantWeightGm],
            -- Code128 + QR payloads
            CONCAT(N'SNS-', oi.[OrderItemId], N'-', ISNULL(pv.[VariantSku], N'X')) AS [BarcodeValue],
            CONCAT(N'/seller/orders/items/', oi.[OrderItemId])                    AS [QrPayload],
            -- Buyer (masked phone — keep last 4)
            (u.[FirstName] + N' ' + ISNULL(u.[LastName], N''))                    AS [BuyerName],
            CASE
                WHEN LEN(u.[Mobile]) >= 4
                    THEN N'XXXXXX' + RIGHT(u.[Mobile], 4)
                ELSE u.[Mobile]
            END                                                                   AS [BuyerPhoneMasked],
            ua.[AddressLine1],
            ua.[AddressLine2],
            ua.[City]    AS [BuyerCity],
            ua.[State]   AS [BuyerState],
            ua.[PinCode] AS [BuyerPincode],
            ua.[Country] AS [BuyerCountry],
            -- Seller (FROM panel)
            s.[BusinessName]      AS [SellerBusinessName],
            s.[GstNumber]         AS [SellerGstNumber],
            s.[SupportPhone]      AS [SellerSupportPhone],
            s.[SupportEmail]      AS [SellerSupportEmail],
            s.[LogoUrl]           AS [SellerLogoUrl],
            s.[PickupAddressLine1] AS [SellerAddressLine1],
            s.[PickupAddressLine2] AS [SellerAddressLine2],
            s.[PickupCity]        AS [SellerCity],
            s.[PickupState]       AS [SellerState],
            s.[PickupPincode]     AS [SellerPincode]
        FROM   [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders]          o   ON o.[OrderId]   = oi.[OrderId]
        INNER JOIN [dbo].[Users]           u   ON u.[UserId]    = o.[UserId]
        INNER JOIN [dbo].[UserAddresses]   ua  ON ua.[AddressId] = o.[ShippingAddressId]
        INNER JOIN [dbo].[Sellers]         s   ON s.[SellerId]  = oi.[SellerId]
        LEFT  JOIN [dbo].[ProductVariants] pv  ON pv.[VariantId] = oi.[VariantId]
        WHERE  oi.[OrderItemId] = @OrderItemId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
