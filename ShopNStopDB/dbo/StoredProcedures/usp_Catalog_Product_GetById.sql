CREATE PROCEDURE [dbo].[usp_Catalog_Product_GetById]
    @ProductId INT  = NULL,
    @SlugUrl   NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            p.[ProductId],
            p.[SellerId],
            p.[BrandId],
            p.[CategoryId],
            p.[SubCategoryId],
            p.[ProductName],
            p.[SlugUrl],
            p.[ShortDescription],
            p.[LongDescription],
            p.[MRP],
            p.[SellingPrice],
            p.[CostPrice],
            p.[GstRate],
            p.[Sku],
            p.[GenderTypeId],
            p.[IsReturnable],
            p.[ReturnWindowDays],
            p.[IsCODAvailable],
            p.[Tags],
            p.[IsFeatured],
            p.[ApprovalStatus],
            p.[PublishedAt],
            p.[MetaTitle],
            p.[MetaDescription],
            p.[MetaKeywords],

            -- Extended product details (nullable)
            p.[Material],
            p.[CareInstructions],
            p.[FitType],
            p.[CountryOfOrigin],
            p.[WarrantyInfo],
            p.[DeliveryInfo],

            b.[BrandName],
            b.[SlugUrl]    AS [BrandSlug],
            b.[LogoUrl]    AS [BrandLogoUrl],

            c.[CategoryName],
            sc.[SubCategoryName],

            gt.[Name]      AS [GenderType],

            s.[BusinessName] AS [SellerName]

        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]       b   ON b.[BrandId]       = p.[BrandId]
        INNER JOIN [dbo].[Categories]   c   ON c.[CategoryId]    = p.[CategoryId]
        LEFT  JOIN [dbo].[SubCategories] sc ON sc.[SubCategoryId] = p.[SubCategoryId]
        INNER JOIN [dbo].[Sellers]      s   ON s.[SellerId]       = p.[SellerId]
        LEFT  JOIN [dbo].[GenderTypes]  gt  ON gt.[GenderTypeId]  = p.[GenderTypeId]

        WHERE p.[IsDeleted] = 0
          AND (p.[ProductId] = @ProductId OR @ProductId IS NULL)
          AND (p.[SlugUrl]   = @SlugUrl   OR @SlugUrl   IS NULL);

        -- Return variants
        SELECT
            [VariantId], [ProductId], [Color], [ColorHexCode], [Size],
            [Material], [Pattern], [FitType], [VariantSku],
            [AdditionalPrice], [StockQuantity], [LowStockThreshold],
            [Weight], [Dimensions], [BarCode], [IsActive]
        FROM [dbo].[ProductVariants]
        WHERE [ProductId] = COALESCE(@ProductId,
            (SELECT [ProductId] FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0))
          AND [IsDeleted] = 0;

        -- Return images
        SELECT [ImageId], [VariantId], [ImageUrl], [AltText], [SortOrder], [IsPrimary]
        FROM [dbo].[ProductImages]
        WHERE [ProductId] = COALESCE(@ProductId,
            (SELECT [ProductId] FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0))
          AND [IsDeleted] = 0
        ORDER BY [SortOrder] ASC;

        -- Return specifications
        SELECT [SpecId], [SpecKey], [SpecValue], [SortOrder]
        FROM [dbo].[ProductSpecifications]
        WHERE [ProductId] = COALESCE(@ProductId,
            (SELECT [ProductId] FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0))
          AND [IsDeleted] = 0
        ORDER BY [SortOrder] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
