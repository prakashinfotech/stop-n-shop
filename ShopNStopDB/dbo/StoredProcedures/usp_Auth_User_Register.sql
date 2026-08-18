CREATE PROCEDURE [dbo].[usp_Auth_User_Register]
    @Email        NVARCHAR(256),
    @PasswordHash NVARCHAR(500),
    @FirstName    NVARCHAR(100) = NULL,
    @LastName     NVARCHAR(100) = NULL,
    @Mobile       NVARCHAR(15)  = NULL,
    @RoleId       TINYINT       = 2          -- 2=Buyer (default)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Email] = @Email AND [IsDeleted] = 0)
            THROW 50001, N'Email address is already registered.', 1;

        IF @Mobile IS NOT NULL AND EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Mobile] = @Mobile AND [IsDeleted] = 0)
            THROW 50002, N'Mobile number is already registered.', 1;

        DECLARE @NewReferralCode NVARCHAR(20) = UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''), 8));
        DECLARE @IsApproved BIT = CASE WHEN @RoleId IN (2) THEN 1 ELSE 0 END; -- Buyers auto-approved; sellers/admins need approval
        DECLARE @NewUserId INT;

        BEGIN TRANSACTION;

            INSERT INTO [dbo].[Users]
                ([Email], [PasswordHash], [FirstName], [LastName], [Mobile], [RoleId], [IsApproved], [ReferralCode])
            VALUES
                (@Email, @PasswordHash, @FirstName, @LastName, @Mobile, @RoleId, @IsApproved, @NewReferralCode);

            SET @NewUserId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            u.[UserId],
            u.[Email],
            u.[FirstName],
            u.[LastName],
            u.[Mobile],
            u.[RoleId],
            r.[RoleName],
            u.[IsEmailVerified],
            u.[IsMobileVerified],
            u.[IsApproved],
            u.[ReferralCode],
            u.[CreatedAt]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[UserId] = @NewUserId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
