CREATE PROCEDURE [dbo].[usp_Catalog_SubCategory_GetFormSchema]
    @SubCategoryId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT TOP 1
            sc.[SubCategoryId],
            sc.[SubCategoryName],
            sc.[ImageAngles],
            sc.[SizeScale],
            sc.[RequiresGender],
            sc.[RequiresDimensions]
        FROM [dbo].[SubCategories] sc
        WHERE sc.[SubCategoryId] = @SubCategoryId
          AND sc.[IsDeleted]     = 0;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
