CREATE PROCEDURE [dbo].[usp_Admin_SubCategory_Reorder]
    @OrderJson    NVARCHAR(MAX),    -- JSON array: [{"subCategoryId":1,"sortOrder":0},...]
    @AdminUserId  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        WITH Incoming AS (
            SELECT [SubCategoryId], [SortOrder]
            FROM OPENJSON(@OrderJson)
            WITH (
                [SubCategoryId] INT '$.subCategoryId',
                [SortOrder]     INT '$.sortOrder'
            )
        )
        UPDATE sc
        SET [SortOrder] = i.[SortOrder],
            [UpdatedBy] = @AdminUserId,
            [UpdatedAt] = GETUTCDATE()
        FROM [dbo].[SubCategories] sc
        INNER JOIN Incoming i ON i.[SubCategoryId] = sc.[SubCategoryId]
        WHERE sc.[IsDeleted] = 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
