CREATE PROCEDURE [dbo].[usp_Catalog_Brand_GetAll]
    @IsFeaturedOnly BIT = 0,
    @PageNumber     INT = 1,
    @PageSize       INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            [BrandId], [BrandName], [SlugUrl], [LogoUrl], [BannerUrl],
            [TagLine], [IsFeatured], [SortOrder],
            [MetaTitle], [MetaDescription]
        FROM [dbo].[Brands]
        WHERE [IsDeleted] = 0
          AND [IsActive]  = 1
          AND (@IsFeaturedOnly = 0 OR [IsFeatured] = 1)
        ORDER BY [SortOrder] ASC, [BrandName] ASC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
