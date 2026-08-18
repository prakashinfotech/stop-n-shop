CREATE PROCEDURE [dbo].[usp_Catalog_Brand_Create]
    @BrandName       NVARCHAR(200),
    @SlugUrl         NVARCHAR(300),
    @LogoUrl         NVARCHAR(500) = NULL,
    @BannerUrl       NVARCHAR(500) = NULL,
    @Description     NVARCHAR(MAX) = NULL,
    @TagLine         NVARCHAR(300) = NULL,
    @IsFeatured      BIT           = 0,
    @SortOrder       INT           = 0,
    @MetaTitle       NVARCHAR(200) = NULL,
    @MetaDescription NVARCHAR(500) = NULL,
    @MetaKeywords    NVARCHAR(500) = NULL,
    @CreatedBy       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Brands] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0)
            THROW 50020, N'A brand with this slug URL already exists.', 1;

        INSERT INTO [dbo].[Brands]
            ([BrandName], [SlugUrl], [LogoUrl], [BannerUrl], [Description], [TagLine],
             [IsFeatured], [SortOrder], [MetaTitle], [MetaDescription], [MetaKeywords], [CreatedBy], [UpdatedBy])
        VALUES
            (@BrandName, @SlugUrl, @LogoUrl, @BannerUrl, @Description, @TagLine,
             @IsFeatured, @SortOrder, @MetaTitle, @MetaDescription, @MetaKeywords, @CreatedBy, @CreatedBy);

        DECLARE @NewBrandId INT = SCOPE_IDENTITY();

        EXEC [dbo].[usp_Catalog_Brand_GetById] @BrandId = @NewBrandId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
