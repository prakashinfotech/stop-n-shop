CREATE PROCEDURE [dbo].[usp_Catalog_Product_Update]
    @ProductId          INT,
    @ProductName        NVARCHAR(200),
    @ShortDescription   NVARCHAR(500)  = NULL,
    @LongDescription    NVARCHAR(MAX)  = NULL,
    @Sku                NVARCHAR(100),
    @SlugUrl            NVARCHAR(300),
    @MRP                DECIMAL(18,2),
    @SellingPrice       DECIMAL(18,2),
    @CostPrice          DECIMAL(18,2)  = NULL,
    @CategoryId         INT,
    @SubCategoryId      INT            = NULL,
    @BrandId            INT,
    @GenderTypeId       TINYINT        = NULL,
    @Tags               NVARCHAR(500)  = NULL,
    @IsFeatured         BIT            = 0,
    @Material           NVARCHAR(200)  = NULL,
    @CareInstructions   NVARCHAR(500)  = NULL,
    @FitType            NVARCHAR(50)   = NULL,
    @CountryOfOrigin    NVARCHAR(100)  = NULL,
    @WarrantyInfo       NVARCHAR(500)  = NULL,
    @DeliveryInfo       NVARCHAR(500)  = NULL,
    @LengthCm           DECIMAL(8,2)   = NULL,
    @WidthCm            DECIMAL(8,2)   = NULL,
    @HeightCm           DECIMAL(8,2)   = NULL,
    @WeightGm           DECIMAL(10,2)  = NULL,
    @UpdatedBy          INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50060, N'Product not found.', 1;

        IF EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [Sku] = @Sku AND [ProductId] <> @ProductId AND [IsDeleted] = 0
        )
            THROW 50061, N'A product with this SKU already exists.', 1;

        IF EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [SlugUrl] = @SlugUrl AND [ProductId] <> @ProductId AND [IsDeleted] = 0
        )
            THROW 50062, N'A product with this slug already exists.', 1;

        UPDATE [dbo].[Products]
        SET    [ProductName]      = @ProductName,
               [ShortDescription] = @ShortDescription,
               [LongDescription]  = @LongDescription,
               [Sku]              = @Sku,
               [SlugUrl]          = @SlugUrl,
               [MRP]              = @MRP,
               [SellingPrice]     = @SellingPrice,
               [CostPrice]        = COALESCE(@CostPrice, [CostPrice]),
               [CategoryId]       = @CategoryId,
               [SubCategoryId]    = @SubCategoryId,
               [BrandId]          = @BrandId,
               [GenderTypeId]     = @GenderTypeId,
               [Tags]             = @Tags,
               [IsFeatured]       = @IsFeatured,
               [Material]         = COALESCE(@Material,         [Material]),
               [CareInstructions] = COALESCE(@CareInstructions, [CareInstructions]),
               [FitType]          = COALESCE(@FitType,          [FitType]),
               [CountryOfOrigin]  = COALESCE(@CountryOfOrigin,  [CountryOfOrigin]),
               [WarrantyInfo]     = COALESCE(@WarrantyInfo,     [WarrantyInfo]),
               [DeliveryInfo]     = COALESCE(@DeliveryInfo,     [DeliveryInfo]),
               [LengthCm]         = COALESCE(@LengthCm,         [LengthCm]),
               [WidthCm]          = COALESCE(@WidthCm,          [WidthCm]),
               [HeightCm]         = COALESCE(@HeightCm,         [HeightCm]),
               [WeightGm]         = COALESCE(@WeightGm,         [WeightGm]),
               [UpdatedAt]        = GETUTCDATE(),
               [UpdatedBy]        = @UpdatedBy
        WHERE  [ProductId] = @ProductId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
