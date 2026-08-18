CREATE PROCEDURE [dbo].[usp_Pricing_Offer_GetActive]
    @ProductId  INT = NULL,
    @CategoryId INT = NULL,
    @BrandId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Today DATE = CAST(GETUTCDATE() AS DATE);

        SELECT
            o.[OfferId],
            o.[OfferName],
            o.[OfferType],
            o.[DiscountValue],
            o.[MaxDiscountCap],
            o.[MinOrderValue],
            o.[ApplicableOn],
            o.[EntityId],
            o.[StartDate],
            o.[EndDate],
            o.[UsageLimitTotal],
            o.[CurrentUsageCount]
        FROM [dbo].[Offers] o
        WHERE o.[IsDeleted] = 0
          AND o.[IsActive]  = 1
          AND o.[StartDate] <= @Today
          AND o.[EndDate]   >= @Today
          AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal])
          AND (
              @ProductId  IS NULL
           OR @CategoryId IS NULL
           OR @BrandId    IS NULL
           OR (o.[ApplicableOn] = 1 AND o.[EntityId] = @ProductId)
           OR (o.[ApplicableOn] = 2 AND o.[EntityId] = @CategoryId)
           OR (o.[ApplicableOn] = 3 AND o.[EntityId] = @BrandId)
           OR  o.[ApplicableOn] = 4
          )
        ORDER BY o.[DiscountValue] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
