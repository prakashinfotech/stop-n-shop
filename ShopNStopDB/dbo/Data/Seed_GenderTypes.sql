MERGE [dbo].[GenderTypes] AS tgt
USING (VALUES
    (1, N'Men'),
    (2, N'Women'),
    (3, N'Kids'),
    (4, N'Unisex'),
    (5, N'Beauty'),
    (6, N'All')
) AS src ([GenderTypeId], [Name])
ON tgt.[GenderTypeId] = src.[GenderTypeId]
WHEN MATCHED AND tgt.[Name] <> src.[Name] THEN UPDATE SET
    tgt.[Name] = src.[Name]
WHEN NOT MATCHED THEN INSERT
    ([GenderTypeId], [Name])
VALUES
    (src.[GenderTypeId], src.[Name]);
GO
