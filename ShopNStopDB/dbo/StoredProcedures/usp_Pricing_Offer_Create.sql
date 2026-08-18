CREATE PROCEDURE [dbo].[usp_Pricing_Offer_Create]
    @OfferName        NVARCHAR(200),
    @OfferType        TINYINT,        -- 1=Flat, 2=Percentage, 3=BOGO
    @DiscountValue    DECIMAL(18,2),
    @MaxDiscountCap   DECIMAL(18,2)   = NULL,
    @MinOrderValue    DECIMAL(18,2)   = 0.00,
    @ApplicableOn     TINYINT         = 4,  -- 1=Product, 2=Category, 3=Brand, 4=All
    @EntityId         INT             = NULL,
    @StartDate        DATE,
    @EndDate          DATE,
    @UsageLimitTotal  INT             = NULL,
    @CreatedBy        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @StartDate > @EndDate
            THROW 50170, N'StartDate must be before EndDate.', 1;

        IF @OfferType NOT IN (1, 2, 3)
            THROW 50171, N'Invalid offer type. Must be 1 (Flat), 2 (Percentage), or 3 (BOGO).', 1;

        INSERT INTO [dbo].[Offers]
            ([OfferName], [OfferType], [DiscountValue], [MaxDiscountCap],
             [MinOrderValue], [ApplicableOn], [EntityId],
             [StartDate], [EndDate], [UsageLimitTotal], [CurrentUsageCount],
             [IsActive], [CreatedAt], [CreatedBy], [IsDeleted])
        VALUES
            (@OfferName, @OfferType, @DiscountValue, @MaxDiscountCap,
             @MinOrderValue, @ApplicableOn, @EntityId,
             @StartDate, @EndDate, @UsageLimitTotal, 0,
             1, GETUTCDATE(), @CreatedBy, 0);

        SELECT SCOPE_IDENTITY() AS [OfferId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
