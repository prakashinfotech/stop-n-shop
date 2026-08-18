CREATE PROCEDURE [dbo].[usp_Pricing_OffersMaster_Get]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Today DATE = CAST(GETUTCDATE() AS DATE);

        -- Result set #1: storefront coupons (joined with their backing offer)
        SELECT
            c.[CouponCode],
            o.[OfferName],
            o.[OfferType],
            o.[DiscountValue],
            o.[MinOrderValue],
            o.[MaxDiscountCap],
            o.[EndDate]
        FROM [dbo].[Coupons] c
        INNER JOIN [dbo].[Offers] o ON o.[OfferId] = c.[OfferId]
        WHERE c.[IsDeleted] = 0
          AND c.[IsActive]  = 1
          AND o.[IsDeleted] = 0
          AND o.[IsActive]  = 1
          AND o.[StartDate] <= @Today
          AND o.[EndDate]   >= @Today
        ORDER BY o.[DiscountValue] DESC;

        -- Result set #2: payment / bank offers (informational)
        SELECT
            [BankOfferId],
            [Title],
            [Description],
            [MinSpend],
            [MaxDiscount],
            [TermsUrl],
            [SortOrder]
        FROM [dbo].[BankOffers]
        WHERE [IsDeleted] = 0
          AND [IsActive]  = 1
        ORDER BY [SortOrder] ASC, [BankOfferId] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
