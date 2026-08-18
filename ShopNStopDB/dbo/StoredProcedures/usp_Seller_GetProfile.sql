CREATE PROCEDURE [dbo].[usp_Seller_GetProfile]
    @SellerId INT = NULL,
    @UserId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            s.[SellerId],
            s.[UserId],
            s.[BusinessName],
            s.[GstNumber],
            s.[PanNumber],
            s.[BankName],
            s.[BankIfscCode],
            s.[ApprovalStatus],
            s.[CommissionRate],
            s.[IsActive],
            u.[Email],
            u.[FirstName],
            u.[LastName],
            u.[Mobile],
            u.[ProfileImageUrl],
            ua.[AddressLine1],
            ua.[City],
            ua.[State],
            ua.[PinCode]
        FROM [dbo].[Sellers]       s
        INNER JOIN [dbo].[Users]         u  ON u.[UserId]    = s.[UserId]
        LEFT  JOIN [dbo].[UserAddresses] ua ON ua.[AddressId] = s.[BusinessAddressId]
        WHERE s.[IsDeleted] = 0
          AND (s.[SellerId] = @SellerId OR @SellerId IS NULL)
          AND (s.[UserId]   = @UserId   OR @UserId   IS NULL);

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
