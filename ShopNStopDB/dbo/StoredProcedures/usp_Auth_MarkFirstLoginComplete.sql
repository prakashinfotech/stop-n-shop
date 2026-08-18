CREATE PROCEDURE [dbo].[usp_Auth_MarkFirstLoginComplete]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [dbo].[Users]
    SET IsFirstLogin = 0, UpdatedAt = GETUTCDATE()
    WHERE UserId = @UserId;
END;
GO
