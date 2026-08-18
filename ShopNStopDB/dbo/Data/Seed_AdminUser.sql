-- Seeds the default admin user. PasswordHash must be updated after first deployment.
MERGE [dbo].[Users] AS tgt
USING (VALUES (
    N'admin@stopnshop.com',
    N'GO91pX+DuuA8Az1K+IVqAg==:O06PSJi5ailLmBSkghEi3Sz4WcQC/OX0qnCQvngG0z8=',  -- PBKDF2-SHA256 hash for: Test@123
    N'SNS',
    N'Admin',
    NULL,
    1,    -- RoleId = Admin
    1,    -- IsEmailVerified
    0,    -- IsMobileVerified
    1     -- IsActive
)) AS src (
    [Email], [PasswordHash], [FirstName], [LastName],
    [Mobile], [RoleId], [IsEmailVerified], [IsMobileVerified], [IsActive]
)
ON tgt.[Email] = src.[Email]
WHEN NOT MATCHED THEN INSERT
    ([Email], [PasswordHash], [FirstName], [LastName],
     [Mobile], [RoleId], [IsEmailVerified], [IsMobileVerified],
     [IsActive], [CreatedAt], [IsDeleted])
VALUES
    (src.[Email], src.[PasswordHash], src.[FirstName], src.[LastName],
     src.[Mobile], src.[RoleId], src.[IsEmailVerified], src.[IsMobileVerified],
     src.[IsActive], GETUTCDATE(), 0)
WHEN MATCHED THEN UPDATE SET
    [PasswordHash] = src.[PasswordHash],
    [FirstName] = src.[FirstName],
    [LastName] = src.[LastName],
    [RoleId] = src.[RoleId],
    [IsEmailVerified] = src.[IsEmailVerified],
    [IsMobileVerified] = src.[IsMobileVerified],
    [IsActive] = src.[IsActive],
    [UpdatedAt] = GETUTCDATE();
GO
