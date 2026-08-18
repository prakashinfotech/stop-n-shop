CREATE PROCEDURE [dbo].[usp_CMS_FooterContent_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            fc.[FooterId],
            fc.[SectionLabel],
            fc.[LinkLabel],
            fc.[LinkUrl],
            fc.[SortOrder],
            fc.[IsActive]
        FROM [dbo].[FooterContent] fc
        WHERE fc.[IsDeleted] = 0
          AND fc.[IsActive]  = 1
        ORDER BY fc.[SectionLabel] ASC, fc.[SortOrder] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
