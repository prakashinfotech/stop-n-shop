CREATE PROCEDURE [dbo].[usp_Engagement_RecentlyViewed_Add]
    @UserId    INT,
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        MERGE [dbo].[RecentlyViewed] AS tgt
        USING (SELECT @UserId AS [UserId], @ProductId AS [ProductId]) AS src
            ON tgt.[UserId] = src.[UserId] AND tgt.[ProductId] = src.[ProductId]
        WHEN MATCHED THEN UPDATE SET
            tgt.[ViewedAt] = GETUTCDATE()
        WHEN NOT MATCHED THEN INSERT
            ([UserId], [ProductId], [ViewedAt])
        VALUES
            (@UserId, @ProductId, GETUTCDATE());

        -- Keep only the latest 20 entries per user
        DELETE FROM [dbo].[RecentlyViewed]
        WHERE [UserId] = @UserId
          AND [ViewId] NOT IN (
              SELECT TOP 20 [ViewId]
              FROM [dbo].[RecentlyViewed]
              WHERE [UserId] = @UserId
              ORDER BY [ViewedAt] DESC
          );

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
