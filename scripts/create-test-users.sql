-- Create test users for local testing
-- Passwords: Buyer@123 and Seller@123

DECLARE @BuyerHash NVARCHAR(500) = N'GfEZ47Z6m0+FywT8S2F6Jw==:T7fHf06oZBhREBHmhWn0F0GC8CxSFCZZmNvlPQpHjWA=';
DECLARE @SellerHash NVARCHAR(500) = N'Q4B2SXYz6nPZ8JK3mL9xRQ==:W8gHi07pBCiSFCGniXo1G1HD9DyTGDaaZnOw0Q6Ijox=';

-- Create Buyer User
EXEC [dbo].[usp_Auth_User_Register]
    @Email = N'buyer@test.com',
    @PasswordHash = @BuyerHash,
    @FirstName = N'Test',
    @LastName = N'Buyer',
    @Mobile = N'9999999991',
    @RoleId = 2;  -- Buyer

-- Create Seller User
EXEC [dbo].[usp_Auth_User_Register]
    @Email = N'seller@test.com',
    @PasswordHash = @SellerHash,
    @FirstName = N'Test',
    @LastName = N'Seller',
    @Mobile = N'9999999992',
    @RoleId = 3;  -- Seller

-- Create Seller Profile (link seller user to business)
INSERT INTO [dbo].[Sellers] ([UserId], [BusinessName], [ApprovalStatus], [OnboardingCompleted], [IsActive])
SELECT UserId, N'Test Store', 2, 1, 1
FROM [dbo].[Users]
WHERE Email = N'seller@test.com'
  AND NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] s WHERE s.UserId = [dbo].[Users].UserId);

PRINT 'Test users created successfully!';
PRINT 'Buyer: buyer@test.com / Buyer@123';
PRINT 'Seller: seller@test.com / Seller@123';
