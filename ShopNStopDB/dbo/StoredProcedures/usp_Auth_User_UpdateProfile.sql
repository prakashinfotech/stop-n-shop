CREATE PROCEDURE [dbo].[usp_Auth_User_UpdateProfile]
    @UserId          INT,
    @FirstName       NVARCHAR(100) = NULL,
    @LastName        NVARCHAR(100) = NULL,
    @ProfileImageUrl NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50013, N'User not found.', 1;

        UPDATE [dbo].[Users]
        SET
            [FirstName]       = COALESCE(@FirstName,       [FirstName]),
            [LastName]        = COALESCE(@LastName,        [LastName]),
            [ProfileImageUrl] = COALESCE(@ProfileImageUrl, [ProfileImageUrl]),
            [UpdatedAt]       = GETUTCDATE(),
            [UpdatedBy]       = @UserId
        WHERE [UserId] = @UserId;

        EXEC [dbo].[usp_Auth_User_GetProfile] @UserId = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
