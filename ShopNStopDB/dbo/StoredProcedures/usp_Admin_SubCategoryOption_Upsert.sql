CREATE PROCEDURE [dbo].[usp_Admin_SubCategoryOption_Upsert]
    @OptionId        INT             = NULL,    -- NULL = insert
    @SubCategoryId   INT,
    @AttributeId     INT,
    @OptionValue     NVARCHAR(100),
    @OptionMetadata  NVARCHAR(200)   = NULL,
    @SortOrder       INT             = 0,
    @AdminUserId     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @OptionId IS NULL OR @OptionId = 0
        BEGIN
            INSERT INTO [dbo].[SubCategoryVariantOptions]
                ([SubCategoryId], [AttributeId], [OptionValue], [OptionMetadata],
                 [SortOrder], [CreatedBy], [UpdatedBy], [CreatedAt], [UpdatedAt])
            VALUES
                (@SubCategoryId, @AttributeId, @OptionValue, @OptionMetadata,
                 @SortOrder, @AdminUserId, @AdminUserId, GETUTCDATE(), GETUTCDATE());

            SELECT CAST(SCOPE_IDENTITY() AS INT) AS [OptionId];
        END
        ELSE
        BEGIN
            UPDATE [dbo].[SubCategoryVariantOptions]
            SET
                [SubCategoryId]   = @SubCategoryId,
                [AttributeId]     = @AttributeId,
                [OptionValue]     = @OptionValue,
                [OptionMetadata]  = @OptionMetadata,
                [SortOrder]       = @SortOrder,
                [UpdatedBy]       = @AdminUserId,
                [UpdatedAt]       = GETUTCDATE()
            WHERE [OptionId] = @OptionId;

            IF @@ROWCOUNT = 0
                THROW 50220, 'Variant option not found.', 1;

            SELECT @OptionId AS [OptionId];
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
