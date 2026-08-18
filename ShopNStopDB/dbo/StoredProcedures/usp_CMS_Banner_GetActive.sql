CREATE PROCEDURE [dbo].[usp_CMS_Banner_GetActive]
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
            b.[BannerType],
            b.[SortOrder],
            b.[GapBelowPx],
            b.[BackgroundColor],
            b.[StartDate],
            b.[EndDate]
        FROM [dbo].[Banners] b
        WHERE b.[IsDeleted] = 0
          AND b.[IsActive]  = 1
          AND (b.[StartDate] IS NULL OR b.[StartDate] <= CAST(GETUTCDATE() AS DATE))
          AND (b.[EndDate]   IS NULL OR b.[EndDate]   >= CAST(GETUTCDATE() AS DATE))
        ORDER BY b.[SortOrder] ASC, b.[CreatedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
