CREATE PROCEDURE [dbo].[usp_Admin_Category_ToggleVisibility]
    @CategoryId      INT,
    @IsActive        BIT             = NULL,    -- when supplied, sets IsActive
    @ShowInMegaMenu  BIT             = NULL,    -- when supplied, sets ShowInMegaMenu
    @AdminUserId     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[Categories]
        SET
            [IsActive]        = COALESCE(@IsActive,       [IsActive]),
            [ShowInMegaMenu]  = COALESCE(@ShowInMegaMenu, [ShowInMegaMenu]),
            [UpdatedBy]       = @AdminUserId,
            [UpdatedAt]       = GETUTCDATE()
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
