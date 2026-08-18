SET IDENTITY_INSERT [dbo].[Brands] ON;

MERGE [dbo].[Brands] AS tgt
USING (VALUES
    (1,  N'Nike',            N'nike',            0, 1),
    (2,  N'Adidas',          N'adidas',          0, 1),
    (3,  N'H&M',             N'h-and-m',         0, 1),
    (4,  N'Zara',            N'zara',            1, 2),
    (5,  N'Levi''s',         N'levis',           0, 3),
    (6,  N'Puma',            N'puma',            0, 4),
    (7,  N'Allen Solly',     N'allen-solly',     0, 5),
    (8,  N'Van Heusen',      N'van-heusen',      0, 6),
    (9,  N'Biba',            N'biba',            0, 7),
    (10, N'W',               N'w-brand',         0, 8),
    (11, N'Woodland',        N'woodland',        0, 9),
    (12, N'Fastrack',        N'fastrack',        0, 10),
    (13, N'Lakme',           N'lakme',           0, 11),
    (14, N'L''Oreal',        N'loreal',          0, 12),
    (15, N'Raymond',         N'raymond',         0, 13)
) AS src ([BrandId], [BrandName], [SlugUrl], [IsFeatured], [SortOrder])
ON tgt.[BrandId] = src.[BrandId]
WHEN MATCHED THEN UPDATE SET
    tgt.[BrandName]  = src.[BrandName],
    tgt.[SlugUrl]    = src.[SlugUrl],
    tgt.[IsFeatured] = src.[IsFeatured],
    tgt.[SortOrder]  = src.[SortOrder]
WHEN NOT MATCHED THEN INSERT
    ([BrandId], [BrandName], [SlugUrl], [IsFeatured], [SortOrder],
     [CreatedAt], [IsDeleted])
VALUES
    (src.[BrandId], src.[BrandName], src.[SlugUrl],
     src.[IsFeatured], src.[SortOrder], GETUTCDATE(), 0);

SET IDENTITY_INSERT [dbo].[Brands] OFF;

DBCC CHECKIDENT ('[dbo].[Brands]', RESEED, 15);
GO
