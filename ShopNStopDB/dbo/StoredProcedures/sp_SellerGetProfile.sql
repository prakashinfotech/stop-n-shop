CREATE PROCEDURE [dbo].[sp_SellerGetProfile]
    @SellerId INT
AS
BEGIN
    SET NOCOUNT ON;

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
    WHERE s.[SellerId]  = @SellerId
      AND s.[IsDeleted] = 0;
END;
GO
