-- Paginated audit query with optional filters. Always orders by ChangedAt DESC.
CREATE PROCEDURE [dbo].[usp_Admin_AuditTrail_Query]
    @TableName  NVARCHAR(100) = NULL,
    @RecordId   INT           = NULL,
    @ChangedBy  INT           = NULL,
    @FromDate   DATETIME2(0)  = NULL,
    @ToDate     DATETIME2(0)  = NULL,
    @PageNumber INT           = 1,
    @PageSize   INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize   < 1 SET @PageSize   = 20;
    IF @PageSize   > 200 SET @PageSize = 200;

    ;WITH filtered AS (
        SELECT
            a.[AuditId],
            a.[TableName],
            a.[RecordId],
            a.[Action],
            a.[OldValues],
            a.[NewValues],
            a.[ChangedBy],
            a.[ChangedAt],
            a.[IpAddress],
            u.[Email]      AS [ChangedByEmail],
            u.[FirstName]  AS [ChangedByFirstName],
            u.[LastName]   AS [ChangedByLastName]
        FROM [dbo].[AuditLogs] a
        LEFT JOIN [dbo].[Users] u ON u.[UserId] = a.[ChangedBy]
        WHERE (@TableName IS NULL OR a.[TableName] = @TableName)
          AND (@RecordId  IS NULL OR a.[RecordId]  = @RecordId)
          AND (@ChangedBy IS NULL OR a.[ChangedBy] = @ChangedBy)
          AND (@FromDate  IS NULL OR a.[ChangedAt] >= @FromDate)
          AND (@ToDate    IS NULL OR a.[ChangedAt] <= @ToDate)
    )
    SELECT
        *,
        COUNT(1) OVER () AS [TotalCount]
    FROM filtered
    ORDER BY [ChangedAt] DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO
