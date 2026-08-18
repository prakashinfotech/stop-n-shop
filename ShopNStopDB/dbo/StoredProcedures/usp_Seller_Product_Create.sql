CREATE PROCEDURE [dbo].[usp_Seller_Product_Create]
    @SellerId           INT,
    @BrandId            INT            = 1,
    @CategoryId         INT,
    @SubCategoryId      INT            = NULL,
    @GenderTypeId       TINYINT        = NULL,
    @ProductName        NVARCHAR(200),
    @ShortDescription   NVARCHAR(500)  = NULL,
    @LongDescription    NVARCHAR(MAX)  = NULL,
    @Sku                NVARCHAR(100),
    @SlugUrl            NVARCHAR(300),
    @MRP                DECIMAL(18,2),
    @SellingPrice       DECIMAL(18,2),
    @CostPrice          DECIMAL(18,2)  = NULL,
    @Tags               NVARCHAR(500)  = NULL,
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
    @CreatedBy          INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50100, N'Seller not found.', 1;

        IF EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [Sku] = @Sku AND [IsDeleted] = 0)
            THROW 50101, N'A product with this SKU already exists.', 1;

        IF EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0)
            THROW 50102, N'A product with this slug already exists.', 1;

        INSERT INTO [dbo].[Products]
            ([SellerId], [BrandId], [CategoryId], [SubCategoryId], [GenderTypeId],
             [ProductName], [ShortDescription], [LongDescription], [Sku], [SlugUrl],
             [MRP], [SellingPrice], [CostPrice], [Tags], [ApprovalStatus],
             [Material], [CareInstructions], [FitType], [CountryOfOrigin], [WarrantyInfo], [DeliveryInfo],
             [LengthCm], [WidthCm], [HeightCm], [WeightGm],
             [CreatedAt], [CreatedBy], [IsDeleted])
        VALUES
            (@SellerId, @BrandId, @CategoryId, @SubCategoryId, @GenderTypeId,
             @ProductName, @ShortDescription, @LongDescription, @Sku, @SlugUrl,
             @MRP, @SellingPrice, @CostPrice, @Tags, 2,  -- ApprovalStatus=2 (Approved) — visible to buyers immediately
             @Material, @CareInstructions, @FitType, @CountryOfOrigin, @WarrantyInfo, @DeliveryInfo,
             @LengthCm, @WidthCm, @HeightCm, @WeightGm,
             GETUTCDATE(), @CreatedBy, 0);

        SELECT SCOPE_IDENTITY() AS [ProductId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
