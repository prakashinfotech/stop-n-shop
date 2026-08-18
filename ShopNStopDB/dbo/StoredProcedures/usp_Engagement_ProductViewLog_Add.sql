CREATE PROCEDURE [dbo].[usp_Engagement_ProductViewLog_Add]
    @ProductId  INT,
    @UserId     INT            = NULL,
    @SessionId  NVARCHAR(100),
    @IpAddress  NVARCHAR(50)   = NULL,
    @DeviceType NVARCHAR(50)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [dbo].[ProductViewLogs]
            ([ProductId], [UserId], [SessionId], [IpAddress], [DeviceType], [ViewedAt])
        VALUES
            (@ProductId, @UserId, @SessionId, @IpAddress, @DeviceType, GETUTCDATE());

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
