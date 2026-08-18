CREATE PROCEDURE [dbo].[usp_Admin_SubCategory_UpdateFormRules]
    @SubCategoryId       INT,
    @ImageAngles         NVARCHAR(200) = NULL,    -- JSON array string, e.g. '["front","back"]'
    @SizeScale           NVARCHAR(30)  = NULL,    -- apparel | shoe-uk | shoe-eu | toy | none
    @RequiresGender      BIT,
    @RequiresDimensions  BIT,
    @AdminUserId         INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[SubCategories]
        SET
            [ImageAngles]        = @ImageAngles,
            [SizeScale]          = @SizeScale,
            [RequiresGender]     = @RequiresGender,
            [RequiresDimensions] = @RequiresDimensions,
            [UpdatedBy]          = @AdminUserId,
            [UpdatedAt]          = GETUTCDATE()
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
