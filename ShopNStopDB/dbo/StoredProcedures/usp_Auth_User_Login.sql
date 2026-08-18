CREATE PROCEDURE [dbo].[usp_Auth_User_Login]
    @Email     NVARCHAR(256),
    @IpAddress NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @UserId INT;
        DECLARE @RoleId INT;

        SELECT @UserId = [UserId], @RoleId = [RoleId]
        FROM   [dbo].[Users]
        WHERE  [Email]     = @Email
          AND  [IsDeleted] = 0
          AND  [IsActive]  = 1;

        IF @UserId IS NULL
            THROW 50003, N'User not found or account is inactive.', 1;

        -- Single shared SP for all role-specific login endpoints (Buyer,
        -- Admin, Seller, Dispatcher). The role check happens in the
        -- controller layer (each endpoint validates result.User.Role
        -- against its expected role and rejects mismatches).
        IF @RoleId NOT IN (1, 2, 3, 4)
            THROW 50004, N'This account role is not recognised.', 1;

        UPDATE [dbo].[Users]
        SET    [LastLoginAt] = GETUTCDATE(),
               [UpdatedAt]   = GETUTCDATE()
        WHERE  [UserId] = @UserId;

        SELECT
            u.[UserId],
            u.[Email],
            u.[PasswordHash],
            u.[FirstName],
            u.[LastName],
            u.[Mobile],
            u.[RoleId],
            r.[RoleName],
            u.[ProfileImageUrl],
            u.[IsEmailVerified],
            u.[IsMobileVerified],
            u.[IsApproved],
            u.[IsActive],
            u.[IsFirstLogin],
            u.[LoyaltyPoints]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[UserId] = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
