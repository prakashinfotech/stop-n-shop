-- Master offers seed: storefront coupon + payment-method bank offers.
-- Idempotent via MERGE on stable natural keys (CouponCode for coupons, Title for bank offers).

DECLARE @Start DATETIME2(0) = '2025-01-01 00:00:00';
DECLARE @End   DATETIME2(0) = '2030-12-31 23:59:59';

-- ── 1. Storefront coupon STOPNSHOP300 (Rs.245 off, min order Rs.1499) ─────────
DECLARE @OfferId INT;

MERGE [dbo].[Offers] AS tgt
USING (VALUES
    (N'STOPNSHOP300 - Rs. 245 off on first purchase', 1, 245.00, 1499.00, NULL, @Start, @End, 4)
) AS src ([OfferName], [OfferType], [DiscountValue], [MinOrderValue], [MaxDiscountCap], [StartDate], [EndDate], [ApplicableOn])
ON tgt.[OfferName] = src.[OfferName]
WHEN MATCHED THEN UPDATE SET
    tgt.[OfferType]      = src.[OfferType],
    tgt.[DiscountValue]  = src.[DiscountValue],
    tgt.[MinOrderValue]  = src.[MinOrderValue],
    tgt.[MaxDiscountCap] = src.[MaxDiscountCap],
    tgt.[StartDate]      = src.[StartDate],
    tgt.[EndDate]        = src.[EndDate],
    tgt.[ApplicableOn]   = src.[ApplicableOn],
    tgt.[IsActive]       = 1,
    tgt.[IsDeleted]      = 0,
    tgt.[UpdatedAt]      = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT
    ([OfferName], [OfferType], [DiscountValue], [MinOrderValue], [MaxDiscountCap], [StartDate], [EndDate], [ApplicableOn])
VALUES
    (src.[OfferName], src.[OfferType], src.[DiscountValue], src.[MinOrderValue], src.[MaxDiscountCap], src.[StartDate], src.[EndDate], src.[ApplicableOn]);

SELECT @OfferId = [OfferId]
FROM [dbo].[Offers]
WHERE [OfferName] = N'STOPNSHOP300 - Rs. 245 off on first purchase';

MERGE [dbo].[Coupons] AS tgt
USING (VALUES (N'STOPNSHOP300', @OfferId)) AS src ([CouponCode], [OfferId])
ON tgt.[CouponCode] = src.[CouponCode]
WHEN MATCHED THEN UPDATE SET
    tgt.[OfferId]   = src.[OfferId],
    tgt.[IsActive]  = 1,
    tgt.[IsDeleted] = 0,
    tgt.[UpdatedAt] = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT
    ([CouponCode], [OfferId])
VALUES
    (src.[CouponCode], src.[OfferId]);

-- ── 2. Bank / payment offers (informational; no checkout logic) ──────────────
MERGE [dbo].[BankOffers] AS tgt
USING (VALUES
    (N'10% Instant Discount on Axis Bank Credit Card',                                              2500.00,   300.00,  10),
    (N'10% Instant Discount on BOBCARD Credit Card',                                                3500.00,  1000.00,  20),
    (N'10% Instant Discount on BOBCARD Credit Card EMI',                                            3500.00,  1200.00,  30),
    (N'10% Instant Discount on HSBC Credit Card',                                                   3500.00,  1000.00,  40),
    (N'10% Instant Discount on RBL Bank Credit Card & Credit Card EMI',                             3500.00,  1000.00,  50),
    (N'10% Instant Discount on Axis Bank Credit Card EMI - only Luxe Products',                     2999.00,  1000.00,  60),
    (N'Flat 7.5% Cashback + 2.5% Instant Discount on Flipkart Axis Bank & SBI Credit Cards',        2000.00,   250.00,  70)
) AS src ([Title], [MinSpend], [MaxDiscount], [SortOrder])
ON tgt.[Title] = src.[Title]
WHEN MATCHED THEN UPDATE SET
    tgt.[MinSpend]    = src.[MinSpend],
    tgt.[MaxDiscount] = src.[MaxDiscount],
    tgt.[SortOrder]   = src.[SortOrder],
    tgt.[IsActive]    = 1,
    tgt.[IsDeleted]   = 0,
    tgt.[UpdatedAt]   = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT
    ([Title], [MinSpend], [MaxDiscount], [SortOrder])
VALUES
    (src.[Title], src.[MinSpend], src.[MaxDiscount], src.[SortOrder]);
GO
