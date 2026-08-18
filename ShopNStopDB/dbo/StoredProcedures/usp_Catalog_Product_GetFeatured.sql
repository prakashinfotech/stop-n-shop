CREATE PROCEDURE [dbo].[usp_Catalog_Product_GetFeatured]
    @GenderTypeId TINYINT = NULL,
    @Limit        INT = 12
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT TOP (@Limit)
            p.[ProductId], p.[ProductName], p.[SlugUrl],
            p.[MRP], p.[SellingPrice], p.[SortOrder],
            b.[BrandName],
            c.[CategoryName],
            gt.[Name]          AS [GenderType],
            pi_.[ImageUrl]     AS [PrimaryImageUrl]
        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]       b   ON b.[BrandId]      = p.[BrandId]
        INNER JOIN [dbo].[Categories]   c   ON c.[CategoryId]   = p.[CategoryId]
        LEFT  JOIN [dbo].[GenderTypes]  gt  ON gt.[GenderTypeId] = p.[GenderTypeId]
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        WHERE p.[IsDeleted]      = 0
          AND p.[IsActive]       = 1
          AND p.[ApprovalStatus] = 2
          AND p.[IsFeatured]     = 1
          AND (p.[GenderTypeId]  = @GenderTypeId OR @GenderTypeId IS NULL)
        ORDER BY p.[SortOrder] ASC, p.[PublishedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
