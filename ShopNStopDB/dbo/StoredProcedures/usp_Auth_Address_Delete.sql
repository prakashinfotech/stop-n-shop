CREATE PROCEDURE [dbo].[usp_Auth_Address_Delete]
    @AddressId INT,
    @UserId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserAddresses] WHERE [AddressId] = @AddressId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50015, N'Address not found.', 1;

        UPDATE [dbo].[UserAddresses]
        SET    [IsDeleted] = 1,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [AddressId] = @AddressId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
