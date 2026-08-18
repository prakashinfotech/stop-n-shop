CREATE PROCEDURE [dbo].[usp_Admin_Order_GetAll]
    @OrderStatus         TINYINT       = NULL,
    @FromDate            DATE          = NULL,
    @ToDate              DATE          = NULL,
    @SearchTerm          NVARCHAR(200) = NULL,
    @LineStatusFilter    TINYINT       = NULL,   -- only include orders with at least one OrderItem at this status (1=Placed → Unfulfilled, 8=Rejected)
    @PaymentStatusFilter TINYINT       = NULL,   -- 2 = Paid
    @PageNumber          INT           = 1,
    @PageSize            INT           = 20
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
            o.[CreatedAt]  AS [OrderDate],
            u.[FirstName],
            u.[LastName],
            u.[Email],
            COUNT(oi.[OrderItemId]) AS [ItemCount],
            COUNT(*)        OVER()  AS [TotalCount]
        FROM [dbo].[Orders]      o
        INNER JOIN [dbo].[Users]      u  ON u.[UserId]  = o.[UserId]
        INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderId] = o.[OrderId] AND oi.[IsDeleted] = 0
        WHERE o.[IsDeleted] = 0
          AND (@OrderStatus IS NULL OR o.[OrderStatus]                 = @OrderStatus)
          AND (@FromDate    IS NULL OR CAST(o.[CreatedAt] AS DATE)    >= @FromDate)
          AND (@ToDate      IS NULL OR CAST(o.[CreatedAt] AS DATE)    <= @ToDate)
          AND (@SearchTerm  IS NULL  OR o.[OrderNumber] LIKE N'%' + @SearchTerm + N'%'
                                    OR u.[Email]        LIKE N'%' + @SearchTerm + N'%'
                                    OR u.[FirstName]    LIKE N'%' + @SearchTerm + N'%'
                                    OR u.[LastName]     LIKE N'%' + @SearchTerm + N'%')
          AND (@PaymentStatusFilter IS NULL OR o.[PaymentStatus] = @PaymentStatusFilter)
          AND (@LineStatusFilter    IS NULL
               OR EXISTS (
                   SELECT 1 FROM [dbo].[OrderItems] x
                   WHERE x.[OrderId]     = o.[OrderId]
                     AND x.[IsDeleted]   = 0
                     AND x.[OrderStatus] = @LineStatusFilter
               ))
        GROUP BY
            o.[OrderId], o.[OrderNumber], o.[OrderStatus], o.[TotalAmount],
            o.[PaymentMode], o.[PaymentStatus], o.[CreatedAt],
            u.[FirstName], u.[LastName], u.[Email]
        ORDER BY o.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
