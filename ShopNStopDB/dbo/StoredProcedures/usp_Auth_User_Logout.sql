CREATE PROCEDURE [dbo].[usp_Auth_User_Logout]
    @Token NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[RefreshTokens]
        SET    [IsRevoked] = 1
        WHERE  [Token] = @Token;

        SELECT @@ROWCOUNT AS [RevokedCount];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
