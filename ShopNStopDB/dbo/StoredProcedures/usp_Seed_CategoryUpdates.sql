CREATE PROCEDURE [dbo].[usp_Seed_CategoryUpdates]
AS
BEGIN
    SET NOCOUNT ON;

    -- Get category IDs
    DECLARE @MenCategoryId INT = (SELECT CategoryId FROM Categories WHERE CategoryName = 'Men' AND IsDeleted = 0)
DECLARE @WomenCategoryId INT = (SELECT CategoryId FROM Categories WHERE CategoryName = 'Women' AND IsDeleted = 0)
DECLARE @KidsCategoryId INT = (SELECT CategoryId FROM Categories WHERE CategoryName = 'Kids' AND IsDeleted = 0)
DECLARE @BrandId INT = 1  -- Default brand
DECLARE @SellerId INT = 1  -- Default seller
DECLARE @CurrentDate DATETIME2 = GETUTCDATE()

-- ============================================================
-- STEP 1: Remove incorrect subcategories
-- ============================================================
-- Remove "Dresses" from Men if it exists
UPDATE SubCategories SET IsDeleted = 1, UpdatedAt = @CurrentDate
WHERE CategoryId = @MenCategoryId AND SubCategoryName IN ('Dresses', 'Skirts', 'Sarees', 'Lehengas')

-- ============================================================
-- STEP 2: Add/Verify WOMEN Subcategories
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Casual Wear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@WomenCategoryId, 'Casual Wear', 'women-casual-wear', 'https://via.placeholder.com/50?text=CasualWear', 1, 1, 'Women Casual Wear', 'Shop women casual wear', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Formal Wear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@WomenCategoryId, 'Formal Wear', 'women-formal-wear', 'https://via.placeholder.com/50?text=FormalWear', 2, 1, 'Women Formal Wear', 'Shop women formal wear', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Indian & Festive Wear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@WomenCategoryId, 'Indian & Festive Wear', 'women-indian-festive-wear', 'https://via.placeholder.com/50?text=IndianWear', 3, 1, 'Women Indian & Festive Wear', 'Shop women Indian & festive wear', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Innerewear & Sleepwear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@WomenCategoryId, 'Innerewear & Sleepwear', 'women-innerwear-sleepwear', 'https://via.placeholder.com/50?text=Innerwear', 4, 0, 'Women Innerwear & Sleepwear', 'Shop women innerwear & sleepwear', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Footwear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@WomenCategoryId, 'Footwear', 'women-footwear', 'https://via.placeholder.com/50?text=Footwear', 5, 1, 'Women Footwear', 'Shop women shoes & footwear', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Accessories' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@WomenCategoryId, 'Accessories', 'women-accessories', 'https://via.placeholder.com/50?text=Accessories', 6, 1, 'Women Accessories', 'Shop women accessories', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Winterwear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@WomenCategoryId, 'Winterwear', 'women-winterwear', 'https://via.placeholder.com/50?text=Winterwear', 7, 1, 'Women Winterwear', 'Shop women winterwear', 1)

-- ============================================================
-- STEP 3: Add/Verify KIDS Subcategories
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Boys Wear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@KidsCategoryId, 'Boys Wear', 'kids-boys-wear', 'https://via.placeholder.com/50?text=BoysWear', 1, 1, 'Kids Boys Wear', 'Shop boys clothing', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Girls Wear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@KidsCategoryId, 'Girls Wear', 'kids-girls-wear', 'https://via.placeholder.com/50?text=GirlsWear', 2, 1, 'Kids Girls Wear', 'Shop girls clothing', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Innerwear & Sleepwear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@KidsCategoryId, 'Innerwear & Sleepwear', 'kids-innerwear-sleepwear', 'https://via.placeholder.com/50?text=Innerwear', 3, 0, 'Kids Innerwear & Sleepwear', 'Shop kids innerwear & sleepwear', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Footwear' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@KidsCategoryId, 'Footwear', 'kids-footwear', 'https://via.placeholder.com/50?text=KidsFootwear', 4, 1, 'Kids Footwear', 'Shop kids shoes & footwear', 1)

IF NOT EXISTS (SELECT 1 FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Accessories' AND IsDeleted = 0)
    INSERT INTO SubCategories (CategoryId, SubCategoryName, SlugUrl, IconUrl, SortOrder, IsFeatured, MetaTitle, MetaDescription, IsActive)
    VALUES (@KidsCategoryId, 'Accessories', 'kids-accessories', 'https://via.placeholder.com/50?text=KidsAccessories', 5, 1, 'Kids Accessories', 'Shop kids accessories', 1)

-- ============================================================
-- STEP 4: Add Sample Products for Women Category
-- ============================================================
-- Casual Wear Products for Women
DECLARE @CasualWearSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Casual Wear' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Women White Cotton T-Shirt' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @WomenCategoryId, @CasualWearSubCatId, 'Women White Cotton T-Shirt', 'women-white-cotton-tshirt', 'Comfortable white cotton t-shirt for women', 'Premium quality white cotton t-shirt perfect for casual wear', 799, 599, 250, 18, 'WTSHIRT001', 2, 'women,tshirt,casual,cotton', 'Women White T-Shirt', 'High quality cotton t-shirt', 'women t-shirt, casual wear', 1, @CurrentDate, @CurrentDate)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Women Blue Denim Jeans' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @WomenCategoryId, @CasualWearSubCatId, 'Women Blue Denim Jeans', 'women-blue-denim-jeans', 'Stylish blue denim jeans for women', 'Premium denim jeans with perfect fit and comfort', 2499, 1899, 800, 18, 'WJEANS001', 2, 'women,jeans,denim,casual', 'Women Blue Denim Jeans', 'High quality denim jeans', 'women jeans, denim, casual wear', 1, @CurrentDate, @CurrentDate)

-- Formal Wear Products for Women
DECLARE @FormalWearSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Formal Wear' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Women Black Formal Blazer' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @WomenCategoryId, @FormalWearSubCatId, 'Women Black Formal Blazer', 'women-black-formal-blazer', 'Elegant black formal blazer for professional wear', 'Premium formal blazer with perfect tailoring', 4999, 3499, 1500, 18, 'WBLAZER001', 2, 'women,blazer,formal,black', 'Women Black Formal Blazer', 'Professional blazer for women', 'women blazer, formal wear', 1, @CurrentDate, @CurrentDate)

-- Indian & Festive Wear Products for Women
DECLARE @IndianWearSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Indian & Festive Wear' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Women Silk Saree Red & Gold' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @WomenCategoryId, @IndianWearSubCatId, 'Women Silk Saree Red & Gold', 'women-silk-saree-red-gold', 'Beautiful silk saree for festive occasions', 'Premium silk saree with traditional weaving', 9999, 7499, 3000, 18, 'WSAREE001', 2, 'women,saree,silk,festive,traditional', 'Women Silk Saree', 'Traditional silk saree', 'women saree, festive wear, traditional', 1, @CurrentDate, @CurrentDate)

-- Footwear Products for Women
DECLARE @WomenFootwearSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Footwear' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Women Black Casual Shoes' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @WomenCategoryId, @WomenFootwearSubCatId, 'Women Black Casual Shoes', 'women-black-casual-shoes', 'Comfortable black casual shoes for everyday wear', 'Lightweight and comfortable casual shoes', 2499, 1699, 700, 18, 'WSHOES001', 2, 'women,shoes,casual,black', 'Women Casual Shoes', 'Comfortable casual shoes', 'women shoes, casual wear, footwear', 1, @CurrentDate, @CurrentDate)

-- Accessories Products for Women
DECLARE @WomenAccessoriesSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Accessories' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Women Leather Handbag Brown' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @WomenCategoryId, @WomenAccessoriesSubCatId, 'Women Leather Handbag Brown', 'women-leather-handbag-brown', 'Stylish brown leather handbag for everyday use', 'Premium leather handbag with quality craftsmanship', 3999, 2799, 1200, 18, 'WBAG001', 2, 'women,handbag,leather,brown', 'Women Leather Handbag', 'Premium leather handbag', 'women bag, leather, accessories', 1, @CurrentDate, @CurrentDate)

-- Winterwear Products for Women
DECLARE @WinterWearSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @WomenCategoryId AND SubCategoryName = 'Winterwear' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Women Wool Cardigan Cream' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @WomenCategoryId, @WinterWearSubCatId, 'Women Wool Cardigan Cream', 'women-wool-cardigan-cream', 'Warm and cozy wool cardigan for winter season', 'Premium wool cardigan with elegant design', 2999, 1999, 850, 18, 'WCARDIGAN001', 2, 'women,cardigan,wool,winter,cream', 'Women Wool Cardigan', 'Winter wool cardigan', 'women cardigan, winterwear, wool', 1, @CurrentDate, @CurrentDate)

-- ============================================================
-- STEP 5: Add Sample Products for Kids Category
-- ============================================================
-- Boys Wear Products for Kids
DECLARE @BoysWearSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Boys Wear' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Kids Boys Blue T-Shirt' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @KidsCategoryId, @BoysWearSubCatId, 'Kids Boys Blue T-Shirt', 'kids-boys-blue-tshirt', 'Soft and comfortable blue t-shirt for boys', 'Premium cotton t-shirt designed for kids', 499, 349, 150, 18, 'KBTSHIRT001', 3, 'kids,boys,tshirt,blue,casual', 'Kids Boys T-Shirt', 'Comfortable kids t-shirt', 'kids boys t-shirt, casual wear', 1, @CurrentDate, @CurrentDate)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Kids Boys Black Shorts' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @KidsCategoryId, @BoysWearSubCatId, 'Kids Boys Black Shorts', 'kids-boys-black-shorts', 'Comfortable black shorts for boys in summer', 'Cotton shorts perfect for kids summer wear', 699, 499, 200, 18, 'KBSHORTS001', 3, 'kids,boys,shorts,black,summer', 'Kids Boys Shorts', 'Summer shorts for kids', 'kids boys shorts, summer wear', 1, @CurrentDate, @CurrentDate)

-- Girls Wear Products for Kids
DECLARE @GirlsWearSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Girls Wear' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Kids Girls Pink Dress' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @KidsCategoryId, @GirlsWearSubCatId, 'Kids Girls Pink Dress', 'kids-girls-pink-dress', 'Adorable pink dress for young girls', 'Cotton dress with cute prints for kids', 899, 649, 280, 18, 'KGDRESS001', 4, 'kids,girls,dress,pink,casual', 'Kids Girls Dress', 'Girls casual dress', 'kids girls dress, casual wear', 1, @CurrentDate, @CurrentDate)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Kids Girls White Top' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @KidsCategoryId, @GirlsWearSubCatId, 'Kids Girls White Top', 'kids-girls-white-top', 'Stylish white top for girls everyday wear', 'Premium cotton top for kids', 549, 399, 170, 18, 'KGTOP001', 4, 'kids,girls,top,white,casual', 'Kids Girls Top', 'Girls casual top', 'kids girls top, casual wear', 1, @CurrentDate, @CurrentDate)

-- Kids Footwear Products
DECLARE @KidsFootwearSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Footwear' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Kids Sports Shoes Blue' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @KidsCategoryId, @KidsFootwearSubCatId, 'Kids Sports Shoes Blue', 'kids-sports-shoes-blue', 'Comfortable sports shoes for active kids', 'Durable sports shoes with cushioning', 1999, 1399, 600, 18, 'KSHOES001', 3, 'kids,shoes,sports,blue,footwear', 'Kids Sports Shoes', 'Kids sports footwear', 'kids shoes, sports wear, footwear', 1, @CurrentDate, @CurrentDate)

-- Kids Accessories Products
DECLARE @KidsAccessoriesSubCatId INT = (SELECT SubCategoryId FROM SubCategories WHERE CategoryId = @KidsCategoryId AND SubCategoryName = 'Accessories' AND IsDeleted = 0)

IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductName = 'Kids Red Baseball Cap' AND IsDeleted = 0)
    INSERT INTO Products (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl, ShortDescription, LongDescription, MRP, SellingPrice, CostPrice, GstRate, Sku, GenderTypeId, Tags, MetaTitle, MetaDescription, MetaKeywords, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SellerId, @BrandId, @KidsCategoryId, @KidsAccessoriesSubCatId, 'Kids Red Baseball Cap', 'kids-red-baseball-cap', 'Stylish red baseball cap for kids', 'Cotton cap with adjustable fit', 399, 279, 120, 18, 'KCAP001', 3, 'kids,cap,baseball,red,accessories', 'Kids Baseball Cap', 'Kids cap accessory', 'kids cap, baseball cap, accessories', 1, @CurrentDate, @CurrentDate)

-- ============================================================
-- STEP 6: Verify the Data
-- ============================================================
PRINT '=== Category Update Complete ==='
PRINT ''
PRINT '--- WOMEN SubCategories ---'
SELECT SubCategoryId, SubCategoryName, SortOrder, IsFeatured FROM SubCategories
WHERE CategoryId = @WomenCategoryId AND IsDeleted = 0 ORDER BY SortOrder

PRINT ''
PRINT '--- KIDS SubCategories ---'
SELECT SubCategoryId, SubCategoryName, SortOrder, IsFeatured FROM SubCategories
WHERE CategoryId = @KidsCategoryId AND IsDeleted = 0 ORDER BY SortOrder

PRINT ''
PRINT '--- Total Products Added ---'
SELECT COUNT(*) as TotalProducts FROM Products WHERE (CategoryId = @WomenCategoryId OR CategoryId = @KidsCategoryId) AND IsDeleted = 0
END;
GO
