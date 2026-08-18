CREATE PROCEDURE [dbo].[usp_Commerce_Order_GetByUser]
    @UserId     INT,
    @OrderStatus TINYINT = NULL,
    @PageNumber INT = 1,
    @PageSize   INT = 10
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
            o.[ExpectedDeliveryDate],
            o.[DeliveredAt],
            o.[CreatedAt]     AS [OrderDate],
            COUNT(*) OVER()   AS [TotalCount],
            -- Item count and primary image from first item
            oi.[ItemCount],
            oi.[FirstProductName],
            oi.[FirstProductImage]
        FROM [dbo].[Orders] o
        OUTER APPLY (
            SELECT
                COUNT(*)                       AS [ItemCount],
                MAX(x.[ProductName])           AS [FirstProductName],
                MAX(x.[ImageUrl])              AS [FirstProductImage]
            FROM (
                SELECT TOP 1
                    oi2.[ProductName],
                    pi_.[ImageUrl]
                FROM [dbo].[OrderItems] oi2
                LEFT JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = oi2.[ProductId]
                                                    AND pi_.[IsPrimary] = 1
                                                    AND pi_.[IsDeleted] = 0
                WHERE oi2.[OrderId]  = o.[OrderId]
                  AND oi2.[IsDeleted] = 0
                ORDER BY oi2.[OrderItemId]
            ) x,
            (SELECT COUNT(*) AS [ItemCount]
             FROM [dbo].[OrderItems] WHERE [OrderId] = o.[OrderId] AND [IsDeleted] = 0) cnt
        ) oi
        WHERE o.[UserId]     = @UserId
          AND o.[IsDeleted]  = 0
          AND (@OrderStatus IS NULL OR o.[OrderStatus] = @OrderStatus)
        ORDER BY o.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
