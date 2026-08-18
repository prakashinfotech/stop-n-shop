CREATE PROCEDURE [dbo].[usp_Commerce_Coupon_Validate]
    @CouponCode   NVARCHAR(50),
    @UserId       INT,
    @OrderSubTotal DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @OfferId          INT;
        DECLARE @OfferType        TINYINT;
        DECLARE @DiscountValue    DECIMAL(18,2);
        DECLARE @MinOrderValue    DECIMAL(18,2);
        DECLARE @MaxDiscountCap   DECIMAL(18,2);
        DECLARE @UsageLimitPerUser TINYINT;
        DECLARE @CouponId         INT;

        SELECT
            @CouponId          = cp.[CouponId],
            @OfferId           = o.[OfferId],
            @OfferType         = o.[OfferType],
            @DiscountValue     = o.[DiscountValue],
            @MinOrderValue     = o.[MinOrderValue],
            @MaxDiscountCap    = o.[MaxDiscountCap],
            @UsageLimitPerUser = o.[UsageLimitPerUser]
        FROM [dbo].[Coupons] cp
        INNER JOIN [dbo].[Offers] o ON o.[OfferId] = cp.[OfferId]
        WHERE cp.[CouponCode] = @CouponCode
          AND cp.[IsDeleted]  = 0
          AND cp.[IsActive]   = 1
          AND o.[IsDeleted]   = 0
          AND o.[IsActive]    = 1
          AND o.[StartDate]   <= GETUTCDATE()
          AND o.[EndDate]     >= GETUTCDATE()
          AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal]);

        IF @CouponId IS NULL
            THROW 50063, N'Invalid or expired coupon code.', 1;

        IF @OrderSubTotal < @MinOrderValue
            THROW 50064, N'Order does not meet the minimum value required for this coupon.', 1;

        DECLARE @UserUsage INT = (
            SELECT COUNT(*) FROM [dbo].[Orders]
            WHERE [UserId] = @UserId AND [CouponId] = @CouponId AND [IsDeleted] = 0
        );
        IF @UserUsage >= @UsageLimitPerUser
            THROW 50065, N'You have already used this coupon the maximum number of times.', 1;

        DECLARE @DiscountAmount DECIMAL(18,2) =
            @OrderSubTotal - [dbo].[fn_CalculateDiscountedPrice](@OrderSubTotal, @OfferType, @DiscountValue, @MaxDiscountCap);

        SELECT
            @CouponId       AS [CouponId],
            @CouponCode     AS [CouponCode],
            @DiscountAmount AS [DiscountAmount],
            @OfferType      AS [OfferType],
            1               AS [IsValid];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
