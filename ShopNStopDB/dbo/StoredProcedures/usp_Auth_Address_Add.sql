CREATE PROCEDURE [dbo].[usp_Auth_Address_Add]
    @UserId       INT,
    @Label        NVARCHAR(50)  = NULL,
    @AddressLine1 NVARCHAR(300),
    @AddressLine2 NVARCHAR(300) = NULL,
    @City         NVARCHAR(100),
    @State        NVARCHAR(100),
    @PinCode      NVARCHAR(10),
    @Country      NVARCHAR(100) = N'India',
    @Latitude     DECIMAL(9,6)  = NULL,
    @Longitude    DECIMAL(9,6)  = NULL,
    @IsDefault    BIT           = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF @IsDefault = 1
                UPDATE [dbo].[UserAddresses]
                SET    [IsDefault] = 0, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UserId
                WHERE  [UserId] = @UserId AND [IsDeleted] = 0;

            INSERT INTO [dbo].[UserAddresses]
                ([UserId], [Label], [AddressLine1], [AddressLine2], [City], [State], [PinCode], [Country], [Latitude], [Longitude], [IsDefault], [CreatedBy], [UpdatedBy])
            VALUES
                (@UserId, @Label, @AddressLine1, @AddressLine2, @City, @State, @PinCode, @Country, @Latitude, @Longitude, @IsDefault, @UserId, @UserId);

            DECLARE @NewAddressId INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            [AddressId], [UserId], [Label], [AddressLine1], [AddressLine2],
            [City], [State], [PinCode], [Country], [Latitude], [Longitude], [IsDefault]
        FROM [dbo].[UserAddresses]
        WHERE [AddressId] = @NewAddressId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
