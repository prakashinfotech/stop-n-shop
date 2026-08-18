CREATE PROCEDURE [dbo].[usp_Auth_Address_GetByUser]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            [AddressId], [UserId], [Label], [AddressLine1], [AddressLine2],
            [City], [State], [PinCode], [Country], [Latitude], [Longitude], [IsDefault]
        FROM [dbo].[UserAddresses]
        WHERE [UserId]    = @UserId
          AND [IsDeleted] = 0
          AND [IsActive]  = 1
        ORDER BY [IsDefault] DESC, [CreatedAt] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
