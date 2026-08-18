CREATE PROCEDURE [dbo].[usp_Auth_RefreshToken_Create]
    @UserId     INT,
    @Token      NVARCHAR(500),
    @ExpiresAt  DATETIME2(0),
    @DeviceInfo NVARCHAR(300) = NULL,
    @IpAddress  NVARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [dbo].[RefreshTokens]
            ([UserId], [Token], [ExpiresAt], [DeviceInfo], [IpAddress])
        VALUES
            (@UserId, @Token, @ExpiresAt, @DeviceInfo, @IpAddress);

        SELECT SCOPE_IDENTITY() AS [TokenId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
