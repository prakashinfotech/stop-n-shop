CREATE PROCEDURE [dbo].[usp_Admin_VariantAttribute_GetAll]
    @IncludeInactive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            [AttributeId],
            [AttributeKey],
            [DisplayName],
            [InputType],
            [SortOrder],
            [IsActive]
        FROM [dbo].[VariantAttributes]
        WHERE (@IncludeInactive = 1 OR [IsActive] = 1)
        ORDER BY [SortOrder], [DisplayName];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
