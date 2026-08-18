-- ============================================================================
-- Seed_CatalogSample.sql
-- ----------------------------------------------------------------------------
-- Idempotent catalog sample: ~24 fully-populated products across 4 menus
-- (MEN, WOMEN, KIDS, HOME). Each product has 2 images, 6 variants (2 colors
-- x 3 sizes), 5 specifications, and all extended detail fields filled in.
--
-- Re-runnable: uses WHERE NOT EXISTS on SlugUrl. Safe to run multiple times.
-- Targets SellerId = 1 (Demo Seller Store). Products land Approved (status=2).
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

DECLARE @SellerId INT = (SELECT TOP 1 SellerId FROM Sellers ORDER BY SellerId);
DECLARE @AdminId  INT = (SELECT TOP 1 UserId FROM Users WHERE Email = N'admin@stopnshop.com');

-- WOMEN > Clothing > (Dresses, Tops) taxonomy is now seeded via
-- Seed_Categories.sql + Seed_SubCategories.sql. Nothing to insert here.

-- Resolve all target subcategory IDs into vars for product inserts
DECLARE @SC_MenTShirts INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N't-shirts');
DECLARE @SC_MenShirts  INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'shirts');
DECLARE @SC_WomenDress INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'women-dresses');
DECLARE @SC_WomenTops  INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'women-tops');
DECLARE @SC_KidsToys   INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'toys-games');
DECLARE @SC_HomeBedding INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'bedding');

-- Resolve Category IDs (needed by Products.CategoryId)
DECLARE @C_MenClothing INT = (SELECT CategoryId FROM Categories WHERE SlugUrl = N'clothing' AND MenuId = 1);
DECLARE @C_KidsToys    INT = (SELECT TOP 1 sc.CategoryId FROM SubCategories sc WHERE sc.SubCategoryId = @SC_KidsToys);
DECLARE @C_HomeLiving  INT = (SELECT TOP 1 sc.CategoryId FROM SubCategories sc WHERE sc.SubCategoryId = @SC_HomeBedding);

-- ── Image pool (rotate through existing wwwroot uploads) ─────────────────────
DECLARE @IMGS TABLE (Idx INT IDENTITY(0,1) PRIMARY KEY, Url NVARCHAR(500));
INSERT INTO @IMGS (Url) VALUES
    (N'https://i.ibb.co/dJPb2n8h/photo-1521572163474-6864f9cf17ab-w-800.jpg'),
    (N'https://i.ibb.co/20nN28L4/photo-1564584217132-2271feaeb3c5-w-800.jpg'),
    (N'https://i.ibb.co/0VWWs3SD/photo-1542272604-787c3835535d-w-800.jpg'),
    (N'https://i.ibb.co/JwbcVHTK/photo-1542291026-7eec264c27ff-w-800.jpg'),
    (N'https://i.ibb.co/pB34sWkB/photo-1503341504253-dff4815485f1-w-800.jpg'),
    (N'https://i.ibb.co/hR4TtgpG/photo-1493663284031-b7e3aefcae8e-w-800.jpg'),
    (N'https://i.ibb.co/QFJLPVgk/photo-1599643478518-a784e5dc4c8f-w-800.jpg'),
    (N'https://i.ibb.co/bMsVtkTn/photo-1556228720-195a672e8a03-w-800.jpg'),
    (N'https://i.ibb.co/PX9DXvY/photo-1571781926291-c477ebfd024b-w-800.jpg'),
    (N'https://i.ibb.co/NHXDRJN/photo-1556909114-f6e7ad7d3136-w-800.jpg'),
    (N'https://i.ibb.co/fYgNSDQx/photo-1603487742131-4160ec999306-w-800.jpg'),
    (N'https://i.ibb.co/0kxM752/photo-1549298916-b41d501d3772-w-800.jpg'),
    (N'https://i.ibb.co/jvN57snF/photo-1560343090-f0409e92791a-w-800.jpg');

DECLARE @ImgCount INT = (SELECT COUNT(*) FROM @IMGS);

-- ── Product template procedure (inlined per row to keep file self-contained) ──
-- Pattern repeated per product. We use a helper inline-block approach.

DECLARE @ProductId INT;
DECLARE @ImgIdx    INT = 0;

-- Helper: insert one product + its children. Repeated below.
-- To stay readable, products are grouped by subcategory.

-- ─────────────────────────────────────────────────────────────────────────────
-- MEN > Clothing > T-Shirts (4 products)
-- ─────────────────────────────────────────────────────────────────────────────
EXEC sp_executesql N'';  -- noop separator

DECLARE @cur_slug NVARCHAR(300), @cur_name NVARCHAR(300), @cur_brand INT,
        @cur_short NVARCHAR(500), @cur_long NVARCHAR(MAX),
        @cur_mrp DECIMAL(18,2), @cur_sell DECIMAL(18,2),
        @cur_subcat INT, @cur_cat INT, @cur_sku NVARCHAR(100),
        @cur_material NVARCHAR(200), @cur_care NVARCHAR(500),
        @cur_fit NVARCHAR(50), @cur_country NVARCHAR(100),
        @cur_warranty NVARCHAR(500), @cur_delivery NVARCHAR(500);

-- =============================================================
-- Helper macro idea: define a temp table of product definitions
-- and a cursor that inserts each row + children. This keeps the
-- file compact and editable.
-- =============================================================

DECLARE @ProductDefs TABLE (
    Idx INT IDENTITY(1,1) PRIMARY KEY,
    Slug         NVARCHAR(300),
    Name         NVARCHAR(300),
    BrandId      INT,
    ShortDesc    NVARCHAR(500),
    LongDesc     NVARCHAR(MAX),
    MRP          DECIMAL(18,2),
    Selling      DECIMAL(18,2),
    SubCategoryId INT,
    CategoryId    INT,
    Material     NVARCHAR(200),
    Care         NVARCHAR(500),
    FitType      NVARCHAR(50),
    CountryOfOrigin NVARCHAR(100),
    WarrantyInfo NVARCHAR(500),
    DeliveryInfo NVARCHAR(500),
    HasSizes     BIT,   -- false → no apparel sizes, e.g. bedding/toys
    SizeKind     NVARCHAR(20) -- 'apparel' | 'footwear' | 'kids' | 'home'
);

INSERT INTO @ProductDefs (Slug, Name, BrandId, ShortDesc, LongDesc, MRP, Selling, SubCategoryId, CategoryId, Material, Care, FitType, CountryOfOrigin, WarrantyInfo, DeliveryInfo, HasSizes, SizeKind) VALUES
-- MEN > T-Shirts (BrandId 7 = Allen Solly, 3 = H&M, 4 = Zara)
(N'mens-classic-cotton-tee-white',     N'Classic Cotton T-Shirt',           7, N'Soft 100% combed cotton crew-neck tee.',          N'A wardrobe essential cut from soft combed cotton. Tailored for everyday comfort with a clean crew neckline, taped shoulders, and a slight stretch for movement.', 999,  599,  @SC_MenTShirts, @C_MenClothing, N'100% Cotton',        N'Machine wash cold, tumble dry low', N'Regular Fit', N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'mens-graphic-tee-charcoal',         N'Graphic Print T-Shirt',            3, N'Soft cotton-blend tee with bold front graphic.',  N'Make a statement in this graphic tee featuring a signature front print. Constructed from a cotton-blend fabric that holds its shape wash after wash.', 1299, 749,  @SC_MenTShirts, @C_MenClothing, N'Cotton Blend',       N'Machine wash gentle, do not iron print', N'Slim Fit', N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'mens-polo-pique-tee-navy',          N'Polo Pique T-Shirt',               4, N'Classic pique polo with two-button placket.',     N'A timeless polo crafted from breathable pique cotton, finished with a flat-knit collar and tonal buttons. Pair with chinos or shorts.', 1499, 899,  @SC_MenTShirts, @C_MenClothing, N'Pique Cotton',       N'Machine wash, hang dry',           N'Regular Fit', N'India',  N'1-year manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'mens-henley-tee-olive',             N'Henley Neck T-Shirt',              6, N'Three-button henley in soft jersey cotton.',      N'A relaxed henley with a button-down neckline and clean topstitching. Layer it solo or under a jacket for a polished casual look.', 1199, 699,  @SC_MenTShirts, @C_MenClothing, N'Jersey Cotton',      N'Machine wash cold',                N'Regular Fit', N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),

-- MEN > Shirts
(N'mens-formal-shirt-white',           N'Manhattan Formal Shirt',           8, N'Slim-fit pure cotton formal shirt with cutaway collar.', N'Tailored for the modern office, this formal shirt features pure cotton fabric, a cutaway collar, single-button cuffs, and a slim through-the-body fit.', 2399, 1223, @SC_MenShirts,  @C_MenClothing, N'Pure Cotton',        N'Dry clean recommended',            N'Slim Fit',    N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'mens-casual-checked-shirt',         N'Casual Checked Shirt',             5, N'Mid-weight cotton flannel with windowpane check.', N'A versatile checked shirt cut from soft mid-weight flannel. Wear it open over a tee on weekends, or tucked-in with chinos for smart-casual occasions.',           1899, 999,  @SC_MenShirts,  @C_MenClothing, N'Cotton Flannel',     N'Machine wash gentle',              N'Regular Fit', N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'mens-linen-shirt-beige',            N'Pure Linen Shirt',                 4, N'Breathable 100% linen, perfect for warm days.',   N'Cool, breezy and resort-ready — a pure linen shirt with a relaxed silhouette and a half-button placket. Pre-washed for a lived-in softness.', 2299, 1199, @SC_MenShirts,  @C_MenClothing, N'100% Linen',         N'Hand wash cold, line dry',         N'Regular Fit', N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'mens-denim-shirt-indigo',           N'Indigo Denim Shirt',               5, N'Mid-wash denim shirt with western yoke detail.',  N'A go-anywhere denim shirt crafted from soft mid-wash denim with a Western yoke, double chest pockets, and pearl-snap buttons.', 2599, 1499, @SC_MenShirts,  @C_MenClothing, N'Denim (Cotton)',     N'Machine wash with similar colors', N'Slim Fit',    N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),

-- WOMEN > Dresses
(N'womens-floral-midi-dress',          N'Floral Midi Dress',                9, N'Tiered midi dress with all-over floral print.',   N'A romantic midi dress with a tiered skirt, ruched bodice and delicate puff sleeves. Crafted from a lightweight rayon that drapes beautifully.',             2599, 1499, @SC_WomenDress, @WomenClothingId, N'Rayon',              N'Machine wash gentle, do not bleach', N'A-Line',  N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'womens-bodycon-evening-dress',      N'Bodycon Evening Dress',            4, N'Sleek bodycon dress for evenings out.',           N'A fitted bodycon evening dress in stretch crepe, finished with a flattering V-neckline and three-quarter sleeves. Statement-ready, all night.',              2999, 1799, @SC_WomenDress, @WomenClothingId, N'Stretch Crepe',      N'Dry clean only',                   N'Bodycon',     N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'womens-anarkali-blue-festive',      N'Anarkali Festive Dress',           9, N'Embroidered Anarkali with churidar — festive edit.', N'A festive Anarkali in cotton-silk blend featuring intricate thread embroidery, scalloped hemline and a paired dupatta. Includes matching churidar.',     4999, 2999, @SC_WomenDress, @WomenClothingId, N'Cotton-Silk Blend',  N'Dry clean only',                   N'Flared',      N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'womens-shirt-dress-olive',          N'Shirt Dress',                      7, N'Versatile knee-length shirt dress with waist tie.', N'A clean-lined shirt dress in soft tencel-cotton with a relaxed silhouette, removable waist tie, and a button-through front. From desk to dinner.',          2299, 1349, @SC_WomenDress, @WomenClothingId, N'Tencel-Cotton',      N'Machine wash cold',                N'Regular Fit', N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),

-- WOMEN > Tops
(N'womens-cropped-tee-pink',           N'Cropped Cotton Tee',               3, N'Soft cotton crop tee with relaxed boxy fit.',     N'An everyday crop tee in soft 100% cotton with a slightly boxy silhouette. Pairs perfectly with high-rise jeans or skirts.', 999,  549,  @SC_WomenTops,  @WomenClothingId, N'100% Cotton',        N'Machine wash cold',                N'Boxy',        N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'womens-ribbed-tank-black',          N'Ribbed Knit Tank',                 4, N'Soft ribbed knit tank with a sleek scoop neck.',  N'A second-skin ribbed knit tank in a luxe stretch viscose blend. Wear it solo or layered under a blazer for a polished evening look.',     1199, 699,  @SC_WomenTops,  @WomenClothingId, N'Viscose Blend',      N'Hand wash cold, lay flat to dry',  N'Slim Fit',    N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'womens-puff-sleeve-blouse',         N'Puff-Sleeve Blouse',               9, N'Romantic puff-sleeve blouse with a tie neckline.', N'A statement blouse in flowy georgette featuring voluminous puff sleeves, a self-tie neckline, and a relaxed silhouette through the body.', 1899, 1099, @SC_WomenTops,  @WomenClothingId, N'Georgette',          N'Hand wash cold, iron low',         N'Relaxed Fit', N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),
(N'womens-button-down-shirt-white',    N'Crisp White Button-Down',          8, N'Classic poplin button-down shirt.',                N'A wardrobe staple — the perfect white button-down in crisp cotton poplin with a clean point collar and slightly fitted waist. Endlessly versatile.',     2199, 1249, @SC_WomenTops,  @WomenClothingId, N'Cotton Poplin',      N'Machine wash, iron medium',        N'Regular Fit', N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'apparel'),

-- KIDS > Toys & Games (no sizes)
(N'kids-wooden-blocks-set',            N'Wooden Building Blocks Set (50pc)', 11, N'50-piece natural wood block set, ages 3+.',      N'A heirloom-quality 50-piece wooden block set crafted from sustainable beechwood. Develops fine motor skills, creativity and spatial reasoning. Ages 3+.', 1499, 899,  @SC_KidsToys,  @C_KidsToys,   N'Beechwood',           N'Wipe clean with damp cloth',       N'',           N'India',  N'6-month manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 0, N'home'),
(N'kids-plush-teddy-large',            N'Cuddly Plush Teddy Bear',           11, N'Extra-soft 18-inch plush teddy bear.',           N'A super-soft 18-inch teddy bear filled with hypoallergenic polyester fibre and finished with embroidered eyes — safe for little ones.', 1999, 1199, @SC_KidsToys,  @C_KidsToys,   N'Plush Polyester',     N'Spot clean only',                  N'',           N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 0, N'home'),
(N'kids-puzzle-100pc-world-map',       N'World Map Jigsaw Puzzle (100pc)',  11, N'Educational 100-piece world map jigsaw.',        N'Explore continents and oceans through a beautifully illustrated 100-piece jigsaw puzzle. Sturdy cardboard pieces with a satin finish.', 899,  499,  @SC_KidsToys,  @C_KidsToys,   N'Cardboard',           N'Keep dry',                          N'',           N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 0, N'home'),
(N'kids-art-craft-kit',                N'Complete Art & Craft Kit',         11, N'150-piece art set with crayons, paints, brushes.', N'A full creative starter kit with crayons, watercolours, brushes, sketch pencils, glue and craft paper — packed in a portable carry case.', 1799, 999,  @SC_KidsToys,  @C_KidsToys,   N'Mixed Materials',     N'Store dry',                         N'',           N'India',  N'No warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', 0, N'home'),

-- HOME > Bedding (king/queen/single)
(N'home-cotton-bedsheet-king',         N'Premium Cotton Bedsheet (King)',    3, N'300-thread-count cotton bedsheet with two pillow covers.', N'A luxuriously soft 300-thread-count cotton bedsheet for king-size beds, paired with two matching pillow covers. Fade-resistant prints.', 2999, 1599, @SC_HomeBedding, @C_HomeLiving, N'300-TC Cotton',       N'Machine wash warm, tumble dry low', N'',          N'India',  N'1-year quality warranty',     N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'home'),
(N'home-satin-quilt-cover',            N'Satin Quilt Cover Set',             3, N'Smooth satin-finish quilt cover for queen beds.', N'Drift to sleep in this satin-finish quilt cover set, including the cover and two pillow shams. Hidden zipper closure for a clean look.', 3499, 1999, @SC_HomeBedding, @C_HomeLiving, N'Satin Polyester',     N'Machine wash cold',                 N'',           N'India',  N'1-year quality warranty',     N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'home'),
(N'home-blanket-fleece',               N'Ultra-Soft Fleece Blanket',         3, N'Lightweight fleece throw blanket.',               N'Cosy up with this ultra-soft fleece blanket featuring double-stitched edges and an anti-pill finish. Perfect for sofas or extra bed warmth.',         1799, 999,  @SC_HomeBedding, @C_HomeLiving, N'Polar Fleece',        N'Machine wash, do not iron',         N'',           N'India',  N'30-day quality guarantee',    N'Free shipping above ₹999. Ships in 1-2 business days.', 1, N'home'),
(N'home-pillow-cover-pair',            N'Embroidered Pillow Cover (Pair)',   3, N'Set of 2 embroidered cotton pillow covers.',      N'A pair of cotton pillow covers with intricate hand embroidery. 18 x 27 inches — fits standard pillows. Hidden zipper closure.',             999,  549,  @SC_HomeBedding, @C_HomeLiving, N'100% Cotton',         N'Machine wash cold, iron low',       N'',           N'India',  N'No warranty',                  N'Free shipping above ₹999. Ships in 1-2 business days.', 0, N'home');


-- ── Now loop the temp table and insert ───────────────────────────────────────
DECLARE @i INT = 1, @max INT = (SELECT COUNT(*) FROM @ProductDefs);
DECLARE @newPid INT;

WHILE @i <= @max
BEGIN
    SELECT
        @cur_slug = Slug, @cur_name = Name, @cur_brand = BrandId,
        @cur_short = ShortDesc, @cur_long = LongDesc,
        @cur_mrp = MRP, @cur_sell = Selling,
        @cur_subcat = SubCategoryId, @cur_cat = CategoryId,
        @cur_material = Material, @cur_care = Care, @cur_fit = FitType,
        @cur_country = CountryOfOrigin, @cur_warranty = WarrantyInfo, @cur_delivery = DeliveryInfo
    FROM @ProductDefs WHERE Idx = @i;

    -- skip if product already exists (idempotent)
    IF NOT EXISTS (SELECT 1 FROM Products WHERE SlugUrl = @cur_slug AND IsDeleted = 0)
    BEGIN
        INSERT INTO Products
            (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl,
             ShortDescription, LongDescription, MRP, SellingPrice, Sku,
             ApprovalStatus, IsActive, IsDeleted, CreatedBy,
             Material, CareInstructions, FitType, CountryOfOrigin, WarrantyInfo, DeliveryInfo)
        VALUES
            (@SellerId, @cur_brand, @cur_cat, @cur_subcat, @cur_name, @cur_slug,
             @cur_short, @cur_long, @cur_mrp, @cur_sell, N'SEED-' + UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''), 8)),
             2, 1, 0, @AdminId,
             @cur_material, @cur_care, @cur_fit, @cur_country, @cur_warranty, @cur_delivery);

        SET @newPid = SCOPE_IDENTITY();

        -- Link to ProductSubCategories
        INSERT INTO ProductSubCategories (ProductId, SubCategoryId)
        VALUES (@newPid, @cur_subcat);

        -- 2 images (rotated from pool)
        INSERT INTO ProductImages (ProductId, ImageUrl, AltText, SortOrder, IsPrimary)
        SELECT @newPid, (SELECT Url FROM @IMGS WHERE Idx = (@ImgIdx % @ImgCount)),       @cur_name, 0, 1
        UNION ALL
        SELECT @newPid, (SELECT Url FROM @IMGS WHERE Idx = ((@ImgIdx + 1) % @ImgCount)), @cur_name, 1, 0;
        SET @ImgIdx = @ImgIdx + 2;

        -- Variants
        DECLARE @hasSizes BIT = (SELECT HasSizes FROM @ProductDefs WHERE Idx = @i);
        DECLARE @sizeKind NVARCHAR(20) = (SELECT SizeKind FROM @ProductDefs WHERE Idx = @i);

        IF @hasSizes = 1
        BEGIN
            DECLARE @sizes TABLE (S NVARCHAR(20));
            DELETE FROM @sizes;
            IF @sizeKind = N'apparel'
                INSERT INTO @sizes VALUES (N'S'), (N'M'), (N'L');
            ELSE IF @sizeKind = N'home'
                INSERT INTO @sizes VALUES (N'Single'), (N'Queen'), (N'King');

            INSERT INTO ProductVariants (ProductId, Color, ColorHexCode, Size, VariantSku, AdditionalPrice, StockQuantity, LowStockThreshold, IsActive, IsDeleted)
            SELECT @newPid, c.Color, c.Hex, s.S,
                   N'V' + RIGHT(N'000000' + CAST(@newPid AS NVARCHAR(10)), 6) + N'-' + LEFT(c.Color, 3) + N'-' + s.S,
                   0, 25, 5, 1, 0
            FROM (VALUES (N'Black', N'#000000'), (N'Navy', N'#1E3A8A')) AS c(Color, Hex)
            CROSS JOIN @sizes s;
        END
        ELSE
        BEGIN
            -- 2 color-only variants for accessories / toys
            INSERT INTO ProductVariants (ProductId, Color, ColorHexCode, Size, VariantSku, AdditionalPrice, StockQuantity, LowStockThreshold, IsActive, IsDeleted)
            VALUES
                (@newPid, N'Default',  N'#888888', NULL, N'V' + RIGHT(N'000000' + CAST(@newPid AS NVARCHAR(10)), 6) + N'-DEF', 0, 50, 5, 1, 0),
                (@newPid, N'Variant2', N'#444444', NULL, N'V' + RIGHT(N'000000' + CAST(@newPid AS NVARCHAR(10)), 6) + N'-VR2', 0, 30, 5, 1, 0);
        END

        -- 5 specification rows
        INSERT INTO ProductSpecifications (ProductId, SpecKey, SpecValue, SortOrder, IsDeleted)
        VALUES
            (@newPid, N'Material',         @cur_material, 0, 0),
            (@newPid, N'Care',             @cur_care,     1, 0),
            (@newPid, N'Country of Origin', @cur_country, 2, 0),
            (@newPid, N'Fit / Type',       ISNULL(NULLIF(@cur_fit, N''), N'Standard'), 3, 0),
            (@newPid, N'Warranty',         @cur_warranty, 4, 0);
    END

    SET @i = @i + 1;
END

PRINT 'Seed_CatalogSample.sql complete.';
GO
