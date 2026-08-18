CREATE PROCEDURE [dbo].[usp_Admin_User_Suspend]
    @UserId      INT,
    @AdminUserId INT,
    @Reason      NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50130, N'User not found.', 1;

        IF @UserId = @AdminUserId
            THROW 50131, N'Admins cannot suspend their own account.', 1;

        UPDATE [dbo].[Users]
        SET    [IsActive]  = 0,
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
