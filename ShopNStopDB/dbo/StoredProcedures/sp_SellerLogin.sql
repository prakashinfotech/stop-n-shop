CREATE PROCEDURE [dbo].[sp_SellerLogin]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @UserId INT;
        DECLARE @RoleId INT;

        -- First check if user exists and get their role
        SELECT @UserId = [UserId], @RoleId = [RoleId]
        FROM   [dbo].[Users]
        WHERE  [Email]     = @Email
          AND  [IsDeleted] = 0
          AND  [IsActive]  = 1;

        IF @UserId IS NULL
            THROW 50003, N'User not found or account is inactive.', 1;

        -- Validate that user is a Seller (RoleId = 3)
        IF @RoleId != 3
            THROW 50005, N'This account is not a seller account. Please use the appropriate login page.', 1;

        -- Check if seller profile exists
        DECLARE @SellerId INT;
        SELECT @SellerId = [SellerId]
        FROM [dbo].[Sellers]
        WHERE [UserId] = @UserId
          AND [IsDeleted] = 0;

        IF @SellerId IS NULL
            THROW 50006, N'Seller profile not found. Please complete your seller registration.', 1;

        SELECT
            s.[SellerId]                                                     AS [Id],
            NULLIF(s.[BusinessName], N'')                                    AS [BusinessName],
            s.[OwnerName],
            u.[Email],
            u.[Mobile]                                                       AS [PhoneNumber],
            s.[GstNumber]                                                    AS [GSTNumber],
            s.[Address],
            s.[City],
            s.[State],
            s.[Pincode],
            s.[DisplayName],
            s.[StoreDescription],
            s.[BannerUrl],
            s.[LogoUrl],
            s.[SupportEmail],
            s.[SupportPhone],
            s.[Description],
            u.[IsMobileVerified]                                             AS [IsPhoneVerified],
            u.[IsEmailVerified],
            s.[IsIdVerified],
            s.[OnboardingCompleted],
            s.[PickupAddressLine1],
            s.[PickupAddressLine2],
            s.[PickupCity],
            s.[PickupState],
            s.[PickupPincode],
            s.[PickupLandmark],
            s.[SelectedCategories],
            s.[IsActive],
            CAST(CASE WHEN s.[ApprovalStatus] = 2 THEN 1 ELSE 0 END AS BIT) AS [IsApproved],
            s.[CreatedAt],
            s.[UpdatedAt],
            u.[PasswordHash]
        FROM [dbo].[Sellers] s
        INNER JOIN [dbo].[Users] u ON u.[UserId] = s.[UserId]
        WHERE u.[Email]     = @Email
          AND u.[IsDeleted] = 0
          AND s.[IsDeleted] = 0;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
