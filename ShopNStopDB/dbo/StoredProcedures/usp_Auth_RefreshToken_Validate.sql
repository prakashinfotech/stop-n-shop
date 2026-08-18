CREATE PROCEDURE [dbo].[usp_Auth_RefreshToken_Validate]
    @Token NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TokenId   INT;
        DECLARE @UserId    INT;
        DECLARE @ExpiresAt DATETIME2(0);
        DECLARE @IsRevoked BIT;

        SELECT
            @TokenId   = rt.[TokenId],
            @UserId    = rt.[UserId],
            @ExpiresAt = rt.[ExpiresAt],
            @IsRevoked = rt.[IsRevoked]
        FROM [dbo].[RefreshTokens] rt
        WHERE rt.[Token] = @Token;

        IF @TokenId IS NULL
            THROW 50010, N'Refresh token not found.', 1;

        IF @IsRevoked = 1
            THROW 50011, N'Refresh token has been revoked.', 1;

        IF @ExpiresAt < GETUTCDATE()
        BEGIN
            UPDATE [dbo].[RefreshTokens] SET [IsRevoked] = 1 WHERE [TokenId] = @TokenId;
            THROW 50012, N'Refresh token has expired.', 1;
        END;

        SELECT
            u.[UserId],
            u.[Email],
            u.[RoleId],
            r.[RoleName],
            u.[IsActive],
            u.[IsApproved],
            u.[IsDeleted]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[UserId] = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
