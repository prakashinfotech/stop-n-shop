SET IDENTITY_INSERT [dbo].[Menus] ON;

MERGE [dbo].[Menus] AS tgt
USING (VALUES
    (1,  N'MEN',       N'men',       1, 1),
    (2,  N'WOMEN',     N'women',     2, 1),
    (3,  N'KIDS',      N'kids',      3, 1),
    (4,  N'HOME',      N'home',      4, 1),
    (5,  N'BEAUTY',    N'beauty',    5, 1),
    (6,  N'HOMESTOP',  N'homestop',  6, 1),
    (7,  N'GIFTS',     N'gifts',     7, 1),
    (8,  N'WATCHES',   N'watches',   8, 1),
    (9,  N'PERFUMES',  N'perfumes',  9, 1),
    (10, N'BRANDS',    N'brands',    10, 1)
) AS src ([MenuId], [MenuName], [SlugUrl], [SortOrder], [IsActive])
ON tgt.[MenuId] = src.[MenuId]
WHEN MATCHED THEN UPDATE SET
    tgt.[MenuName]  = src.[MenuName],
    tgt.[SlugUrl]   = src.[SlugUrl],
    tgt.[SortOrder] = src.[SortOrder],
    tgt.[IsActive]  = src.[IsActive]
WHEN NOT MATCHED THEN INSERT
    ([MenuId], [MenuName], [SlugUrl], [SortOrder], [IsActive], [CreatedAt], [IsDeleted])
VALUES
    (src.[MenuId], src.[MenuName], src.[SlugUrl], src.[SortOrder], src.[IsActive], GETUTCDATE(), 0);

SET IDENTITY_INSERT [dbo].[Menus] OFF;

-- Reseed identity so new inserts start after 10
DBCC CHECKIDENT ('[dbo].[Menus]', RESEED, 10);
GO
