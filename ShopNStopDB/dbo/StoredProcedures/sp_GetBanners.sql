CREATE PROCEDURE [dbo].[sp_GetBanners]
    @Section TINYINT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            b.[BannerId]              AS [Id],
            b.[BannerType]            AS [Section],
            b.[ImageUrl],
            b.[MobileImageUrl],
            b.[Title],
            b.[SubTitle]              AS [Subtitle],
            b.[LinkUrl],
            b.[SortOrder],
            b.[GapBelowPx],
            b.[BackgroundColor]
        FROM [dbo].[Banners] b
        WHERE b.[IsDeleted]  = 0
          AND b.[IsActive]   = 1
          AND b.[BannerType] = @Section
          AND (b.[StartDate] IS NULL OR b.[StartDate] <= GETUTCDATE())
          AND (b.[EndDate]   IS NULL OR b.[EndDate]   >= GETUTCDATE())
        ORDER BY b.[SortOrder] ASC, b.[BannerId] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
