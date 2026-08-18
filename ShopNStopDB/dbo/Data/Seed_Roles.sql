MERGE [dbo].[Roles] AS tgt
USING (VALUES
    (1, N'Admin'),
    (2, N'Buyer'),
    (3, N'Seller'),
    (4, N'Dispatcher')
) AS src ([RoleId], [RoleName])
ON tgt.[RoleId] = src.[RoleId]
WHEN MATCHED AND tgt.[RoleName] <> src.[RoleName] THEN UPDATE SET
    tgt.[RoleName] = src.[RoleName]
WHEN NOT MATCHED THEN INSERT
    ([RoleId], [RoleName])
VALUES
    (src.[RoleId], src.[RoleName]);
GO
