CREATE PROCEDURE [dbo].[usp_CMS_Banner_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            b.[BannerId],
            b.[Title],
            b.[SubTitle],
            b.[ImageUrl],
            b.[MobileImageUrl],
            b.[LinkUrl],
            b.[BannerType]      AS [Section],
            b.[SortOrder],
            b.[GapBelowPx],
            b.[BackgroundColor],
            b.[IsActive],
            b.[StartDate],
            b.[EndDate],
            b.[CreatedAt],
            b.[UpdatedAt]
        FROM [dbo].[Banners] b
        WHERE b.[IsDeleted] = 0
        ORDER BY b.[BannerType] ASC, b.[SortOrder] ASC, b.[BannerId] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
