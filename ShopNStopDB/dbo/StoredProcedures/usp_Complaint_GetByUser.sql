CREATE PROCEDURE [dbo].[usp_Complaint_GetByUser]
    @UserId    INT,
    @Page      INT = 1,
    @PageSize  INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@Page - 1) * @PageSize;

        SELECT
            c.[ComplaintId],
            c.[OrderId],
            o.[OrderNumber],
            c.[Category],
            c.[Subject],
            c.[Body],
            c.[Status],
            c.[AdminNote],
            c.[CreatedAt],
            c.[UpdatedAt],
            COUNT(*) OVER() AS [TotalCount]
        FROM   [dbo].[Complaints] c
        LEFT  JOIN [dbo].[Orders] o ON o.[OrderId] = c.[OrderId]
        WHERE  c.[UserId]    = @UserId
          AND  c.[IsDeleted] = 0
        ORDER BY c.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
