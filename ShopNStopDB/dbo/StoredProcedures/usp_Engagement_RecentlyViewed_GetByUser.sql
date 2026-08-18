CREATE PROCEDURE [dbo].[usp_Engagement_RecentlyViewed_GetByUser]
    @UserId INT,
    @Top    INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT TOP (@Top)
            p.[ProductId],
            p.[ProductName],
            p.[SlugUrl],
            p.[SellingPrice],
            p.[MRP],
            pi_.[ImageUrl]  AS [PrimaryImageUrl],
            rv.[ViewedAt]
        FROM [dbo].[RecentlyViewed] rv
        INNER JOIN [dbo].[Products]      p   ON p.[ProductId]  = rv.[ProductId]  AND p.[IsDeleted] = 0
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = p.[ProductId]
                                             AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        WHERE rv.[UserId] = @UserId
        ORDER BY rv.[ViewedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
