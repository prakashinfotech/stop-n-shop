CREATE PROCEDURE [dbo].[usp_Auth_User_GetProfile]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            u.[UserId],
            u.[Email],
            u.[Mobile],
            u.[FirstName],
            u.[LastName],
            u.[ProfileImageUrl],
            u.[RoleId],
            r.[RoleName],
            u.[IsEmailVerified],
            u.[IsMobileVerified],
            u.[IsApproved],
            u.[LoyaltyPoints],
            u.[ReferralCode],
            u.[CreatedAt]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[UserId]    = @UserId
          AND u.[IsDeleted] = 0
          AND u.[IsActive]  = 1;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
