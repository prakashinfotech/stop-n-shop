CREATE PROCEDURE [dbo].[usp_Admin_Coupon_Create]
    @CouponCode      NVARCHAR(50),
    @OfferName       NVARCHAR(300),
    @OfferType       TINYINT,           -- 1=Flat, 2=Percentage
    @DiscountValue   DECIMAL(18,2),
    @MinOrderValue   DECIMAL(18,2) = 0,
    @MaxDiscountCap  DECIMAL(18,2) = NULL,
    @StartDate       DATETIME2(0),
    @EndDate         DATETIME2(0),
    @ApplicableOn    TINYINT = 4,       -- 1=Product, 2=Brand, 3=Category, 4=Cart
    @EntityId        INT = NULL,
    @UsageLimitPerUser TINYINT = 1,
    @AdminUserId     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Coupons] WHERE [CouponCode] = @CouponCode AND [IsDeleted] = 0)
            THROW 50080, N'A coupon with this code already exists.', 1;

        IF @ApplicableOn = 2 AND @EntityId IS NULL
            THROW 50081, N'Brand-specific coupons require a brand id.', 1;

        BEGIN TRANSACTION;

        INSERT INTO [dbo].[Offers]
            ([OfferName], [OfferType], [DiscountValue], [MinOrderValue], [MaxDiscountCap],
             [StartDate], [EndDate], [ApplicableOn], [EntityId], [UsageLimitPerUser], [CreatedBy])
        VALUES
            (@OfferName, @OfferType, @DiscountValue, @MinOrderValue, @MaxDiscountCap,
             @StartDate, @EndDate, @ApplicableOn, @EntityId, @UsageLimitPerUser, @AdminUserId);

        DECLARE @NewOfferId INT = SCOPE_IDENTITY();

        INSERT INTO [dbo].[Coupons] ([CouponCode], [OfferId], [CreatedBy])
        VALUES (@CouponCode, @NewOfferId, @AdminUserId);

        DECLARE @NewCouponId INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NewCouponId AS [CouponId];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
