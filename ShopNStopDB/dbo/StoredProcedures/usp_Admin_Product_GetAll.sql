CREATE PROCEDURE [dbo].[usp_Admin_Product_GetAll]
    @ApprovalStatus TINYINT       = NULL,    -- 1=Pending, 2=Approved, 3=Rejected
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
            p.[ProductId]      AS [Id],
            p.[ProductName]    AS [Name],
            p.[MRP],
            p.[SellingPrice],
            p.[ApprovalStatus],
            p.[IsActive],
            p.[CreatedAt],
            s.[BusinessName]   AS [SellerName],
            b.[BrandName],
            c.[CategoryName],
            pi_.[ImageUrl]     AS [PrimaryImage],
            COUNT(*) OVER()    AS [TotalCount]
        FROM [dbo].[Products]            p
        INNER JOIN [dbo].[Sellers]       s   ON s.[SellerId]   = p.[SellerId]
        INNER JOIN [dbo].[Brands]        b   ON b.[BrandId]    = p.[BrandId]
        INNER JOIN [dbo].[Categories]    c   ON c.[CategoryId] = p.[CategoryId]
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = p.[ProductId]
                                              AND pi_.[IsPrimary] = 1
                                              AND pi_.[IsDeleted] = 0
        WHERE p.[IsDeleted] = 0
          AND (@ApprovalStatus IS NULL OR p.[ApprovalStatus] = @ApprovalStatus)
          AND (@SearchTerm IS NULL
               OR p.[ProductName]  LIKE N'%' + @SearchTerm + N'%'
               OR s.[BusinessName] LIKE N'%' + @SearchTerm + N'%'
               OR b.[BrandName]    LIKE N'%' + @SearchTerm + N'%')
        ORDER BY p.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
