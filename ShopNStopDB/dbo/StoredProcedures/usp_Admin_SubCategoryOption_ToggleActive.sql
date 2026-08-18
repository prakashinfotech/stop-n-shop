CREATE PROCEDURE [dbo].[usp_Admin_SubCategoryOption_ToggleActive]
    @OptionId    INT,
    @IsActive    BIT,
    @AdminUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[SubCategoryVariantOptions]
        SET [IsActive]  = @IsActive,
            [UpdatedBy] = @AdminUserId,
            [UpdatedAt] = GETUTCDATE()
        WHERE [OptionId] = @OptionId;

        IF @@ROWCOUNT = 0
            THROW 50220, 'Variant option not found.', 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
