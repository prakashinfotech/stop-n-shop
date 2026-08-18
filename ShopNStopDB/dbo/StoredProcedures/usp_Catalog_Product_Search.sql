CREATE PROCEDURE [dbo].[usp_Catalog_Product_Search]
    @SearchTerm    NVARCHAR(500),
    @CategoryId    INT    = NULL,
    @SubCategoryId INT    = NULL,
    @MenuId        INT    = NULL,
    @BrandId       INT    = NULL,
    @BrandIds      NVARCHAR(500) = NULL,
    @Sizes         NVARCHAR(500) = NULL,
    @Colors        NVARCHAR(500) = NULL,
    @GenderTypeId  TINYINT = NULL,
    @MinPrice      DECIMAL(18,2) = NULL,
    @MaxPrice      DECIMAL(18,2) = NULL,
    @SortBy        NVARCHAR(50)  = N'Relevance',  -- Relevance | PriceLow | PriceHigh | Newest
    @PageNumber    INT  = 1,
    @PageSize      INT  = 20,
    @CallerUserId  INT  = NULL,
    @DatePosted    NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
        DECLARE @SearchPattern NVARCHAR(502) = CASE WHEN @SearchTerm <> N'' THEN N'%' + @SearchTerm + N'%' ELSE N'%' END;

        -- Log search for analytics
        IF @SearchTerm <> N''
            INSERT INTO [dbo].[SearchLogs] ([UserId], [SearchTerm], [ResultCount], [SearchedAt])
            VALUES (@CallerUserId, @SearchTerm, 0, GETUTCDATE());

        DECLARE @SearchLogId BIGINT = SCOPE_IDENTITY();

        DECLARE @BrandIdTbl TABLE (Id INT PRIMARY KEY);
        IF @BrandIds IS NOT NULL AND LEN(@BrandIds) > 0
            INSERT INTO @BrandIdTbl(Id)
            SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@BrandIds, ',') WHERE TRY_CAST(value AS INT) IS NOT NULL;

        DECLARE @SizeTbl TABLE (Val NVARCHAR(50));
        IF @Sizes IS NOT NULL AND LEN(@Sizes) > 0
            INSERT INTO @SizeTbl(Val) SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@Sizes, ',') WHERE LTRIM(RTRIM(value)) <> N'';

        DECLARE @ColorTbl TABLE (Val NVARCHAR(50));
        IF @Colors IS NOT NULL AND LEN(@Colors) > 0
            INSERT INTO @ColorTbl(Val) SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@Colors, ',') WHERE LTRIM(RTRIM(value)) <> N'';

        DECLARE @HasBrandFilter BIT = CASE WHEN EXISTS (SELECT 1 FROM @BrandIdTbl) THEN 1 ELSE 0 END;
        DECLARE @HasSizeFilter  BIT = CASE WHEN EXISTS (SELECT 1 FROM @SizeTbl)    THEN 1 ELSE 0 END;
        DECLARE @HasColorFilter BIT = CASE WHEN EXISTS (SELECT 1 FROM @ColorTbl)   THEN 1 ELSE 0 END;

        -- LIKE-based search (no full-text index required)
        SELECT
            p.[ProductId]           AS [Id],
            p.[ProductName]         AS [Name],
            p.[SlugUrl],
            p.[CategoryId],
            p.[SubCategoryId],
            p.[SellerId],
            p.[MRP],
            p.[SellingPrice],
            CAST(CASE WHEN p.[MRP] > 0 THEN (p.[MRP] - p.[SellingPrice]) * 100.0 / p.[MRP] ELSE 0 END AS DECIMAL(5,1)) AS [DiscountPct],
            p.[GstRate],
            b.[BrandName],
            c.[CategoryName],
            sc.[SubCategoryName],
            pi_.[ImageUrl]           AS [PrimaryImage],
            ISNULL(pv.[MinStock], 0) AS [MinStock],
            COUNT(*) OVER()          AS [TotalCount]
        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]         b   ON b.[BrandId]       = p.[BrandId]
        INNER JOIN [dbo].[Categories]     c   ON c.[CategoryId]    = p.[CategoryId]
        LEFT  JOIN [dbo].[SubCategories]  sc  ON sc.[SubCategoryId] = p.[SubCategoryId]
        LEFT  JOIN [dbo].[ProductImages]  pi_ ON pi_.[ProductId]   = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN (
            SELECT [ProductId], MIN([StockQuantity]) AS [MinStock]
            FROM [dbo].[ProductVariants] WHERE [IsDeleted] = 0 AND [IsActive] = 1
            GROUP BY [ProductId]
        ) pv ON pv.[ProductId] = p.[ProductId]
        WHERE p.[IsDeleted]      = 0
          AND p.[IsActive]       = 1
          AND p.[ApprovalStatus] = 2
          AND (p.[CategoryId]    = @CategoryId    OR @CategoryId    IS NULL)
          AND (p.[SubCategoryId] = @SubCategoryId OR @SubCategoryId IS NULL)
          AND (c.[MenuId]        = @MenuId        OR @MenuId        IS NULL)
          AND (p.[BrandId]       = @BrandId      OR @BrandId      IS NULL)
          AND (@HasBrandFilter = 0 OR p.[BrandId] IN (SELECT Id FROM @BrandIdTbl))
          AND (p.[GenderTypeId]  = @GenderTypeId OR @GenderTypeId IS NULL)
          AND (p.[SellingPrice]  >= @MinPrice     OR @MinPrice     IS NULL)
          AND (p.[SellingPrice]  <= @MaxPrice     OR @MaxPrice     IS NULL)
          AND (p.[ProductName] LIKE @SearchPattern OR p.[ShortDescription] LIKE @SearchPattern OR p.[Tags] LIKE @SearchPattern OR @SearchTerm = N'')
          AND (@HasSizeFilter  = 0 OR EXISTS (SELECT 1 FROM [dbo].[ProductVariants] v WHERE v.[ProductId] = p.[ProductId] AND v.[IsDeleted] = 0 AND v.[Size]  IN (SELECT Val FROM @SizeTbl)))
          AND (@HasColorFilter = 0 OR EXISTS (SELECT 1 FROM [dbo].[ProductVariants] v WHERE v.[ProductId] = p.[ProductId] AND v.[IsDeleted] = 0 AND v.[Color] IN (SELECT Val FROM @ColorTbl)))
          AND (
              @DatePosted IS NULL
              OR (@DatePosted = N'today'      AND CAST(p.[CreatedAt] AS DATE) = CAST(GETUTCDATE() AS DATE))
              OR (@DatePosted = N'this_week'  AND p.[CreatedAt] >= DATEADD(DAY, -6, CAST(GETUTCDATE() AS DATE)))
              OR (@DatePosted = N'this_month' AND p.[CreatedAt] >= DATEFROMPARTS(YEAR(GETUTCDATE()), MONTH(GETUTCDATE()), 1))
              OR (@DatePosted = N'last_month' AND p.[CreatedAt] >= DATEFROMPARTS(YEAR(DATEADD(MONTH,-1,GETUTCDATE())), MONTH(DATEADD(MONTH,-1,GETUTCDATE())), 1)
                                              AND p.[CreatedAt] <  DATEFROMPARTS(YEAR(GETUTCDATE()), MONTH(GETUTCDATE()), 1))
              OR (@DatePosted = N'older'      AND p.[CreatedAt] <  DATEFROMPARTS(YEAR(DATEADD(MONTH,-1,GETUTCDATE())), MONTH(DATEADD(MONTH,-1,GETUTCDATE())), 1))
          )
        ORDER BY
            CASE WHEN @SortBy = N'PriceLow'  THEN p.[SellingPrice] END ASC,
            CASE WHEN @SortBy = N'PriceHigh' THEN p.[SellingPrice] END DESC,
            -- Default + LATEST/POPULAR: surface recently-modified products first
            CASE WHEN @SortBy IN (N'Newest', N'LATEST', N'POPULAR') THEN COALESCE(p.[UpdatedAt], p.[CreatedAt]) END DESC,
            COALESCE(p.[UpdatedAt], p.[CreatedAt]) DESC,
            p.[ProductId] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

        -- Update result count in search log
        IF @SearchLogId > 0
            UPDATE [dbo].[SearchLogs] SET [ResultCount] = @@ROWCOUNT WHERE [SearchId] = @SearchLogId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
