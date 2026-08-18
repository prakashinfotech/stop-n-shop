CREATE PROCEDURE [dbo].[usp_Catalog_SubCategory_GetFeatured]
    @Count INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Returns the admin-curated set of subcategories flagged for the home
        -- "Trending Categories" tile grid. Joins one level up so the UI can show
        -- the parent category/menu for deep-linking.
        SELECT TOP (@Count)
            sc.[SubCategoryId]    AS [SubCategoryId],
            sc.[SubCategoryName]  AS [SubCategoryName],
            sc.[SlugUrl]          AS [SlugUrl],
            sc.[IconUrl]          AS [IconUrl],
            sc.[SortOrder]        AS [SortOrder],
            c.[CategoryId]        AS [CategoryId],
            c.[CategoryName]      AS [CategoryName],
            c.[SlugUrl]           AS [CategorySlug],
            m.[MenuId]            AS [MenuId],
            m.[MenuName]          AS [MenuName],
            m.[SlugUrl]           AS [MenuSlug]
        FROM [dbo].[SubCategories]   sc
        INNER JOIN [dbo].[Categories]    c  ON c.[CategoryId] = sc.[CategoryId]
                                           AND c.[IsDeleted] = 0 AND c.[IsActive] = 1
        INNER JOIN [dbo].[Menus]         m  ON m.[MenuId] = c.[MenuId]
                                           AND m.[IsDeleted] = 0 AND m.[IsActive] = 1
        WHERE sc.[IsFeatured] = 1
          AND sc.[IsDeleted]  = 0
          AND sc.[IsActive]   = 1
        ORDER BY sc.[SortOrder], sc.[SubCategoryName];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
