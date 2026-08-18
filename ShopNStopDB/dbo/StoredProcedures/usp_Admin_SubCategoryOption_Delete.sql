CREATE PROCEDURE [dbo].[usp_Admin_SubCategoryOption_Delete]
    @OptionId    INT,
    @AdminUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Soft-delete = mark inactive. Hard delete blocked if any product references it.
        IF EXISTS (
            SELECT 1 FROM [dbo].[ProductDisabledVariantOptions]
            WHERE [OptionId] = @OptionId
        )
        BEGIN
            UPDATE [dbo].[SubCategoryVariantOptions]
            SET [IsActive]  = 0,
                [UpdatedBy] = @AdminUserId,
                [UpdatedAt] = GETUTCDATE()
            WHERE [OptionId] = @OptionId;
        END
        ELSE
        BEGIN
            DELETE FROM [dbo].[SubCategoryVariantOptions]
            WHERE [OptionId] = @OptionId;
        END

        IF @@ROWCOUNT = 0
            THROW 50220, 'Variant option not found.', 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
