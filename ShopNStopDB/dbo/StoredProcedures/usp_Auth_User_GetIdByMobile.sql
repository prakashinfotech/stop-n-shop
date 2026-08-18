CREATE PROCEDURE [dbo].[usp_Auth_User_GetIdByMobile]
    @Mobile NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT [UserId]
        FROM   [dbo].[Users]
        WHERE  [Mobile]     = @Mobile
          AND  [IsDeleted]  = 0
          AND  [IsActive]   = 1;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
