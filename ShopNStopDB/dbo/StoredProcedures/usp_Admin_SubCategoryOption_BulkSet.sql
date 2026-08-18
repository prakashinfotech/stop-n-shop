CREATE PROCEDURE [dbo].[usp_Admin_SubCategoryOption_BulkSet]
    @SubCategoryId  INT,
    @AttributeId    INT,
    @OptionsJson    NVARCHAR(MAX),    -- [{"optionValue":"XL","optionMetadata":null,"sortOrder":4},...]
    @AdminUserId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Stage incoming values
        DECLARE @Incoming TABLE (
            [OptionValue]     NVARCHAR(100) NOT NULL,
            [OptionMetadata]  NVARCHAR(200) NULL,
            [SortOrder]       INT           NOT NULL
        );

        INSERT INTO @Incoming ([OptionValue], [OptionMetadata], [SortOrder])
        SELECT [OptionValue], [OptionMetadata], [SortOrder]
        FROM OPENJSON(@OptionsJson)
        WITH (
            [OptionValue]    NVARCHAR(100) '$.optionValue',
            [OptionMetadata] NVARCHAR(200) '$.optionMetadata',
            [SortOrder]      INT           '$.sortOrder'
        );

        -- Reactivate + update matches
        UPDATE existing
        SET [OptionMetadata] = i.[OptionMetadata],
            [SortOrder]      = i.[SortOrder],
            [IsActive]       = 1,
            [UpdatedBy]      = @AdminUserId,
            [UpdatedAt]      = GETUTCDATE()
        FROM [dbo].[SubCategoryVariantOptions] existing
        INNER JOIN @Incoming i ON i.[OptionValue] = existing.[OptionValue]
        WHERE existing.[SubCategoryId] = @SubCategoryId
          AND existing.[AttributeId]   = @AttributeId;

        -- Insert brand-new
        INSERT INTO [dbo].[SubCategoryVariantOptions]
            ([SubCategoryId], [AttributeId], [OptionValue], [OptionMetadata],
             [SortOrder], [CreatedBy], [UpdatedBy])
        SELECT @SubCategoryId, @AttributeId, i.[OptionValue], i.[OptionMetadata],
               i.[SortOrder], @AdminUserId, @AdminUserId
        FROM @Incoming i
        WHERE NOT EXISTS (
            SELECT 1 FROM [dbo].[SubCategoryVariantOptions] existing
            WHERE existing.[SubCategoryId] = @SubCategoryId
              AND existing.[AttributeId]   = @AttributeId
              AND existing.[OptionValue]   = i.[OptionValue]
        );

        -- Deactivate values that were removed (don't hard-delete — products may still reference)
        UPDATE [dbo].[SubCategoryVariantOptions]
        SET [IsActive]  = 0,
            [UpdatedBy] = @AdminUserId,
            [UpdatedAt] = GETUTCDATE()
        WHERE [SubCategoryId] = @SubCategoryId
          AND [AttributeId]   = @AttributeId
          AND [OptionValue] NOT IN (SELECT [OptionValue] FROM @Incoming);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
