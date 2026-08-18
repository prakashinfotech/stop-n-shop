CREATE PROCEDURE [dbo].[sp_GetBannerStack]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Returns every PROMOTIONAL banner (BannerType 2..7) in a single ordered list so the
    -- home-page banner stack renders with one round-trip instead of six. Hero banners
    -- (BannerType = 1) stay on sp_GetBanners @Section = 1.
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
        WHERE b.[IsDeleted]   = 0
          AND b.[IsActive]    = 1
          AND b.[BannerType] >= 2
          AND (b.[StartDate] IS NULL OR b.[StartDate] <= GETUTCDATE())
          AND (b.[EndDate]   IS NULL OR b.[EndDate]   >= GETUTCDATE())
        ORDER BY b.[BannerType] ASC, b.[SortOrder] ASC, b.[BannerId] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
