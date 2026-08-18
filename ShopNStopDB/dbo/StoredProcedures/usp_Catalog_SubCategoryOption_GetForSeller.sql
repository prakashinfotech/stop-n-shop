CREATE PROCEDURE [dbo].[usp_Catalog_SubCategoryOption_GetForSeller]
    @SubCategoryId  INT,
    @ProductId      INT = NULL    -- when supplied, joins per-product disabled flags
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
            CAST(CASE WHEN d.[ProductId] IS NULL THEN 0 ELSE 1 END AS BIT) AS [IsDisabledForProduct]
        FROM [dbo].[SubCategoryVariantOptions] o
        INNER JOIN [dbo].[VariantAttributes]   a ON a.[AttributeId] = o.[AttributeId]
        LEFT  JOIN [dbo].[ProductDisabledVariantOptions] d
               ON d.[OptionId]  = o.[OptionId]
              AND d.[ProductId] = @ProductId
        WHERE o.[SubCategoryId] = @SubCategoryId
          AND o.[IsActive]      = 1
          AND a.[IsActive]      = 1
        ORDER BY a.[SortOrder], a.[DisplayName], o.[SortOrder], o.[OptionValue];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
