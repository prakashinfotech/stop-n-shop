CREATE PROCEDURE [dbo].[usp_Engagement_SearchLog_Add]
    @SearchTerm   NVARCHAR(500),
    @UserId       INT            = NULL,
    @ResultCount  INT            = 0,
    @ClickedProductId INT        = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [dbo].[SearchLogs]
            ([SearchTerm], [UserId], [ResultCount], [ClickedProductId], [SearchedAt])
        VALUES
            (@SearchTerm, @UserId, @ResultCount, @ClickedProductId, GETUTCDATE());

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
