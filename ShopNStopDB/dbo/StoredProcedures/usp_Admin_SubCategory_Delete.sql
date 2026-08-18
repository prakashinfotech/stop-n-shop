CREATE PROCEDURE [dbo].[usp_Admin_SubCategory_Delete]
    @SubCategoryId  INT,
    @AdminUserId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [SubCategoryId] = @SubCategoryId AND [IsDeleted] = 0
        )
            THROW 50204, 'Cannot delete subcategory: products are still assigned to it. Reassign or delete those products first.', 1;

        UPDATE [dbo].[SubCategories]
        SET [IsDeleted] = 1,
            [IsActive]  = 0,
            [UpdatedBy] = @AdminUserId,
            [UpdatedAt] = GETUTCDATE()
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
