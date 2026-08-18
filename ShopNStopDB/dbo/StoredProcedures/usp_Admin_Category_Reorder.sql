CREATE PROCEDURE [dbo].[usp_Admin_Category_Reorder]
    @OrderJson    NVARCHAR(MAX),    -- JSON array: [{"categoryId":1,"sortOrder":0},...]
    @AdminUserId  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        WITH Incoming AS (
            SELECT [CategoryId], [SortOrder]
            FROM OPENJSON(@OrderJson)
            WITH (
                [CategoryId] INT '$.categoryId',
                [SortOrder]  INT '$.sortOrder'
            )
        )
        UPDATE c
        SET [SortOrder] = i.[SortOrder],
            [UpdatedBy] = @AdminUserId,
            [UpdatedAt] = GETUTCDATE()
        FROM [dbo].[Categories] c
        INNER JOIN Incoming i ON i.[CategoryId] = c.[CategoryId]
        WHERE c.[IsDeleted] = 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
