CREATE PROCEDURE [dbo].[sp_GetMegaMenu]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- 3-level commerce hierarchy:
        -- Level 1: Menus (MEN, WOMEN, KIDS, HOME, BEAUTY, HOMESTOP, GIFTS, WATCHES, PERFUMES, BRANDS)
        -- Level 2: Categories (e.g., Casual Wear, Inner Wear, Formal Wear under MEN)
        -- Level 3: SubCategories (e.g., T-Shirts, Polos, Shirts under Casual Wear)
        SELECT
            m.[MenuId]                      AS [TopMenuId],
            m.[MenuName]                    AS [TopMenuName],
            m.[SlugUrl]                     AS [TopMenuSlug],

            c.[CategoryId]                  AS [SubMenuId],
            c.[CategoryName]                AS [SubMenuName],
            c.[SlugUrl]                     AS [SubMenuSlug],
            c.[IconUrl]                     AS [SubMenuIconUrl],

            sc.[SubCategoryId]              AS [SubSubMenuId],
            sc.[SubCategoryName]            AS [SubSubMenuName],
            sc.[SlugUrl]                    AS [SubSubMenuSlug],
            sc.[IconUrl]                    AS [SubSubMenuIconUrl]
        FROM [dbo].[Menus]          m
        INNER JOIN [dbo].[Categories]    c
              ON c.[MenuId] = m.[MenuId]
             AND c.[IsDeleted] = 0 AND c.[IsActive] = 1
             AND c.[ShowInMegaMenu] = 1
        INNER JOIN [dbo].[SubCategories] sc
              ON sc.[CategoryId] = c.[CategoryId]
             AND sc.[IsDeleted] = 0 AND sc.[IsActive] = 1
             AND sc.[ShowInMegaMenu] = 1
        WHERE m.[IsDeleted] = 0
          AND m.[IsActive]  = 1
        ORDER BY m.[SortOrder], m.[MenuName], c.[SortOrder], c.[CategoryName], sc.[SortOrder], sc.[SubCategoryName];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
