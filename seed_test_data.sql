-- ============================================================
-- Seed Test Data for Seller Dashboard
-- ============================================================

-- Check if seller exists
DECLARE @SellerId INT = 1
DECLARE @BuyerId INT = 1

-- Create test seller if not exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = 1 AND Role = 'Seller')
BEGIN
    INSERT INTO Users (Email, Mobile, PasswordHash, Role, FirstName, LastName, IsEmailVerified, IsMobileVerified, IsFirstLogin, CreatedAt)
    VALUES ('seller@test.com', '9876543210', 'HASHED_PASSWORD', 'Seller', 'John', 'Seller', 1, 1, 0, GETUTCDATE())
    SET @SellerId = @@IDENTITY
END

-- Create test buyer if not exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = 2 AND Role = 'Buyer')
BEGIN
    INSERT INTO Users (Email, Mobile, PasswordHash, Role, FirstName, LastName, IsEmailVerified, IsMobileVerified, IsFirstLogin, CreatedAt)
    VALUES ('buyer@test.com', '9876543211', 'HASHED_PASSWORD', 'Buyer', 'Jane', 'Buyer', 1, 1, 0, GETUTCDATE())
    SET @BuyerId = @@IDENTITY
END

-- Create test product if not exists
DECLARE @ProductId INT
IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Test Product')
BEGIN
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, IsActive, CreatedAt)
    VALUES (@SellerId, 1, 1, 1, 'Test Product', 'test-product', 'Test', 'Test Product', 1000, 800, 400, 18, 'TEST001', 1, GETUTCDATE())
    SET @ProductId = @@IDENTITY
END
ELSE
    SET @ProductId = (SELECT ProductId FROM Products WHERE ProductName = 'Test Product')

-- Create test address if not exists
DECLARE @AddressId INT
IF NOT EXISTS (SELECT 1 FROM Addresses WHERE UserId = @BuyerId)
BEGIN
    INSERT INTO Addresses (UserId, AddressName, MobileNumber, AddressLine1, AddressLine2, City, State, PinCode, Country, IsDefault, IsDeleted, CreatedAt)
    VALUES (@BuyerId, 'Home', '9876543211', '123 Main St', 'Apt 4B', 'Bangalore', 'Karnataka', '560001', 'India', 1, 0, GETUTCDATE())
    SET @AddressId = @@IDENTITY
END
ELSE
    SET @AddressId = (SELECT AddressId FROM Addresses WHERE UserId = @BuyerId LIMIT 1)

-- Create test order if not exists
DECLARE @OrderId INT
IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderNumber = 'TEST001')
BEGIN
    INSERT INTO Orders (UserId, ShippingAddressId, OrderNumber, Status, PaymentMethod, PaymentStatus, TotalMRP, TotalDiscount, CouponDiscount, TaxAmount, ShippingCharge, TotalAmount, OrderDate, CreatedAt)
    VALUES (@BuyerId, @AddressId, 'TEST001', 'Pending', 'COD', 'Pending', 1000, 200, 0, 144, 50, 994, GETUTCDATE(), GETUTCDATE())
    SET @OrderId = @@IDENTITY
END
ELSE
    SET @OrderId = (SELECT OrderId FROM Orders WHERE OrderNumber = 'TEST001')

-- Create test order items
IF NOT EXISTS (SELECT 1 FROM OrderItems WHERE OrderId = @OrderId)
BEGIN
    INSERT INTO OrderItems (OrderId, ProductId, SellerId, Quantity, MRP, SellingPrice, DiscountAmount, TaxAmount, TotalAmount, Status, CreatedAt)
    VALUES (@OrderId, @ProductId, @SellerId, 1, 1000, 800, 200, 144, 994, 'Pending', GETUTCDATE())
END

-- Print results
PRINT '=== Test Data Seeded ==='
PRINT 'Seller ID: ' + CAST(@SellerId AS VARCHAR)
PRINT 'Buyer ID: ' + CAST(@BuyerId AS VARCHAR)
PRINT 'Product ID: ' + CAST(@ProductId AS VARCHAR)
PRINT 'Order ID: ' + CAST(@OrderId AS VARCHAR)
PRINT ''
PRINT 'Seller Email: seller@test.com'
PRINT 'Buyer Email: buyer@test.com'
PRINT ''
PRINT 'Test order created:'
SELECT OrderId, OrderNumber, Status, TotalAmount FROM Orders WHERE OrderId = @OrderId
