CREATE PROCEDURE [dbo].[usp_Admin_SubCategory_Upsert]
    @SubCategoryId    INT             = NULL,    -- NULL = insert
    @CategoryId       INT,
    @SubCategoryName  NVARCHAR(200),
    @SlugUrl          NVARCHAR(300),
    @IconUrl          NVARCHAR(500)   = NULL,
    @SortOrder        INT             = 0,
    @IsFeatured       BIT             = 0,
    @ShowInMegaMenu   BIT             = 1,
    @MetaTitle        NVARCHAR(200)   = NULL,
    @MetaDescription  NVARCHAR(500)   = NULL,
    @AdminUserId      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Categories]
            WHERE [CategoryId] = @CategoryId AND [IsDeleted] = 0
        )
            THROW 50202, 'Parent category not found.', 1;

        IF @SubCategoryId IS NULL OR @SubCategoryId = 0
        BEGIN
            INSERT INTO [dbo].[SubCategories]
                ([CategoryId], [SubCategoryName], [SlugUrl], [IconUrl],
                 [SortOrder], [IsFeatured], [ShowInMegaMenu],
                 [MetaTitle], [MetaDescription],
                 [CreatedBy], [UpdatedBy], [CreatedAt], [UpdatedAt])
            VALUES
                (@CategoryId, @SubCategoryName, @SlugUrl, @IconUrl,
                 @SortOrder, @IsFeatured, @ShowInMegaMenu,
                 @MetaTitle, @MetaDescription,
                 @AdminUserId, @AdminUserId, GETUTCDATE(), GETUTCDATE());

            SELECT CAST(SCOPE_IDENTITY() AS INT) AS [SubCategoryId];
        END
        ELSE
        BEGIN
            UPDATE [dbo].[SubCategories]
            SET
                [CategoryId]       = @CategoryId,
                [SubCategoryName]  = @SubCategoryName,
                [SlugUrl]          = @SlugUrl,
                [IconUrl]          = @IconUrl,
                [SortOrder]        = @SortOrder,
                [IsFeatured]       = @IsFeatured,
                [ShowInMegaMenu]   = @ShowInMegaMenu,
                [MetaTitle]        = @MetaTitle,
                [MetaDescription]  = @MetaDescription,
                [UpdatedBy]        = @AdminUserId,
                [UpdatedAt]        = GETUTCDATE()
            WHERE [SubCategoryId] = @SubCategoryId
              AND [IsDeleted]     = 0;

            IF @@ROWCOUNT = 0
                THROW 50203, 'Subcategory not found.', 1;

            SELECT @SubCategoryId AS [SubCategoryId];
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
