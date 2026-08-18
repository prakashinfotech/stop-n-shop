CREATE PROCEDURE [dbo].[usp_Commerce_Cart_RemoveItem]
    @CartId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Cart] WHERE [CartId] = @CartId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50046, N'Cart item not found.', 1;

        UPDATE [dbo].[Cart]
        SET    [IsDeleted] = 1,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [CartId] = @CartId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
