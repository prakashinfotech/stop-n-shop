CREATE PROCEDURE [dbo].[usp_Auth_User_ForgotPassword]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            u.[UserId],
            u.[Email],
            u.[FirstName],
            u.[IsEmailVerified]
        FROM [dbo].[Users] u
        WHERE u.[Email]     = @Email
          AND u.[IsDeleted] = 0
          AND u.[IsActive]  = 1;

        -- Deliberately returns empty if not found (prevents user-enumeration)

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
