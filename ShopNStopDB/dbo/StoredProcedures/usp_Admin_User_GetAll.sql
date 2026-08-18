CREATE PROCEDURE [dbo].[usp_Admin_User_GetAll]
    @RoleId      TINYINT       = NULL,
    @SearchTerm  NVARCHAR(200) = NULL,
    @IsActive    BIT           = NULL,
    @PageNumber  INT = 1,
    @PageSize    INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            u.[UserId],
            u.[FirstName],
            u.[LastName],
            u.[Email],
            u.[Mobile],
            u.[RoleId],
            r.[RoleName],
            u.[IsEmailVerified],
            u.[IsMobileVerified],
            u.[IsActive],
            u.[CreatedAt],
            u.[LastLoginAt],
            COUNT(*) OVER() AS [TotalCount]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[IsDeleted] = 0
          AND (@RoleId     IS NULL OR u.[RoleId]  = @RoleId)
          AND (@IsActive   IS NULL OR u.[IsActive] = @IsActive)
          AND (@SearchTerm IS NULL  OR u.[FirstName] LIKE N'%' + @SearchTerm + N'%'
                                   OR u.[LastName]  LIKE N'%' + @SearchTerm + N'%'
                                   OR u.[Email]     LIKE N'%' + @SearchTerm + N'%'
                                   OR u.[Mobile]    LIKE N'%' + @SearchTerm + N'%')
        ORDER BY u.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
