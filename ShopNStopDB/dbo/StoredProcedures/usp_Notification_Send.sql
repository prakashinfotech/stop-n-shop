CREATE PROCEDURE [dbo].[usp_Notification_Send]
    @UserId           INT,
    @Title            NVARCHAR(200),
    @Body             NVARCHAR(1000),
    @NotificationType TINYINT       = NULL,
    @EntityId         INT           = NULL,
    @EntityType       NVARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [dbo].[Notifications]
            ([UserId], [Title], [Body], [NotificationType],
             [EntityId], [EntityType], [IsRead],
             [CreatedAt], [IsDeleted])
        VALUES
            (@UserId, @Title, @Body, @NotificationType,
             @EntityId, @EntityType, 0,
             GETUTCDATE(), 0);

        SELECT SCOPE_IDENTITY() AS [NotificationId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
