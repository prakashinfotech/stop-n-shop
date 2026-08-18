CREATE PROCEDURE [dbo].[sp_SellerCompleteOnboarding]
    @SellerId           INT,
    @OwnerFullName      NVARCHAR(200),
    @DisplayName        NVARCHAR(200),
    @StoreDescription   NVARCHAR(MAX),
    @IsPhoneVerified    BIT,
    @IsEmailVerified    BIT,
    @IsIdVerified       BIT,
    @SelectedCategories NVARCHAR(MAX) = NULL,
    @PickupAddressLine1 NVARCHAR(300) = NULL,
    @PickupAddressLine2 NVARCHAR(300) = NULL,
    @PickupCity         NVARCHAR(100) = NULL,
    @PickupState        NVARCHAR(100) = NULL,
    @PickupPincode      NVARCHAR(10)  = NULL,
    @PickupLandmark     NVARCHAR(200) = NULL
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
                [OwnerName]           = @OwnerFullName,
                [DisplayName]         = @DisplayName,
                [StoreDescription]    = @StoreDescription,
                [IsIdVerified]        = @IsIdVerified,
                [OnboardingCompleted] = 1,
                [SelectedCategories]  = @SelectedCategories,
                [PickupAddressLine1]  = @PickupAddressLine1,
                [PickupAddressLine2]  = @PickupAddressLine2,
                [PickupCity]          = @PickupCity,
                [PickupState]         = @PickupState,
                [PickupPincode]       = @PickupPincode,
                [PickupLandmark]      = @PickupLandmark,
                [UpdatedAt]           = GETUTCDATE(),
                [UpdatedBy]           = @SellerId
            WHERE [SellerId] = @SellerId;

            UPDATE [dbo].[Users]
            SET
                [IsMobileVerified] = @IsPhoneVerified,
                [IsEmailVerified]  = @IsEmailVerified,
                [UpdatedAt]        = GETUTCDATE()
            WHERE [UserId] = @UserId;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
