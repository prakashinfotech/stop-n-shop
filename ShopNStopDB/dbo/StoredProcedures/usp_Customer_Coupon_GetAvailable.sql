CREATE PROCEDURE [dbo].[usp_Customer_Coupon_GetAvailable]
    @UserId INT = NULL    -- nullable so anonymous storefront previews work too
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            cp.[CouponId],
            cp.[CouponCode],
            o.[OfferName],
            o.[OfferType],          -- 1 = Flat, 2 = Percentage
            o.[DiscountValue],
            o.[MinOrderValue],
            o.[MaxDiscountCap],
            o.[ApplicableOn],       -- 1=Product, 2=Brand, 3=Category, 4=Cart
            o.[EntityId],
            b.[BrandName],
            o.[StartDate],
            o.[EndDate],
            o.[UsageLimitPerUser],
            -- per-user usage count so the UI can grey out exhausted coupons
            COALESCE((
                SELECT COUNT(*)
                FROM [dbo].[Orders] oh
                WHERE oh.[UserId]   = @UserId
                  AND oh.[CouponId] = cp.[CouponId]
                  AND oh.[IsDeleted] = 0
            ), 0) AS [UsedByUser]
        FROM [dbo].[Coupons] cp
        INNER JOIN [dbo].[Offers] o ON o.[OfferId] = cp.[OfferId]
        LEFT  JOIN [dbo].[Brands] b ON o.[ApplicableOn] = 2 AND b.[BrandId] = o.[EntityId]
        WHERE cp.[IsDeleted] = 0
          AND cp.[IsActive]  = 1
          AND o.[IsActive]   = 1
          AND o.[StartDate] <= GETUTCDATE()
          AND o.[EndDate]   >= GETUTCDATE()
          AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal])
        ORDER BY o.[EndDate] ASC, cp.[CouponCode] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
