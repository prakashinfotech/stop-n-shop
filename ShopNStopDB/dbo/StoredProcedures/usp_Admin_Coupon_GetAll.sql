CREATE PROCEDURE [dbo].[usp_Admin_Coupon_GetAll]
    @Page     INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@Page - 1) * @PageSize;

        SELECT
            cp.[CouponId],
            cp.[CouponCode],
            cp.[IsActive],
            o.[OfferId],
            o.[OfferName],
            o.[OfferType],         -- 1=Flat, 2=Percentage
            o.[DiscountValue],
            o.[MinOrderValue],
            o.[MaxDiscountCap],
            o.[StartDate],
            o.[EndDate],
            o.[ApplicableOn],      -- 1=Product, 2=Brand, 3=Category, 4=Cart
            o.[EntityId],
            b.[BrandName],
            o.[UsageLimitPerUser],
            o.[CurrentUsageCount],
            cp.[CreatedAt],
            COUNT(*) OVER() AS [TotalCount]
        FROM [dbo].[Coupons] cp
        INNER JOIN [dbo].[Offers] o ON o.[OfferId] = cp.[OfferId]
        LEFT  JOIN [dbo].[Brands] b ON o.[ApplicableOn] = 2 AND b.[BrandId] = o.[EntityId]
        WHERE cp.[IsDeleted] = 0
        ORDER BY cp.[CouponId] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
