CREATE PROCEDURE [dbo].[usp_Commerce_Wishlist_GetByUser]
    @UserId     INT,
    @PageNumber INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            w.[WishlistId],
            w.[AddedAt],
            p.[ProductId],
            p.[ProductName],
            p.[SlugUrl],
            p.[MRP],
            p.[SellingPrice],
            p.[IsActive]       AS [ProductIsActive],
            b.[BrandName],
            pi_.[ImageUrl]     AS [PrimaryImageUrl],
            ISNULL(pv.[MinStock], 0) AS [MinStock],
            COUNT(*) OVER()    AS [TotalCount]
        FROM [dbo].[Wishlist]          w
        INNER JOIN [dbo].[Products]        p   ON p.[ProductId]  = w.[ProductId] AND p.[IsDeleted]  = 0
        INNER JOIN [dbo].[Brands]          b   ON b.[BrandId]    = p.[BrandId]   AND b.[IsDeleted]  = 0
        LEFT  JOIN [dbo].[ProductImages]   pi_ ON pi_.[ProductId] = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN (
            SELECT [ProductId], MIN([StockQuantity]) AS [MinStock]
            FROM [dbo].[ProductVariants] WHERE [IsDeleted] = 0 AND [IsActive] = 1
            GROUP BY [ProductId]
        ) pv ON pv.[ProductId] = p.[ProductId]
        WHERE w.[UserId]    = @UserId
          AND w.[IsDeleted] = 0
        ORDER BY w.[AddedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
