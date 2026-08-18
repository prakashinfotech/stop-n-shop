CREATE PROCEDURE [dbo].[usp_Admin_SubCategoryOption_GetBySubCategory]
    @SubCategoryId   INT,
    @IncludeInactive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            o.[OptionId],
            o.[SubCategoryId],
            o.[AttributeId],
            a.[AttributeKey],
            a.[DisplayName]   AS [AttributeName],
            a.[InputType],
            o.[OptionValue],
            o.[OptionMetadata],
            o.[SortOrder],
            o.[IsActive]
        FROM [dbo].[SubCategoryVariantOptions] o
        INNER JOIN [dbo].[VariantAttributes]   a ON a.[AttributeId] = o.[AttributeId]
        WHERE o.[SubCategoryId] = @SubCategoryId
          AND (@IncludeInactive = 1 OR o.[IsActive] = 1)
          AND a.[IsActive] = 1
        ORDER BY a.[SortOrder], a.[DisplayName], o.[SortOrder], o.[OptionValue];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
