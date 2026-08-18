CREATE PROCEDURE [dbo].[usp_Admin_Coupon_Update]
    @CouponId          INT,
    @CouponCode        NVARCHAR(50),
    @OfferName         NVARCHAR(300),
    @OfferType         TINYINT,
    @DiscountValue     DECIMAL(18,2),
    @MinOrderValue     DECIMAL(18,2) = 0,
    @MaxDiscountCap    DECIMAL(18,2) = NULL,
    @StartDate         DATETIME2(0),
    @EndDate           DATETIME2(0),
    @ApplicableOn      TINYINT = 4,
    @EntityId          INT = NULL,
    @UsageLimitPerUser TINYINT = 1,
    @AdminUserId       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @OfferId INT;
        SELECT @OfferId = [OfferId]
        FROM   [dbo].[Coupons]
        WHERE  [CouponId] = @CouponId AND [IsDeleted] = 0;

        IF @OfferId IS NULL
            THROW 50090, N'Coupon not found.', 1;

        IF EXISTS (
            SELECT 1 FROM [dbo].[Coupons]
            WHERE [CouponCode] = @CouponCode AND [CouponId] <> @CouponId AND [IsDeleted] = 0)
            THROW 50091, N'Another coupon already uses this code.', 1;

        IF @ApplicableOn = 2 AND @EntityId IS NULL
            THROW 50092, N'Brand-specific coupons require a brand id.', 1;

        BEGIN TRANSACTION;

        UPDATE [dbo].[Coupons]
        SET    [CouponCode] = @CouponCode,
               [UpdatedAt]  = GETUTCDATE(),
               [UpdatedBy]  = @AdminUserId
        WHERE  [CouponId]   = @CouponId;

        UPDATE [dbo].[Offers]
        SET    [OfferName]         = @OfferName,
               [OfferType]         = @OfferType,
               [DiscountValue]     = @DiscountValue,
               [MinOrderValue]     = @MinOrderValue,
               [MaxDiscountCap]    = @MaxDiscountCap,
               [StartDate]         = @StartDate,
               [EndDate]           = @EndDate,
               [ApplicableOn]      = @ApplicableOn,
               [EntityId]          = @EntityId,
               [UsageLimitPerUser] = @UsageLimitPerUser,
               [UpdatedAt]         = GETUTCDATE(),
               [UpdatedBy]         = @AdminUserId
        WHERE  [OfferId]           = @OfferId;

        COMMIT TRANSACTION;

        SELECT 1 AS [Success];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
