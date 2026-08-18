CREATE PROCEDURE [dbo].[usp_Seller_Product_GetAll]
    @SellerId        INT,
    @ApprovalStatus  TINYINT = NULL,  -- 1=Pending, 2=Approved, 3=Rejected
    @SearchTerm      NVARCHAR(200) = NULL,
    @PageNumber      INT = 1,
    @PageSize        INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            p.[ProductId]                                                          AS [Id],
            p.[ProductName]                                                        AS [Name],
            p.[MRP],
            p.[SellingPrice],
            CASE WHEN p.[MRP] > 0
                 THEN ROUND((p.[MRP] - p.[SellingPrice]) * 100.0 / p.[MRP], 0)
                 ELSE 0 END                                                        AS [DiscountPct],
            ISNULL(SUM(pv.[StockQuantity]), 0)                                     AS [StockQuantity],
            ISNULL(MIN(pv.[LowStockThreshold]), 0)                                 AS [LowStockThreshold],
            pi_.[ImageUrl]                                                         AS [PrimaryImage],
            CASE WHEN p.[ApprovalStatus] = 2 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsApproved],
            p.[CreatedAt],
            COUNT(*)        OVER()                                                 AS [TotalCount]
        FROM [dbo].[Products]         p
        INNER JOIN [dbo].[Brands]      b   ON b.[BrandId]    = p.[BrandId]
        INNER JOIN [dbo].[Categories]  c   ON c.[CategoryId] = p.[CategoryId]
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = p.[ProductId]
                                              AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN [dbo].[ProductVariants] pv ON pv.[ProductId] = p.[ProductId] AND pv.[IsDeleted] = 0
        WHERE p.[SellerId]  = @SellerId
          AND p.[IsDeleted] = 0
          AND (@ApprovalStatus IS NULL OR p.[ApprovalStatus] = @ApprovalStatus)
          AND (@SearchTerm    IS NULL  OR p.[ProductName] LIKE N'%' + @SearchTerm + N'%'
                                      OR p.[Sku] LIKE N'%' + @SearchTerm + N'%')
        GROUP BY
            p.[ProductId], p.[ProductName],
            p.[MRP], p.[SellingPrice], p.[ApprovalStatus],
            p.[CreatedAt], pi_.[ImageUrl]
        ORDER BY p.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
