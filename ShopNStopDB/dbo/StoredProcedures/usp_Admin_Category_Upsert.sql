CREATE PROCEDURE [dbo].[usp_Admin_Category_Upsert]
    @CategoryId       INT             = NULL,    -- NULL = insert
    @MenuId           INT,
    @CategoryName     NVARCHAR(200),
    @SlugUrl          NVARCHAR(300),
    @IconUrl          NVARCHAR(500)   = NULL,
    @BannerUrl        NVARCHAR(500)   = NULL,
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
        IF @CategoryId IS NULL OR @CategoryId = 0
        BEGIN
            INSERT INTO [dbo].[Categories]
                ([MenuId], [CategoryName], [SlugUrl], [IconUrl], [BannerUrl],
                 [SortOrder], [IsFeatured], [ShowInMegaMenu],
                 [MetaTitle], [MetaDescription],
                 [CreatedBy], [UpdatedBy], [CreatedAt], [UpdatedAt])
            VALUES
                (@MenuId, @CategoryName, @SlugUrl, @IconUrl, @BannerUrl,
                 @SortOrder, @IsFeatured, @ShowInMegaMenu,
                 @MetaTitle, @MetaDescription,
                 @AdminUserId, @AdminUserId, GETUTCDATE(), GETUTCDATE());

            SELECT CAST(SCOPE_IDENTITY() AS INT) AS [CategoryId];
        END
        ELSE
        BEGIN
            UPDATE [dbo].[Categories]
            SET
                [MenuId]           = @MenuId,
                [CategoryName]     = @CategoryName,
                [SlugUrl]          = @SlugUrl,
                [IconUrl]          = @IconUrl,
                [BannerUrl]        = @BannerUrl,
                [SortOrder]        = @SortOrder,
                [IsFeatured]       = @IsFeatured,
                [ShowInMegaMenu]   = @ShowInMegaMenu,
                [MetaTitle]        = @MetaTitle,
                [MetaDescription]  = @MetaDescription,
                [UpdatedBy]        = @AdminUserId,
                [UpdatedAt]        = GETUTCDATE()
            WHERE [CategoryId] = @CategoryId
              AND [IsDeleted]  = 0;

            IF @@ROWCOUNT = 0
                THROW 50200, 'Category not found.', 1;

            SELECT @CategoryId AS [CategoryId];
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
