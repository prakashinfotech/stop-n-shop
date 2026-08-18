CREATE PROCEDURE [dbo].[usp_Engagement_SearchLog_GetRecent]
    @UserId INT,
    @Count  INT = 6
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Returns the user's last N distinct search terms (case-insensitive), newest first.
    -- Used by the home page "Recent searches" chip row.
    BEGIN TRY
        ;WITH Ranked AS (
            SELECT
                LOWER(LTRIM(RTRIM(s.[SearchTerm]))) AS [TermKey],
                s.[SearchTerm],
                s.[SearchedAt],
                ROW_NUMBER() OVER (
                    PARTITION BY LOWER(LTRIM(RTRIM(s.[SearchTerm])))
                    ORDER BY s.[SearchedAt] DESC
                ) AS [rn]
            FROM [dbo].[SearchLogs] s
            WHERE s.[UserId] = @UserId
              AND LEN(LTRIM(RTRIM(s.[SearchTerm]))) > 0
        )
        SELECT TOP (@Count)
            [SearchTerm] AS [Term],
            [SearchedAt]
        FROM Ranked
        WHERE [rn] = 1
        ORDER BY [SearchedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
