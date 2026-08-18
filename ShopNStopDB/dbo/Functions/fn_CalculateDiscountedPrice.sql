CREATE FUNCTION [dbo].[fn_CalculateDiscountedPrice]
(
    @BasePrice     DECIMAL(18,2),
    @OfferType     TINYINT,        -- 1=Flat, 2=Percentage, 3=BOGO(treat as 0)
    @DiscountValue DECIMAL(18,2),
    @MaxDiscountCap DECIMAL(18,2)  -- NULL = no cap
)
RETURNS DECIMAL(18,2)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @Discount DECIMAL(18,2) = 0;

    IF @OfferType = 1        -- Flat
        SET @Discount = @DiscountValue;
    ELSE IF @OfferType = 2   -- Percentage
    BEGIN
        SET @Discount = @BasePrice * @DiscountValue / 100;
        IF @MaxDiscountCap IS NOT NULL AND @Discount > @MaxDiscountCap
            SET @Discount = @MaxDiscountCap;
    END;
    -- BOGO handled at order-placement level, not here

    DECLARE @FinalPrice DECIMAL(18,2) = @BasePrice - @Discount;
    RETURN CASE WHEN @FinalPrice < 0 THEN 0 ELSE @FinalPrice END;
END;
GO
