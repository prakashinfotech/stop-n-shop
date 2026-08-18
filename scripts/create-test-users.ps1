#!/usr/bin/env pwsh
# Create test buyer and seller users for local testing
# Uses same PBKDF2-SHA256 algorithm as API

param(
    [string]$Server = "localhost\SQLEXPRESS01",
    [string]$Database = "ShopNShop_db"
)

# PBKDF2-SHA256 password hashing (matches API's AuthService)
function HashPassword([string]$password) {
    $salt = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
    $hash = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($password, $salt, 100000, [System.Security.Cryptography.HashAlgorithmName]::SHA256).GetBytes(32)
    $saltB64 = [Convert]::ToBase64String($salt)
    $hashB64 = [Convert]::ToBase64String($hash)
    return "$saltB64`:$hashB64"
}

# Test credentials
$buyerPassword = "Buyer@123"
$sellerPassword = "Seller@123"

$buyerHash = HashPassword $buyerPassword
$sellerHash = HashPassword $sellerPassword

Write-Host "Generated password hashes:"
Write-Host "Buyer hash: $buyerHash"
Write-Host "Seller hash: $sellerHash"
Write-Host ""

# SQL script to insert users
$sqlScript = @"
-- Create test buyer (RoleId = 2: Buyer)
INSERT INTO [dbo].[Users]
  ([Email], [Mobile], [PasswordHash], [RoleId], [FirstName], [LastName], [IsEmailVerified], [IsMobileVerified], [IsApproved], [IsActive])
VALUES
  (N'buyer@test.com', N'9999999991', N'$buyerHash', 2, N'Test', N'Buyer', 1, 1, 1, 1)
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Email] = N'buyer@test.com');

-- Create test seller (RoleId = 3: Seller)
INSERT INTO [dbo].[Users]
  ([Email], [Mobile], [PasswordHash], [RoleId], [FirstName], [LastName], [IsEmailVerified], [IsMobileVerified], [IsApproved], [IsActive])
VALUES
  (N'seller@test.com', N'9999999992', N'$sellerHash', 3, N'Test', N'Seller', 1, 1, 1, 1)
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Email] = N'seller@test.com');

-- Create seller profile for seller user (UserId = 2 assuming sequential)
INSERT INTO [dbo].[Sellers]
  ([UserId], [BusinessName], [ApprovalStatus], [OnboardingCompleted], [IsActive])
VALUES
  (2, N'Test Store', 2, 1, 1)
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [UserId] = 2);

PRINT 'Test users created successfully!';
PRINT 'Buyer: buyer@test.com / $buyerPassword';
PRINT 'Seller: seller@test.com / $sellerPassword';
"@

# Run SQL script
Write-Host "Inserting test users into database..."
$sqlScript | sqlcmd -S $Server -d $Database

Write-Host ""
Write-Host "✅ Test users created!"
Write-Host ""
Write-Host "Login credentials:"
Write-Host "  Buyer Email: buyer@test.com"
Write-Host "  Buyer Password: $buyerPassword"
Write-Host ""
Write-Host "  Seller Email: seller@test.com"
Write-Host "  Seller Password: $sellerPassword"
