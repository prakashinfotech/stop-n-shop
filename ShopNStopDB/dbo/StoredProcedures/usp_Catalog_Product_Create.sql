CREATE PROCEDURE [dbo].[usp_Catalog_Product_Create]
    @SellerId         INT,
    @BrandId          INT,
    @CategoryId       INT,
    @SubCategoryId    INT,
    @ProductName      NVARCHAR(300),
    @SlugUrl          NVARCHAR(400),
    @ShortDescription NVARCHAR(500) = NULL,
    @LongDescription  NVARCHAR(MAX) = NULL,
    @MRP              DECIMAL(18,2),
    @SellingPrice     DECIMAL(18,2),
    @CostPrice        DECIMAL(18,2) = NULL,
    @GstRate          DECIMAL(5,2)  = 0,
    @Sku              NVARCHAR(100) = NULL,
    @GenderTypeId     TINYINT       = NULL,
    @IsReturnable     BIT           = 1,
    @ReturnWindowDays TINYINT       = 7,
    @IsCODAvailable   BIT           = 1,
    @Tags             NVARCHAR(1000) = NULL,
    @MetaTitle        NVARCHAR(200)  = NULL,
    @MetaDescription  NVARCHAR(500)  = NULL,
    @MetaKeywords     NVARCHAR(500)  = NULL,
    @LengthCm         DECIMAL(8,2)   = NULL,
    @WidthCm          DECIMAL(8,2)   = NULL,
    @HeightCm         DECIMAL(8,2)   = NULL,
    @WeightGm         DECIMAL(10,2)  = NULL,
    @CreatedBy        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0)
            THROW 50030, N'A product with this slug URL already exists.', 1;

        IF @Sku IS NOT NULL AND EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [Sku] = @Sku AND [IsDeleted] = 0)
            THROW 50031, N'A product with this SKU already exists.', 1;

        IF @SellingPrice > @MRP
            THROW 50032, N'Selling price cannot exceed MRP.', 1;

        -- Verify seller-brand mapping is approved
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[SellerBrandMappings]
            WHERE [SellerId] = @SellerId AND [BrandId] = @BrandId AND [IsApproved] = 1 AND [IsDeleted] = 0
        )
            THROW 50033, N'Seller is not authorised to list products under this brand.', 1;

        INSERT INTO [dbo].[Products]
            ([SellerId], [BrandId], [CategoryId], [SubCategoryId], [ProductName], [SlugUrl],
             [ShortDescription], [LongDescription], [MRP], [SellingPrice], [CostPrice], [GstRate],
             [Sku], [GenderTypeId], [IsReturnable], [ReturnWindowDays], [IsCODAvailable],
             [Tags], [MetaTitle], [MetaDescription], [MetaKeywords],
             [LengthCm], [WidthCm], [HeightCm], [WeightGm],
             [ApprovalStatus], [CreatedBy], [UpdatedBy])
        VALUES
            (@SellerId, @BrandId, @CategoryId, @SubCategoryId, @ProductName, @SlugUrl,
             @ShortDescription, @LongDescription, @MRP, @SellingPrice, @CostPrice, @GstRate,
             @Sku, @GenderTypeId, @IsReturnable, @ReturnWindowDays, @IsCODAvailable,
             @Tags, @MetaTitle, @MetaDescription, @MetaKeywords,
             @LengthCm, @WidthCm, @HeightCm, @WeightGm,
             1, @CreatedBy, @CreatedBy);

        DECLARE @NewProductId INT = SCOPE_IDENTITY();

        SELECT @NewProductId AS [ProductId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
