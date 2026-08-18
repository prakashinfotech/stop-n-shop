CREATE PROCEDURE [dbo].[usp_Commerce_Wishlist_Remove]
    @UserId    INT,
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[Wishlist]
        SET    [IsDeleted] = 1,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [UserId]    = @UserId
          AND  [ProductId] = @ProductId
          AND  [IsDeleted] = 0;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
