CREATE PROCEDURE [dbo].[usp_Catalog_Product_ListByBrand]
    @BrandId      INT,
    @CategoryId   INT    = NULL,
    @GenderTypeId TINYINT = NULL,
    @SortBy       NVARCHAR(50) = N'Newest',
    @PageNumber   INT = 1,
    @PageSize     INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            p.[ProductId], p.[ProductName], p.[SlugUrl],
            p.[MRP], p.[SellingPrice], p.[IsFeatured],
            b.[BrandName],
            c.[CategoryName],
            gt.[Name]         AS [GenderType],
            pi_.[ImageUrl]    AS [PrimaryImageUrl],
            ISNULL(pv.[MinStock], 0) AS [MinStock],
            COUNT(*) OVER()   AS [TotalCount]
        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]       b   ON b.[BrandId]       = p.[BrandId]
        INNER JOIN [dbo].[Categories]   c   ON c.[CategoryId]    = p.[CategoryId]
        LEFT  JOIN [dbo].[GenderTypes]  gt  ON gt.[GenderTypeId] = p.[GenderTypeId]
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId]  = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN (
            SELECT [ProductId], MIN([StockQuantity]) AS [MinStock]
            FROM [dbo].[ProductVariants] WHERE [IsDeleted] = 0 AND [IsActive] = 1
            GROUP BY [ProductId]
        ) pv ON pv.[ProductId] = p.[ProductId]
        WHERE p.[IsDeleted]      = 0
          AND p.[IsActive]       = 1
          AND p.[ApprovalStatus] = 2
          AND p.[BrandId]        = @BrandId
          AND (p.[CategoryId]    = @CategoryId   OR @CategoryId   IS NULL)
          AND (p.[GenderTypeId]  = @GenderTypeId OR @GenderTypeId IS NULL)
        ORDER BY
            CASE WHEN @SortBy = N'PriceLow'  THEN p.[SellingPrice] END ASC,
            CASE WHEN @SortBy = N'PriceHigh' THEN p.[SellingPrice] END DESC,
            CASE WHEN @SortBy = N'Newest'    THEN p.[PublishedAt]  END DESC,
            p.[SortOrder] ASC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
