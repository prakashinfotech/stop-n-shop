CREATE PROCEDURE [dbo].[usp_Catalog_Category_GetAll]
    @MenuId         INT = NULL,    -- NULL = show all menus, otherwise filter by specific MenuId
    @IsFeaturedOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            c.[CategoryId]     AS [Id],
            c.[MenuId],
            c.[CategoryName]   AS [Name],
            c.[SlugUrl],
            m.[MenuName],
            c.[IconUrl],
            c.[BannerUrl],
            c.[SortOrder],
            c.[IsFeatured],
            c.[MetaTitle],
            c.[MetaDescription]
        FROM [dbo].[Categories] c
        INNER JOIN [dbo].[Menus] m ON m.[MenuId] = c.[MenuId]
        WHERE c.[IsDeleted] = 0
          AND c.[IsActive]  = 1
          AND m.[IsDeleted] = 0
          AND m.[IsActive]  = 1
          AND (@MenuId IS NULL OR c.[MenuId] = @MenuId)
          AND (@IsFeaturedOnly = 0 OR c.[IsFeatured] = 1)
        ORDER BY m.[SortOrder] ASC, m.[MenuName] ASC, c.[SortOrder] ASC, c.[CategoryName] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
