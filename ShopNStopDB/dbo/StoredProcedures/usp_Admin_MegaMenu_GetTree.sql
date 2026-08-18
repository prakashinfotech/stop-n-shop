CREATE PROCEDURE [dbo].[usp_Admin_MegaMenu_GetTree]
    @IncludeInactive  BIT = 1     -- admin view defaults to showing all
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Result set 1: categories
        SELECT
            c.[CategoryId],
            c.[MenuId],
            m.[MenuName],
            c.[CategoryName],
            c.[SlugUrl],
            c.[IconUrl],
            c.[BannerUrl],
            c.[SortOrder],
            c.[IsFeatured],
            c.[ShowInMegaMenu],
            c.[IsActive],
            c.[MetaTitle],
            c.[MetaDescription],
            (SELECT COUNT(*)
                 FROM [dbo].[SubCategories] sc
                WHERE sc.[CategoryId] = c.[CategoryId]
                  AND sc.[IsDeleted]  = 0) AS [SubCategoryCount],
            (SELECT COUNT(*)
                 FROM [dbo].[Products] p
                WHERE p.[CategoryId] = c.[CategoryId]
                  AND p.[IsDeleted]  = 0) AS [ProductCount]
        FROM [dbo].[Categories] c
        LEFT JOIN [dbo].[Menus] m ON m.[MenuId] = c.[MenuId]
        WHERE c.[IsDeleted] = 0
          AND (@IncludeInactive = 1 OR c.[IsActive] = 1)
        ORDER BY c.[MenuId], c.[SortOrder], c.[CategoryName];

        -- Result set 2: subcategories
        SELECT
            sc.[SubCategoryId],
            sc.[CategoryId],
            sc.[SubCategoryName],
            sc.[SlugUrl],
            sc.[IconUrl],
            sc.[SortOrder],
            sc.[IsFeatured],
            sc.[ShowInMegaMenu],
            sc.[IsActive],
            sc.[MetaTitle],
            sc.[MetaDescription],
            (SELECT COUNT(*)
                 FROM [dbo].[Products] p
                WHERE p.[SubCategoryId] = sc.[SubCategoryId]
                  AND p.[IsDeleted]     = 0) AS [ProductCount]
        FROM [dbo].[SubCategories] sc
        INNER JOIN [dbo].[Categories] c ON c.[CategoryId] = sc.[CategoryId]
        WHERE sc.[IsDeleted] = 0
          AND c.[IsDeleted]  = 0
          AND (@IncludeInactive = 1 OR sc.[IsActive] = 1)
        ORDER BY sc.[CategoryId], sc.[SortOrder], sc.[SubCategoryName];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
