CREATE PROCEDURE [dbo].[usp_Catalog_Brand_Update]
    @BrandId         INT,
    @BrandName       NVARCHAR(200) = NULL,
    @SlugUrl         NVARCHAR(300) = NULL,
    @LogoUrl         NVARCHAR(500) = NULL,
    @BannerUrl       NVARCHAR(500) = NULL,
    @Description     NVARCHAR(MAX) = NULL,
    @TagLine         NVARCHAR(300) = NULL,
    @IsFeatured      BIT           = NULL,
    @SortOrder       INT           = NULL,
    @MetaTitle       NVARCHAR(200) = NULL,
    @MetaDescription NVARCHAR(500) = NULL,
    @MetaKeywords    NVARCHAR(500) = NULL,
    @IsActive        BIT           = NULL,
    @UpdatedBy       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Brands] WHERE [BrandId] = @BrandId AND [IsDeleted] = 0)
            THROW 50021, N'Brand not found.', 1;

        IF @SlugUrl IS NOT NULL AND EXISTS (SELECT 1 FROM [dbo].[Brands] WHERE [SlugUrl] = @SlugUrl AND [BrandId] <> @BrandId AND [IsDeleted] = 0)
            THROW 50022, N'Slug URL is already in use by another brand.', 1;

        UPDATE [dbo].[Brands]
        SET
            [BrandName]       = COALESCE(@BrandName,       [BrandName]),
            [SlugUrl]         = COALESCE(@SlugUrl,         [SlugUrl]),
            [LogoUrl]         = COALESCE(@LogoUrl,         [LogoUrl]),
            [BannerUrl]       = COALESCE(@BannerUrl,       [BannerUrl]),
            [Description]     = COALESCE(@Description,     [Description]),
            [TagLine]         = COALESCE(@TagLine,         [TagLine]),
            [IsFeatured]      = COALESCE(@IsFeatured,      [IsFeatured]),
            [SortOrder]       = COALESCE(@SortOrder,       [SortOrder]),
            [MetaTitle]       = COALESCE(@MetaTitle,       [MetaTitle]),
            [MetaDescription] = COALESCE(@MetaDescription, [MetaDescription]),
            [MetaKeywords]    = COALESCE(@MetaKeywords,    [MetaKeywords]),
            [IsActive]        = COALESCE(@IsActive,        [IsActive]),
            [UpdatedAt]       = GETUTCDATE(),
            [UpdatedBy]       = @UpdatedBy
        WHERE [BrandId] = @BrandId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
