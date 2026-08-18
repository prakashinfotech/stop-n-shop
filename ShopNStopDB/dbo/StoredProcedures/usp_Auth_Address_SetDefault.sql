CREATE PROCEDURE [dbo].[usp_Auth_Address_SetDefault]
    @AddressId INT,
    @UserId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserAddresses] WHERE [AddressId] = @AddressId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50016, N'Address not found.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[UserAddresses]
            SET    [IsDefault] = 0, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UserId
            WHERE  [UserId] = @UserId AND [IsDeleted] = 0;

            UPDATE [dbo].[UserAddresses]
            SET    [IsDefault] = 1, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UserId
            WHERE  [AddressId] = @AddressId;

        COMMIT TRANSACTION;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
