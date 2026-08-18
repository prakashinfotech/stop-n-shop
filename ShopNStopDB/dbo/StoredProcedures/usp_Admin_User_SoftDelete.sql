CREATE PROCEDURE [dbo].[usp_Admin_User_SoftDelete]
    @UserId      INT,
    @AdminUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50133, N'User not found.', 1;

        IF @UserId = @AdminUserId
            THROW 50134, N'Admins cannot delete their own account.', 1;

        UPDATE [dbo].[Users]
        SET    [IsDeleted] = 1,
               [IsActive]  = 0,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @AdminUserId
        WHERE  [UserId] = @UserId;

        SELECT 1 AS [Success];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
