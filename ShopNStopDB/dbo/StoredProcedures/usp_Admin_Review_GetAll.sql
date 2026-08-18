CREATE PROCEDURE [dbo].[usp_Admin_Review_GetAll]
    @IsApproved  BIT = NULL,
    @PageNumber  INT = 1,
    @PageSize    INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            r.[ReviewId]       AS [Id],
            r.[ProductId],
            p.[ProductName],
            COALESCE(u.[FirstName] + N' ' + u.[LastName], u.[Email]) AS [ReviewerName],
            r.[Rating],
            r.[Body]           AS [Comment],
            r.[IsApproved],
            r.[CreatedAt],
            COUNT(*) OVER()    AS [TotalCount]
        FROM [dbo].[Reviews]        r
        INNER JOIN [dbo].[Products] p ON p.[ProductId] = r.[ProductId]
        INNER JOIN [dbo].[Users]    u ON u.[UserId]    = r.[UserId]
        WHERE r.[IsDeleted] = 0
          AND (@IsApproved IS NULL OR r.[IsApproved] = @IsApproved)
        ORDER BY r.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
