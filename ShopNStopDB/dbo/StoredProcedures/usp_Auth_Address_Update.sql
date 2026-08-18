CREATE PROCEDURE [dbo].[usp_Auth_Address_Update]
    @AddressId    INT,
    @UserId       INT,
    @Label        NVARCHAR(50)  = NULL,
    @AddressLine1 NVARCHAR(300) = NULL,
    @AddressLine2 NVARCHAR(300) = NULL,
    @City         NVARCHAR(100) = NULL,
    @State        NVARCHAR(100) = NULL,
    @PinCode      NVARCHAR(10)  = NULL,
    @Country      NVARCHAR(100) = NULL,
    @Latitude     DECIMAL(9,6)  = NULL,
    @Longitude    DECIMAL(9,6)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserAddresses] WHERE [AddressId] = @AddressId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50014, N'Address not found.', 1;

        UPDATE [dbo].[UserAddresses]
        SET
            [Label]        = COALESCE(@Label,        [Label]),
            [AddressLine1] = COALESCE(@AddressLine1, [AddressLine1]),
            [AddressLine2] = COALESCE(@AddressLine2, [AddressLine2]),
            [City]         = COALESCE(@City,         [City]),
            [State]        = COALESCE(@State,        [State]),
            [PinCode]      = COALESCE(@PinCode,      [PinCode]),
            [Country]      = COALESCE(@Country,      [Country]),
            [Latitude]     = COALESCE(@Latitude,     [Latitude]),
            [Longitude]    = COALESCE(@Longitude,    [Longitude]),
            [UpdatedAt]    = GETUTCDATE(),
            [UpdatedBy]    = @UserId
        WHERE [AddressId] = @AddressId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
