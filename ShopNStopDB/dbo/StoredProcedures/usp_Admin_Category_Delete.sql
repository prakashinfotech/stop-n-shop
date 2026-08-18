CREATE PROCEDURE [dbo].[usp_Admin_Category_Delete]
    @CategoryId   INT,
    @AdminUserId  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [CategoryId] = @CategoryId AND [IsDeleted] = 0
        )
            THROW 50201, 'Cannot delete category: products are still assigned to it. Reassign or delete those products first.', 1;

        UPDATE [dbo].[SubCategories]
        SET [IsDeleted] = 1,
            [UpdatedBy] = @AdminUserId,
            [UpdatedAt] = GETUTCDATE()
        WHERE [CategoryId] = @CategoryId
          AND [IsDeleted]  = 0;

        UPDATE [dbo].[Categories]
        SET [IsDeleted] = 1,
            [IsActive]  = 0,
            [UpdatedBy] = @AdminUserId,
            [UpdatedAt] = GETUTCDATE()
        WHERE [CategoryId] = @CategoryId
          AND [IsDeleted]  = 0;

        IF @@ROWCOUNT = 0
            THROW 50200, 'Category not found.', 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
