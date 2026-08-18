CREATE PROCEDURE [dbo].[usp_Catalog_Product_GetTrending]
    @WindowDays INT = 7,
    @Limit      INT = 12
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- "Trending right now" — rolling-window view count from ProductViewLogs joined to
    -- the product card payload. Falls back to featured if there's no view activity yet
    -- so the home page never renders an empty rail in fresh installs.
    BEGIN TRY
        DECLARE @Since DATETIME2(0) = DATEADD(DAY, -@WindowDays, GETUTCDATE());

        ;WITH ViewCounts AS (
            SELECT
                vl.[ProductId],
                COUNT_BIG(1) AS [ViewCount]
            FROM [dbo].[ProductViewLogs] vl
            WHERE vl.[ViewedAt] >= @Since
            GROUP BY vl.[ProductId]
        )
        SELECT TOP (@Limit)
            p.[ProductId]                                        AS [Id],
            p.[ProductName]                                      AS [Name],
            p.[SlugUrl],
            p.[MRP],
            p.[SellingPrice],
            CASE
                WHEN p.[MRP] > 0
                THEN CAST(ROUND((p.[MRP] - p.[SellingPrice]) * 100.0 / p.[MRP], 0) AS INT)
                ELSE 0
            END                                                   AS [DiscountPercent],
            b.[BrandName],
            p.[CategoryId],
            ISNULL(p.[SubCategoryId], 0)                          AS [SubCategoryId],
            pi_.[ImageUrl]                                       AS [PrimaryImage],
            0                                                     AS [OfferCount],
            ISNULL(vc.[ViewCount], 0)                             AS [TrendingScore]
        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]       b   ON b.[BrandId]    = p.[BrandId]
        LEFT  JOIN [dbo].[ProductImages] pi_
                ON pi_.[ProductId] = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN ViewCounts vc
                ON vc.[ProductId] = p.[ProductId]
        WHERE p.[IsDeleted]      = 0
          AND p.[IsActive]       = 1
          AND p.[ApprovalStatus] = 2
        ORDER BY
            -- Real trending data wins; if no views yet, featured rank takes over.
            CASE WHEN vc.[ViewCount] IS NULL THEN 1 ELSE 0 END ASC,
            ISNULL(vc.[ViewCount], 0)                          DESC,
            p.[IsFeatured]                                     DESC,
            p.[PublishedAt]                                    DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
