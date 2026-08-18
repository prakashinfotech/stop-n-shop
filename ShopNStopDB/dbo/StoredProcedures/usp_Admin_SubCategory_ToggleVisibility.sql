CREATE PROCEDURE [dbo].[usp_Admin_SubCategory_ToggleVisibility]
    @SubCategoryId   INT,
    @IsActive        BIT             = NULL,
    @ShowInMegaMenu  BIT             = NULL,
    @AdminUserId     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[SubCategories]
        SET
            [IsActive]        = COALESCE(@IsActive,       [IsActive]),
            [ShowInMegaMenu]  = COALESCE(@ShowInMegaMenu, [ShowInMegaMenu]),
            [UpdatedBy]       = @AdminUserId,
            [UpdatedAt]       = GETUTCDATE()
        WHERE [SubCategoryId] = @SubCategoryId
          AND [IsDeleted]     = 0;

        IF @@ROWCOUNT = 0
            THROW 50203, 'Subcategory not found.', 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
