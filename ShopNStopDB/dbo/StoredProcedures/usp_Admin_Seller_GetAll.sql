CREATE PROCEDURE [dbo].[usp_Admin_Seller_GetAll]
    @ApprovalStatus TINYINT       = NULL,    -- 1=Pending, 2=Approved, 3=Rejected, 4=Suspended
    @SearchTerm     NVARCHAR(200) = NULL,
    @PageNumber     INT = 1,
    @PageSize       INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            s.[SellerId]         AS [Id],
            s.[BusinessName],
            COALESCE(s.[OwnerName], u.[FirstName] + N' ' + u.[LastName]) AS [OwnerName],
            u.[Email],
            u.[Mobile]           AS [PhoneNumber],
            s.[ApprovalStatus],
            s.[IsActive],
            s.[CreatedAt],
            COUNT(*) OVER()      AS [TotalCount]
        FROM [dbo].[Sellers] s
        INNER JOIN [dbo].[Users] u ON u.[UserId] = s.[UserId]
        WHERE s.[IsDeleted] = 0
          AND (@ApprovalStatus IS NULL OR s.[ApprovalStatus] = @ApprovalStatus)
          AND (@SearchTerm IS NULL
               OR s.[BusinessName] LIKE N'%' + @SearchTerm + N'%'
               OR u.[Email]        LIKE N'%' + @SearchTerm + N'%'
               OR u.[FirstName]    LIKE N'%' + @SearchTerm + N'%'
               OR u.[LastName]     LIKE N'%' + @SearchTerm + N'%')
        ORDER BY s.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
