CREATE PROCEDURE [dbo].[usp_Commerce_Cart_Clear]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[Cart]
        SET    [IsDeleted] = 1,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [UserId] = @UserId AND [IsDeleted] = 0;

        SELECT @@ROWCOUNT AS [ClearedCount];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
