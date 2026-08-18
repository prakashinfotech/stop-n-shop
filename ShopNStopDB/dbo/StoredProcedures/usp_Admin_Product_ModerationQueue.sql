-- Convenience filter over Products limited to ApprovalStatus = 1 (Pending),
-- ordered oldest-first so the longest-waiting submissions surface at the top.
CREATE PROCEDURE [dbo].[usp_Admin_Product_ModerationQueue]
    @PageNumber INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize   < 1 SET @PageSize   = 20;
    IF @PageSize   > 100 SET @PageSize = 100;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    SELECT
        p.[ProductId]      AS [Id],
        p.[ProductName]    AS [Name],
        p.[ShortDescription],
        p.[MRP],
        p.[SellingPrice],
        p.[ApprovalStatus],
        p.[CreatedAt],
        s.[SellerId],
        s.[BusinessName]   AS [SellerName],
        b.[BrandName],
        c.[CategoryName],
        pi_.[ImageUrl]     AS [PrimaryImage],
        DATEDIFF(HOUR, p.[CreatedAt], GETUTCDATE()) AS [HoursWaiting],
        COUNT(*) OVER()    AS [TotalCount]
    FROM [dbo].[Products]            p
    INNER JOIN [dbo].[Sellers]       s   ON s.[SellerId]   = p.[SellerId]
    INNER JOIN [dbo].[Brands]        b   ON b.[BrandId]    = p.[BrandId]
    INNER JOIN [dbo].[Categories]    c   ON c.[CategoryId] = p.[CategoryId]
    LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = p.[ProductId]
                                          AND pi_.[IsPrimary] = 1
                                          AND pi_.[IsDeleted] = 0
    WHERE p.[IsDeleted]      = 0
      AND p.[ApprovalStatus] = 1
    ORDER BY p.[CreatedAt] ASC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
