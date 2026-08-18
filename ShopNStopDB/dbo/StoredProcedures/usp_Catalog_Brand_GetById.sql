CREATE PROCEDURE [dbo].[usp_Catalog_Brand_GetById]
    @BrandId  INT  = NULL,
    @SlugUrl  NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            [BrandId], [BrandName], [SlugUrl], [LogoUrl], [BannerUrl],
            [Description], [TagLine], [IsFeatured], [SortOrder],
            [MetaTitle], [MetaDescription], [MetaKeywords]
        FROM [dbo].[Brands]
        WHERE [IsDeleted] = 0
          AND [IsActive]  = 1
          AND ([BrandId]  = @BrandId  OR @BrandId IS NULL)
          AND ([SlugUrl]  = @SlugUrl  OR @SlugUrl IS NULL);

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
