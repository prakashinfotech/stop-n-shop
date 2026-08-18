CREATE PROCEDURE [dbo].[usp_CMS_HomeSection_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            hs.[SectionId],
            hs.[SectionName],
            hs.[Title],
            hs.[SubTitle],
            hs.[SectionType],
            hs.[SortOrder],
            hs.[IsActive],
            hs.[FilterJson]
        FROM [dbo].[HomeSections] hs
        WHERE hs.[IsDeleted] = 0
        ORDER BY hs.[SortOrder] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
