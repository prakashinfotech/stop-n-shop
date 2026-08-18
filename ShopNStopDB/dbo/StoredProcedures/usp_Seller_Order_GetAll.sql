CREATE PROCEDURE [dbo].[usp_Seller_Order_GetAll]
    @SellerId    INT,
    @OrderStatus TINYINT = NULL,
    @FromDate    DATE    = NULL,
    @ToDate      DATE    = NULL,
    @PageNumber  INT = 1,
    @PageSize    INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            o.[OrderId],
            o.[OrderNumber],
            o.[OrderStatus],
            o.[TotalAmount],
            o.[PaymentMode],
            o.[PaymentStatus],
            o.[CreatedAt]    AS [OrderDate],
            u.[FirstName],
            u.[LastName],
            u.[Email],
            oi.[OrderItemId],
            oi.[ProductName],
            oi.[VariantSnapshot],
            oi.[Quantity],
            oi.[TotalPrice],
            oi.[SellerEarning],
            pi_.[ImageUrl]   AS [ProductImageUrl],
            COUNT(*) OVER()  AS [TotalCount]
        FROM [dbo].[OrderItems]       oi
        INNER JOIN [dbo].[Orders]         o  ON o.[OrderId]  = oi.[OrderId]  AND o.[IsDeleted]  = 0
        INNER JOIN [dbo].[Users]          u  ON u.[UserId]   = o.[UserId]
        LEFT  JOIN [dbo].[ProductImages]  pi_ ON pi_.[ProductId] = oi.[ProductId]
                                              AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        WHERE oi.[SellerId]  = @SellerId
          AND oi.[IsDeleted] = 0
          AND (@OrderStatus IS NULL OR o.[OrderStatus] = @OrderStatus)
          AND (@FromDate     IS NULL OR CAST(o.[CreatedAt] AS DATE) >= @FromDate)
          AND (@ToDate       IS NULL OR CAST(o.[CreatedAt] AS DATE) <= @ToDate)
        ORDER BY o.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
