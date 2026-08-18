CREATE PROCEDURE [dbo].[sp_SellerUpdateProfile]
    @SellerId     INT,
    @BusinessName NVARCHAR(300) = NULL,
    @OwnerName    NVARCHAR(200) = NULL,
    @PhoneNumber  NVARCHAR(15)  = NULL,
    @GSTNumber    NVARCHAR(20)  = NULL,
    @Address      NVARCHAR(300) = NULL,
    @City         NVARCHAR(100) = NULL,
    @State        NVARCHAR(100) = NULL,
    @Pincode      NVARCHAR(10)  = NULL,
    @BannerUrl    NVARCHAR(500) = NULL,
    @LogoUrl      NVARCHAR(500) = NULL,
    @SupportEmail NVARCHAR(256) = NULL,
    @SupportPhone NVARCHAR(20)  = NULL,
    @Description  NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @UserId INT;
        SELECT @UserId = [UserId]
        FROM   [dbo].[Sellers]
        WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0;

        IF @UserId IS NULL
            THROW 50095, N'Seller not found.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[Sellers]
            SET
                [BusinessName] = ISNULL(@BusinessName, [BusinessName]),
                [OwnerName]    = ISNULL(@OwnerName,    [OwnerName]),
                [GstNumber]    = ISNULL(@GSTNumber,    [GstNumber]),
                [Address]      = ISNULL(@Address,      [Address]),
                [City]         = ISNULL(@City,         [City]),
                [State]        = ISNULL(@State,        [State]),
                [Pincode]      = ISNULL(@Pincode,      [Pincode]),
                [BannerUrl]    = ISNULL(@BannerUrl,    [BannerUrl]),
                [LogoUrl]      = ISNULL(@LogoUrl,      [LogoUrl]),
                [SupportEmail] = ISNULL(@SupportEmail, [SupportEmail]),
                [SupportPhone] = ISNULL(@SupportPhone, [SupportPhone]),
                [Description]  = ISNULL(@Description,  [Description]),
                [UpdatedAt]    = GETUTCDATE(),
                [UpdatedBy]    = @SellerId
            WHERE [SellerId] = @SellerId;

            IF @PhoneNumber IS NOT NULL
                UPDATE [dbo].[Users]
                SET    [Mobile]    = @PhoneNumber,
                       [UpdatedAt] = GETUTCDATE()
                WHERE  [UserId] = @UserId;

        COMMIT TRANSACTION;

        -- Return updated profile
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
            s.[UpdatedAt]
        FROM [dbo].[Sellers] s
        INNER JOIN [dbo].[Users] u ON u.[UserId] = s.[UserId]
        WHERE s.[SellerId] = @SellerId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
