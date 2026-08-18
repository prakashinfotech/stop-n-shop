CREATE PROCEDURE [dbo].[usp_Seller_OrderItem_GetQueue]
    @SellerId    INT,
    @StatusFilter NVARCHAR(20) = N'all',   -- 'placed' | 'confirmed' | 'rejected' | 'fulfilled' | 'all'
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
            CASE oi.[OrderStatus] WHEN 1 THEN 0 ELSE 1 END,  -- pending first
            oi.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
