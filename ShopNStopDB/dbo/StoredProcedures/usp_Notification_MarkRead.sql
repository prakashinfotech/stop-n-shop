CREATE PROCEDURE [dbo].[usp_Notification_MarkRead]
    @UserId         INT,
    @NotificationId INT = NULL  -- NULL = mark all as read
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[Notifications]
        SET    [IsRead]  = 1,
               [ReadAt]  = GETUTCDATE()
        WHERE  [UserId]    = @UserId
          AND  [IsDeleted] = 0
          AND  [IsRead]    = 0
          AND  (@NotificationId IS NULL OR [NotificationId] = @NotificationId);

        SELECT @@ROWCOUNT AS [UpdatedCount];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
