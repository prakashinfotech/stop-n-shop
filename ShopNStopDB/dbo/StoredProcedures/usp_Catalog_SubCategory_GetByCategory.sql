CREATE PROCEDURE [dbo].[usp_Catalog_SubCategory_GetByCategory]
    @CategoryId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            sc.[SubCategoryId]   AS [Id],
            sc.[CategoryId],
            sc.[SubCategoryName] AS [Name],
            sc.[SlugUrl],
            sc.[IconUrl],
            sc.[SortOrder],
            sc.[IsFeatured],
            sc.[ImageAngles],
            sc.[SizeScale],
            sc.[RequiresGender],
            sc.[RequiresDimensions],
            sc.[MetaTitle],
            sc.[MetaDescription]
        FROM [dbo].[SubCategories] sc
        WHERE sc.[CategoryId] = @CategoryId
          AND sc.[IsDeleted]  = 0
          AND sc.[IsActive]   = 1
        ORDER BY sc.[SortOrder] ASC, sc.[SubCategoryName] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
