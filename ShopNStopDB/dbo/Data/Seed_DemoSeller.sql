-- Seeds a demo seller (user + Sellers row) used as the owner of all seed products.
-- Idempotent: MERGE on Email / UserId. CustomerRole=2 assumed for buyers; SellerRole=3 used here.

MERGE [dbo].[Users] AS tgt
USING (VALUES (
    N'demoseller@stopnshop.com',
    N'RE3rL7aRhROPjazVNlzbBQ==:QBb8ll4/P/fjikyPs9aqEZ0JlA3b9kWoB1/qMZVzVvE=',  -- PBKDF2-SHA256 hash for: Test@123
    N'Demo',
    N'Seller',
    N'9000000000',
    3,    -- RoleId = Seller
    1, 0, 1,
    N'DEMOSELL'  -- ReferralCode: UQ_Users_Referral is unfiltered, so a second NULL collides
)) AS src (
    [Email], [PasswordHash], [FirstName], [LastName],
    [Mobile], [RoleId], [IsEmailVerified], [IsMobileVerified], [IsActive],
    [ReferralCode]
)
ON tgt.[Email] = src.[Email]
WHEN NOT MATCHED THEN INSERT
    ([Email], [PasswordHash], [FirstName], [LastName],
     [Mobile], [RoleId], [IsEmailVerified], [IsMobileVerified],
     [IsActive], [ReferralCode], [CreatedAt], [IsDeleted])
VALUES
    (src.[Email], src.[PasswordHash], src.[FirstName], src.[LastName],
     src.[Mobile], src.[RoleId], src.[IsEmailVerified], src.[IsMobileVerified],
     src.[IsActive], src.[ReferralCode], GETUTCDATE(), 0);
GO

DECLARE @DemoUserId INT = (SELECT [UserId] FROM [dbo].[Users] WHERE [Email] = N'demoseller@stopnshop.com');

MERGE [dbo].[Sellers] AS tgt
USING (VALUES (
    @DemoUserId,
    N'Demo Seller Store',
    2,             -- ApprovalStatus = Approved
    N'Demo',
    N'Demo Seller',
    N'Default demo seller for seeded catalog data.',
    1, 1, 1        -- IsIdVerified, OnboardingCompleted, IsActive
)) AS src (
    [UserId], [BusinessName], [ApprovalStatus],
    [OwnerName], [DisplayName], [StoreDescription],
    [IsIdVerified], [OnboardingCompleted], [IsActive]
)
ON tgt.[UserId] = src.[UserId]
WHEN NOT MATCHED THEN INSERT
    ([UserId], [BusinessName], [ApprovalStatus],
     [OwnerName], [DisplayName], [StoreDescription],
     [IsIdVerified], [OnboardingCompleted], [IsActive],
     [CreatedAt], [IsDeleted])
VALUES
    (src.[UserId], src.[BusinessName], src.[ApprovalStatus],
     src.[OwnerName], src.[DisplayName], src.[StoreDescription],
     src.[IsIdVerified], src.[OnboardingCompleted], src.[IsActive],
     GETUTCDATE(), 0);
GO
