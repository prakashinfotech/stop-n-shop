CREATE PROCEDURE [dbo].[usp_Engagement_Review_GetByProduct]
    @ProductId  INT,
    @PageNumber INT = 1,
    @PageSize   INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        -- Rating summary
        SELECT
            COUNT(*)                       AS [TotalReviews],
            CAST(AVG(CAST([Rating] AS DECIMAL(3,2))) AS DECIMAL(3,2)) AS [AverageRating],
            SUM(CASE WHEN [Rating] = 5 THEN 1 ELSE 0 END) AS [FiveStar],
            SUM(CASE WHEN [Rating] = 4 THEN 1 ELSE 0 END) AS [FourStar],
            SUM(CASE WHEN [Rating] = 3 THEN 1 ELSE 0 END) AS [ThreeStar],
            SUM(CASE WHEN [Rating] = 2 THEN 1 ELSE 0 END) AS [TwoStar],
            SUM(CASE WHEN [Rating] = 1 THEN 1 ELSE 0 END) AS [OneStar]
        FROM [dbo].[Reviews]
        WHERE [ProductId]  = @ProductId
          AND [IsApproved] = 1
          AND [IsDeleted]  = 0;

        -- Individual reviews (paginated)
        SELECT
            rv.[ReviewId],
            rv.[Rating],
            rv.[Title],
            rv.[Body],
            rv.[HelpfulCount],
            rv.[CreatedAt],
            u.[FirstName],
            u.[LastName],
            u.[ProfileImageUrl],
            COUNT(*) OVER() AS [TotalCount]
        FROM [dbo].[Reviews] rv
        INNER JOIN [dbo].[Users] u ON u.[UserId] = rv.[UserId]
        WHERE rv.[ProductId]  = @ProductId
          AND rv.[IsApproved] = 1
          AND rv.[IsDeleted]  = 0
        ORDER BY rv.[HelpfulCount] DESC, rv.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
