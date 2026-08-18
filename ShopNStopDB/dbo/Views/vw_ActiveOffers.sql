CREATE VIEW [dbo].[vw_ActiveOffers]
AS
SELECT
    o.[OfferId],
    o.[OfferName],
    o.[OfferType],
    o.[DiscountValue],
    o.[MinOrderValue],
    o.[MaxDiscountCap],
    o.[StartDate],
    o.[EndDate],
    o.[ApplicableOn],
    o.[EntityId],
    o.[UsageLimitTotal],
    o.[UsageLimitPerUser],
    o.[CurrentUsageCount],

    -- Associated coupon code (if any)
    cp.[CouponId],
    cp.[CouponCode]

FROM [dbo].[Offers]   o
LEFT JOIN [dbo].[Coupons] cp ON cp.[OfferId] = o.[OfferId] AND cp.[IsDeleted] = 0 AND cp.[IsActive] = 1

WHERE
    o.[IsDeleted]  = 0
    AND o.[IsActive]  = 1
    AND o.[StartDate] <= GETUTCDATE()
    AND o.[EndDate]   >= GETUTCDATE()
    AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal]);
GO
