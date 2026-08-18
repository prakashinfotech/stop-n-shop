CREATE PROCEDURE [dbo].[usp_Admin_Complaint_GetAll]
    @Status      TINYINT       = NULL,
    @Category    NVARCHAR(50)  = NULL,
    @SearchTerm  NVARCHAR(200) = NULL,
    @Page        INT = 1,
    @PageSize    INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@Page - 1) * @PageSize;

        SELECT
            c.[ComplaintId],
            c.[UserId],
            u.[FirstName] + N' ' + ISNULL(u.[LastName], N'') AS [UserName],
            u.[Email]      AS [UserEmail],
            c.[OrderId],
            o.[OrderNumber],
            c.[Category],
            c.[Subject],
            c.[Body],
            c.[Status],
            c.[AdminNote],
            c.[Source],
            c.[CreatedAt],
            c.[UpdatedAt],
            COUNT(*) OVER() AS [TotalCount]
        FROM   [dbo].[Complaints] c
        INNER JOIN [dbo].[Users]    u ON u.[UserId]  = c.[UserId]
        LEFT  JOIN [dbo].[Orders]   o ON o.[OrderId] = c.[OrderId]
        WHERE  c.[IsDeleted] = 0
          AND  (@Status   IS NULL OR c.[Status]   = @Status)
          AND  (@Category IS NULL OR c.[Category] = @Category)
          AND  (@SearchTerm IS NULL
                OR c.[Subject] LIKE N'%' + @SearchTerm + N'%'
                OR c.[Body]    LIKE N'%' + @SearchTerm + N'%'
                OR u.[Email]   LIKE N'%' + @SearchTerm + N'%'
                OR u.[FirstName] LIKE N'%' + @SearchTerm + N'%'
                OR u.[LastName]  LIKE N'%' + @SearchTerm + N'%')
        ORDER BY c.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
