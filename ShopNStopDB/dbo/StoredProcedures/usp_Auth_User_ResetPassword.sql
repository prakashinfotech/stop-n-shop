CREATE PROCEDURE [dbo].[usp_Auth_User_ResetPassword]
    @UserId          INT,
    @NewPasswordHash NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50009, N'User not found.', 1;

        UPDATE [dbo].[Users]
        SET    [PasswordHash] = @NewPasswordHash,
               [UpdatedAt]    = GETUTCDATE(),
               [UpdatedBy]    = @UserId
        WHERE  [UserId] = @UserId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
