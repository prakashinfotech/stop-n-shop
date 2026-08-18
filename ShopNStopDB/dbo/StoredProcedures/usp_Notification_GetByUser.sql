CREATE PROCEDURE [dbo].[usp_Notification_GetByUser]
    @UserId     INT,
    @IsRead     BIT = NULL,
    @PageNumber INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            n.[NotificationId],
            n.[Title],
            n.[Body],
            n.[NotificationType],
            n.[EntityId],
            n.[EntityType],
            n.[IsRead],
            n.[ReadAt],
            n.[CreatedAt],
            COUNT(*) OVER()                                     AS [TotalCount],
            SUM(CASE WHEN n.[IsRead] = 0 THEN 1 ELSE 0 END)
                OVER()                                          AS [UnreadCount]
        FROM [dbo].[Notifications] n
        WHERE n.[UserId]    = @UserId
          AND n.[IsDeleted] = 0
          AND (@IsRead IS NULL OR n.[IsRead] = @IsRead)
        ORDER BY n.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
