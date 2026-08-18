-- ============================================================================
-- Seed_FullCatalog.sql
-- ----------------------------------------------------------------------------
-- Fills every storefront subcategory left empty by Seed_CatalogSample so the
-- 3-level filter has products everywhere. ~42 products, 3 per subcategory,
-- all owned by the demo seller (SellerId = 1, demoseller@stopnshop.com).
--
-- Idempotent: each product is guarded by `WHERE NOT EXISTS (SlugUrl)`. Safe
-- to re-run; brand FK falls back to the lowest-id brand if a name lookup
-- misses; subcategory blocks no-op if the subcategory is absent.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

DECLARE @SellerId    INT = (SELECT TOP 1 SellerId FROM Sellers ORDER BY SellerId);
DECLARE @AdminId     INT = (SELECT TOP 1 UserId FROM Users WHERE Email = N'admin@stopnshop.com');
DECLARE @FallbackBr  INT = (SELECT TOP 1 BrandId FROM Brands ORDER BY BrandId);

-- ── Brand lookups (NULL-safe via COALESCE to fallback) ──────────────────────
DECLARE @B_Nike       INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Nike'),        @FallbackBr);
DECLARE @B_Adidas     INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Adidas'),      @FallbackBr);
DECLARE @B_HM         INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'H&M'),         @FallbackBr);
DECLARE @B_Zara       INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Zara'),        @FallbackBr);
DECLARE @B_Levis      INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Levi''s'),     @FallbackBr);
DECLARE @B_Puma       INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Puma'),        @FallbackBr);
DECLARE @B_AllenSolly INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Allen Solly'), @FallbackBr);
DECLARE @B_VanHeusen  INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Van Heusen'),  @FallbackBr);
DECLARE @B_Biba       INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Biba'),        @FallbackBr);
DECLARE @B_W          INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'W'),           @FallbackBr);
DECLARE @B_Woodland   INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Woodland'),    @FallbackBr);
DECLARE @B_Fastrack   INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Fastrack'),    @FallbackBr);
DECLARE @B_Lakme      INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Lakme'),       @FallbackBr);
DECLARE @B_LOreal     INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'L''Oreal'),    @FallbackBr);
DECLARE @B_Raymond    INT = COALESCE((SELECT BrandId FROM Brands WHERE BrandName = N'Raymond'),     @FallbackBr);

-- ── SubCategory + Category lookups ──────────────────────────────────────────
DECLARE @SC_Jeans      INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'jeans-trousers');
DECLARE @SC_Dresses    INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'dresses');
DECLARE @SC_Ethnic     INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'ethnic-wear');
DECLARE @SC_Sneakers   INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'sneakers');
DECLARE @SC_Formal     INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'formal-shoes');
DECLARE @SC_Sandals    INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'sandals-slippers');
DECLARE @SC_Baby       INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'baby-essentials');
DECLARE @SC_Furniture  INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'furniture');
DECLARE @SC_Kitchen    INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'kitchen-dining');
DECLARE @SC_Skincare   INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'skincare');
DECLARE @SC_Haircare   INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'haircare');
DECLARE @SC_Fragrances INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'fragrances');
DECLARE @SC_Watches    INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'watches');
DECLARE @SC_Jewellery  INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'jewellery');
DECLARE @SC_WSarees    INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'women-sarees');
DECLARE @SC_WKurtas    INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'women-kurtas');
DECLARE @SC_WEthnic    INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'women-ethnic');
DECLARE @SC_WShoes     INT = (SELECT SubCategoryId FROM SubCategories WHERE SlugUrl = N'women-shoes');

-- Parent category for each subcategory (Products.CategoryId is NOT NULL)
DECLARE @C_MenClothing   INT = (SELECT CategoryId FROM SubCategories WHERE SubCategoryId = @SC_Jeans);
DECLARE @C_MenFootwear   INT = (SELECT CategoryId FROM SubCategories WHERE SubCategoryId = @SC_Sneakers);
DECLARE @C_KidsToysBaby  INT = (SELECT CategoryId FROM SubCategories WHERE SubCategoryId = @SC_Baby);
DECLARE @C_HomeLiving    INT = (SELECT CategoryId FROM SubCategories WHERE SubCategoryId = @SC_Furniture);
DECLARE @C_Beauty        INT = (SELECT CategoryId FROM SubCategories WHERE SubCategoryId = @SC_Skincare);
DECLARE @C_WatchesAccess INT = (SELECT CategoryId FROM SubCategories WHERE SubCategoryId = @SC_Watches);
DECLARE @C_WClothing     INT = (SELECT CategoryId FROM SubCategories WHERE SubCategoryId = @SC_WSarees);
DECLARE @C_WFootwear     INT = (SELECT CategoryId FROM SubCategories WHERE SubCategoryId = @SC_WShoes);

-- ── Image pool (shared with Seed_CatalogSample) — hosted on ImgBB ───────────
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

-- ── Product definitions ─────────────────────────────────────────────────────
DECLARE @ProductDefs TABLE (
    Idx          INT IDENTITY(1,1) PRIMARY KEY,
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
    SizeKind     NVARCHAR(20)   -- 'apparel' | 'footwear' | 'home'
);

-- MEN > Clothing > Jeans & Trousers
IF @SC_Jeans IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'mens-jeans-slim-fit-indigo',     N'Slim Fit Indigo Jeans',         @B_Levis,      N'Five-pocket slim-fit denim in classic indigo.',         N'A wardrobe staple cut for a clean slim silhouette. Mid-rise, comfort stretch, signature contrast stitching.', 2499,1499, @SC_Jeans,@C_MenClothing, N'98% Cotton, 2% Elastane', N'Machine wash cold, tumble dry low',     N'Slim Fit',    N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'mens-jeans-relaxed-fit-black',   N'Relaxed Fit Black Jeans',       @B_AllenSolly, N'Easy-wearing relaxed-fit denim in jet black.',          N'Roomier through the thigh and leg for all-day comfort. Soft hand-feel cotton denim with a clean five-pocket finish.', 2299,1299, @SC_Jeans,@C_MenClothing, N'100% Cotton Denim',       N'Machine wash gentle, do not bleach',    N'Relaxed Fit', N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'mens-trousers-formal-charcoal',  N'Formal Trousers Charcoal',      @B_HM,         N'Mid-rise tailored formal trousers in charcoal.',        N'Polished office trousers tailored for a sharp, modern silhouette. Wrinkle-resistant blend with a clean side-pocket finish.', 1899,1099, @SC_Jeans,@C_MenClothing, N'Polyester Viscose Blend', N'Dry clean recommended',                 N'Tailored Fit',N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel');

-- MEN > Clothing > Dresses (lounge/robe-style for men)
IF @SC_Dresses IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'mens-kaftan-cotton-blue',     N'Cotton Kaftan Lounge',           @B_AllenSolly, N'Breezy long-line kaftan for at-home comfort.',         N'Cut from soft pure cotton with a relaxed straight silhouette and side slits. Perfect lounge piece for warm days.', 1799,999,  @SC_Dresses,@C_MenClothing, N'100% Cotton',         N'Machine wash cold, line dry',           N'Relaxed Fit',N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'mens-bathrobe-terry-grey',    N'Terry Cloth Bath Robe',          @B_Zara,       N'Thick terry-cloth robe with shawl collar.',            N'Absorbent loop-pile terry with a generous shawl collar, tie belt, and two patch pockets. A luxe post-shower essential.', 2499,1699, @SC_Dresses,@C_MenClothing, N'100% Cotton Terry',   N'Machine wash warm, tumble dry medium',  N'One Size',   N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'mens-night-suit-printed',     N'Printed Night Suit Set',         @B_HM,         N'Two-piece cotton night suit with all-over print.',     N'Lightweight long-sleeve top and matching pyjama bottoms. Soft hand-feel cotton, elasticated drawstring waist.', 1599,899,  @SC_Dresses,@C_MenClothing, N'100% Cotton',         N'Machine wash cold, do not bleach',      N'Regular Fit',N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel');

-- MEN > Clothing > Ethnic Wear
IF @SC_Ethnic IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'mens-kurta-pyjama-cream',     N'Cotton Kurta Pyjama Cream',      @B_Raymond,    N'Hand-finished cream kurta with matching pyjama.',      N'Festive-ready ensemble cut from soft pure cotton with a mandarin collar and subtle tonal embroidery on the placket.', 2999,1799, @SC_Ethnic,@C_MenClothing, N'100% Cotton',         N'Dry clean only',                        N'Straight Fit',N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'mens-sherwani-maroon',        N'Embroidered Sherwani Maroon',    @B_AllenSolly, N'Knee-length embroidered sherwani in deep maroon.',     N'Show-stopping wedding sherwani with intricate zardozi work on the bodice. Stand collar, matching churidar pyjama included.', 8999,6499, @SC_Ethnic,@C_MenClothing, N'Silk Blend',          N'Dry clean only',                        N'Tailored Fit',N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'mens-nehru-jacket-navy',      N'Quilted Nehru Jacket Navy',      @B_VanHeusen,  N'Mandarin-collar quilted Nehru jacket.',                N'A festive layering essential. Lightweight quilted body, hidden front placket, and deep welt pockets.', 3499,2299, @SC_Ethnic,@C_MenClothing, N'Polyester Blend',     N'Dry clean only',                        N'Slim Fit',    N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel');

-- MEN > Footwear > Sneakers
IF @SC_Sneakers IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'mens-sneakers-classic-white', N'Classic Court Sneakers',         @B_Adidas,     N'Low-top leather sneakers in clean white.',             N'Heritage court silhouette in supple full-grain leather with perforated three-stripe sides and a vulcanised gum sole.', 5999,3999, @SC_Sneakers,@C_MenFootwear, N'Full-Grain Leather', N'Wipe clean with damp cloth',           N'True to size',N'Vietnam', N'90-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear'),
(N'mens-sneakers-runner-black',  N'Performance Runner Sneakers',    @B_Nike,       N'Cushioned road runners with mesh upper.',              N'Engineered breathable mesh upper, dual-density EVA midsole, and a high-rebound foam insert for the long haul.', 7999,5499, @SC_Sneakers,@C_MenFootwear, N'Mesh & Synthetic',    N'Spot clean with mild detergent',       N'True to size',N'Vietnam', N'180-day manufacturer warranty',N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear'),
(N'mens-sneakers-canvas-red',    N'Canvas High-Top Sneakers',       @B_Puma,       N'Retro high-top in crimson canvas.',                    N'Classic high-top canvas with rubber toe cap, contrast laces, and a vulcanised gum sole. Easy off-duty wear.', 3999,2499, @SC_Sneakers,@C_MenFootwear, N'Cotton Canvas',       N'Machine wash gentle, air dry',         N'True to size',N'India',   N'30-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear');

-- MEN > Footwear > Formal Shoes
IF @SC_Formal IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'mens-oxfords-tan-leather',    N'Leather Oxford Shoes Tan',       @B_AllenSolly, N'Classic five-eyelet oxfords in burnished tan.',        N'Full-grain leather upper with a hand-burnished tan finish, leather lining, and a Goodyear-welted rubber sole.', 6999,4499, @SC_Formal,@C_MenFootwear, N'Full-Grain Leather',  N'Polish with neutral leather cream',     N'True to size',N'India',   N'90-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear'),
(N'mens-derby-black-formal',     N'Derby Lace-Up Black Formal',     @B_VanHeusen,  N'Open-laced derby in polished black calf leather.',     N'Versatile open-lacing derby with a clean apron toe. Cushioned footbed and a hand-stitched welt for durability.', 5499,3299, @SC_Formal,@C_MenFootwear, N'Calf Leather',        N'Polish with neutral leather cream',     N'True to size',N'India',   N'90-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear'),
(N'mens-loafers-brown-suede',    N'Suede Penny Loafers Brown',      @B_Woodland,   N'Hand-finished suede penny loafers.',                   N'Slip-on penny loafers in soft brushed suede with a leather-stacked heel and a flexible rubber outsole.', 4799,2899, @SC_Formal,@C_MenFootwear, N'Brushed Suede',       N'Brush gently, avoid water exposure',    N'True to size',N'India',   N'90-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear');

-- MEN > Footwear > Sandals & Slippers
IF @SC_Sandals IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'mens-flipflop-classic-black', N'Classic Flip Flops Black',       @B_Puma,       N'Soft EVA flip flops with rubber strap.',               N'Lightweight EVA footbed, anatomically contoured for everyday comfort. Quick-dry rubber strap, ideal for poolside or beach.', 999, 599,  @SC_Sandals,@C_MenFootwear, N'EVA & Rubber',       N'Wipe clean with damp cloth',           N'True to size',N'India',   N'30-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear'),
(N'mens-sport-sandals-grey',     N'Sport Sandals Adjustable Grey',  @B_Adidas,     N'Three-strap adjustable sport sandals.',                N'Hook-and-loop adjustable straps, EVA midsole, and a high-traction rubber outsole. Perfect for trails and travel.', 2499,1499, @SC_Sandals,@C_MenFootwear, N'Synthetic & Rubber', N'Wipe clean with damp cloth',           N'True to size',N'Vietnam', N'90-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear'),
(N'mens-slipons-brown-leather',  N'Leather Slip-On Sandals Brown',  @B_Woodland,   N'Open-toe leather slip-on sandals.',                    N'Full-grain leather upper with adjustable buckle, padded footbed, and a hand-stitched welt for long-haul comfort.', 3299,1999, @SC_Sandals,@C_MenFootwear, N'Full-Grain Leather', N'Polish with neutral leather cream',    N'True to size',N'India',   N'90-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear');

-- KIDS > Toys & Baby > Baby Essentials
IF @SC_Baby IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'baby-onesie-organic-pack3',   N'Organic Cotton Onesies (Pack of 3)',  @B_HM,        N'Snap-front onesies in organic cotton.',              N'Skin-friendly GOTS-certified organic cotton with snap-front closure and lap-shoulder neckline. Soft to wash, gentle to wear.', 1499,899,  @SC_Baby,@C_KidsToysBaby, N'GOTS Organic Cotton', N'Machine wash gentle, do not bleach',  N'Standard',   N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'baby-blanket-muslin-cloud',   N'Muslin Cloud Print Blanket',          @B_Biba,      N'Lightweight muslin baby blanket in cloud print.',    N'Six-layer breathable muslin, perfect for swaddling or summer blanket use. Pre-washed for everyday softness.', 1299,799,  @SC_Baby,@C_KidsToysBaby, N'100% Cotton Muslin',  N'Machine wash cold, tumble dry low',   N'Standard',   N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'baby-bath-towel-hooded',      N'Hooded Bath Towel Animal Print',      @B_AllenSolly,N'Plush hooded bath towel with animal hood.',          N'Super-soft 400 GSM cotton with a fun animal-ear hood. Wraps baby head-to-toe after bath time.', 999, 549,  @SC_Baby,@C_KidsToysBaby, N'400 GSM Cotton',      N'Machine wash warm, tumble dry medium',N'Standard',   N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home');

-- HOME > Home & Living > Furniture
IF @SC_Furniture IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'home-sofa-3seater-fabric',    N'3-Seater Fabric Sofa Beige',     @B_Raymond,    N'Mid-century 3-seater sofa in beige weave.',            N'Solid sheesham frame with high-density foam cushioning and a stain-resistant beige weave. Tapered tapered legs in walnut finish.', 39999,29999, @SC_Furniture,@C_HomeLiving, N'Wood Frame, Fabric',  N'Spot clean with mild detergent', N'Assembled',N'India', N'12-month manufacturer warranty', N'Free assembly included. Ships in 5-7 business days.', N'home'),
(N'home-coffee-table-walnut',    N'Coffee Table Solid Wood Walnut', @B_AllenSolly, N'Solid sheesham coffee table with under-shelf storage.',N'Hand-finished sheesham wood with a deep walnut stain. Lower display shelf and tapered legs in mid-century style.', 14999,9999,  @SC_Furniture,@C_HomeLiving, N'Solid Sheesham Wood', N'Dust with dry cloth',           N'Pre-assembled',N'India', N'24-month manufacturer warranty',N'Ships in 5-7 business days.', N'home'),
(N'home-bookshelf-5tier-oak',    N'5-Tier Bookshelf Oak Finish',    @B_HM,         N'Open 5-tier bookshelf in light oak finish.',           N'Sturdy engineered-wood frame with five spacious tiers, anti-tip wall mount included. Holds up to 25 kg per shelf.', 8999, 5999,  @SC_Furniture,@C_HomeLiving, N'Engineered Wood',     N'Wipe clean with dry cloth',     N'DIY Assembly',N'India', N'12-month manufacturer warranty', N'Ships in 5-7 business days.', N'home');

-- HOME > Home & Living > Kitchen & Dining
IF @SC_Kitchen IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'home-dinner-set-bone-china',  N'Bone China Dinner Set (24-Piece)',     @B_HM,         N'Premium 24-piece bone china dinner set.',          N'Pure bone china in a clean off-white finish. Service for six: dinner plates, side plates, soup bowls, dessert bowls.', 8999,5499, @SC_Kitchen,@C_HomeLiving, N'Bone China',          N'Dishwasher safe, microwave safe',     N'Standard',N'India', N'30-day breakage replacement',N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'home-cookware-cast-iron-skillet', N'Cast Iron Skillet 26cm',           @B_Raymond,    N'Pre-seasoned cast iron skillet in 26cm.',          N'Heavyweight pre-seasoned cast iron with an ergonomic handle. Suitable for stove, oven, and open-flame cooking.', 2499,1499, @SC_Kitchen,@C_HomeLiving, N'Cast Iron',           N'Rinse with hot water, dry & oil',     N'Standard',N'India', N'12-month replacement guarantee',N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'home-knife-block-6piece',     N'Stainless Steel Knife Block Set (6-Piece)', @B_AllenSolly, N'Six-piece chef knife block set with wooden stand.', N'High-carbon stainless steel knives: chef, bread, slicer, utility, paring, and kitchen shears in a solid wood block.', 4999,2999, @SC_Kitchen,@C_HomeLiving, N'Stainless Steel & Wood', N'Hand wash, dry immediately',       N'Standard',N'India', N'12-month manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home');

-- BEAUTY > Skincare
IF @SC_Skincare IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'beauty-vitamin-c-serum-30ml', N'Vitamin C Brightening Serum 30ml',     @B_Lakme,    N'10% Vitamin C facial serum for a brighter complexion.',N'Lightweight serum with 10% ethyl ascorbic acid, hyaluronic acid, and ferulic acid. Targets dullness and uneven tone over time.', 1299,799,  @SC_Skincare,@C_Beauty, N'Skincare',           N'Apply AM/PM. Avoid contact with eyes.', N'30 ml',  N'India',  N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'beauty-hydrating-moisturiser-50g', N'Hydrating Moisturiser 50g',       @B_LOreal,   N'72-hour hydration with hyaluronic acid + niacinamide.',N'Whipped gel-cream texture that sinks in instantly. Hyaluronic acid plumps and niacinamide refines pores over time.', 1499,899,  @SC_Skincare,@C_Beauty, N'Skincare',           N'Apply to clean skin morning and night.',N'50 g',   N'France', N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'beauty-spf50-sunscreen-50ml', N'SPF 50 PA+++ Sunscreen Fluid 50ml',    @B_Biba,     N'Featherlight SPF 50 PA+++ daily sunscreen.',         N'Broad-spectrum UVA + UVB protection in a milky fluid that disappears into skin. No white cast, suitable for all tones.', 1199,699,  @SC_Skincare,@C_Beauty, N'Skincare',           N'Apply generously 15 min before sun exposure.', N'50 ml', N'India', N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home');

-- BEAUTY > Haircare
IF @SC_Haircare IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'beauty-shampoo-repair-340ml', N'Repair & Restore Shampoo 340ml',       @B_LOreal,   N'Sulphate-free shampoo for damaged hair.',            N'Argan oil and keratin formula gently cleanses while restoring strength to chemically-treated or coloured hair.', 899, 549,  @SC_Haircare,@C_Beauty, N'Haircare',          N'Massage into wet hair, rinse thoroughly.', N'340 ml',N'India',  N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'beauty-conditioner-smooth-300ml', N'Smoothing Conditioner 300ml',     @B_Lakme,    N'Anti-frizz silicone-free conditioner.',              N'Lightweight cream with coconut oil and ceramides. Smooths the cuticle and tames flyaways without weighing hair down.', 799, 449,  @SC_Haircare,@C_Beauty, N'Haircare',          N'Apply to mid-lengths and ends, rinse.',   N'300 ml',N'India',  N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'beauty-hair-oil-argan-100ml', N'Pure Argan Hair Oil 100ml',            @B_Biba,     N'Cold-pressed Moroccan argan oil.',                   N'A few drops nourish ends, tame frizz, and add brilliant shine. Cold-pressed, no added fragrance.', 1499,899,  @SC_Haircare,@C_Beauty, N'Haircare',          N'Warm 2-3 drops between palms, apply.',    N'100 ml',N'Morocco',N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home');

-- BEAUTY > Fragrances
IF @SC_Fragrances IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'beauty-perfume-citrus-edp-50', N'Citrus Bloom EDP 50ml',               @B_LOreal,   N'Fresh citrus eau-de-parfum.',                        N'Top notes of bergamot and grapefruit, a heart of neroli and jasmine, base of cedarwood and white musk. 6-8 hour wear.', 3999,2499, @SC_Fragrances,@C_Beauty, N'Fragrance',         N'Store away from direct sunlight.',        N'50 ml', N'France', N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'beauty-perfume-woody-edt-100', N'Woody Amber EDT 100ml',               @B_Raymond,  N'Warm woody amber eau-de-toilette.',                  N'Smoky vetiver, leather, and amber wrapped around a clean cedar heart. A confident evening signature.', 2999,1799, @SC_Fragrances,@C_Beauty, N'Fragrance',         N'Store away from direct sunlight.',        N'100 ml',N'India',  N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'beauty-bodymist-floral-150',  N'Floral Body Mist 150ml',               @B_Lakme,    N'Lightweight all-over body mist.',                    N'Soft floral spritz with peony, pink pepper, and clean cotton. Effortless freshness for everyday.', 999, 599,  @SC_Fragrances,@C_Beauty, N'Fragrance',         N'Spray from 20cm onto skin or clothing.',  N'150 ml',N'India',  N'Return unopened within 30 days', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home');

-- WATCHES > Watches
IF @SC_Watches IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'watches-chronograph-black-leather', N'Chronograph Black Leather Strap', @B_Fastrack, N'42mm chronograph with black leather strap.',         N'Three-dial chronograph movement, scratch-resistant mineral glass, and a genuine leather strap with buckle closure. 5 ATM water resistance.', 6999,4499, @SC_Watches,@C_WatchesAccess, N'Stainless Steel & Leather', N'Wipe with soft dry cloth', N'42mm',N'India',  N'24-month manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'watches-digital-sport-grey',  N'Digital Sport Watch Grey',             @B_Adidas,   N'Multi-function digital sport watch.',                N'Backlight display, stopwatch, alarm, and dual-time function in a lightweight resin case with grey silicone strap. 10 ATM water resistance.', 3999,2499, @SC_Watches,@C_WatchesAccess, N'Resin & Silicone',         N'Rinse off sweat after use', N'44mm',N'China',  N'12-month manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'watches-classic-rose-gold',   N'Classic Rose Gold Bracelet Watch',     @B_Fastrack, N'36mm rose-gold bracelet watch.',                     N'Slim 36mm rose-gold-plated case on a five-link bracelet. Mother-of-pearl dial with subtle Roman markers. 3 ATM water resistance.', 5999,3999, @SC_Watches,@C_WatchesAccess, N'Rose-Gold-Plated Steel',    N'Wipe with soft dry cloth', N'36mm',N'India',  N'24-month manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home');

-- WATCHES > Jewellery
IF @SC_Jewellery IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'jewellery-pendant-rose-gold',    N'Rose Gold Pendant Necklace',         @B_Biba,     N'Delicate rose-gold pendant on a fine chain.',        N'Sterling silver base, 18k rose-gold plating, with a heart-cut cubic zirconia stone. 18-inch fine cable chain.', 2499,1499, @SC_Jewellery,@C_WatchesAccess, N'Sterling Silver, Rose-Gold Plated', N'Store in airtight pouch when not worn',N'18-inch',N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'jewellery-stud-earrings-pearl',  N'Freshwater Pearl Stud Earrings',     @B_W,        N'8mm freshwater pearl studs in sterling silver.',     N'Cultured freshwater pearls in a clean sterling silver four-prong setting. Hypoallergenic posts and butterfly backs.', 1999,1199, @SC_Jewellery,@C_WatchesAccess, N'Sterling Silver & Pearl', N'Wipe with soft cloth, avoid moisture', N'8 mm',  N'India',  N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'jewellery-bracelet-silver',   N'Sterling Silver Chain Bracelet',         @B_Fastrack, N'Brushed sterling silver chain bracelet.',            N'Hand-finished sterling silver curb chain with a secure lobster clasp. Brushed matte finish for everyday wear.', 2999,1799, @SC_Jewellery,@C_WatchesAccess, N'Sterling Silver',         N'Polish with silver cloth periodically', N'7.5-inch',N'India',N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home');

-- WOMEN > Clothing > Sarees
IF @SC_WSarees IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'women-saree-banarasi-silk-red',   N'Banarasi Silk Saree Red',         @B_Biba,       N'Handwoven Banarasi silk saree in classic red.',         N'Rich pure silk with intricate zari motifs along the pallu and border. Includes unstitched blouse piece.', 8999, 5499, @SC_WSarees, @C_WClothing, N'Pure Silk',         N'Dry clean only',                       N'Free Size', N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'women-saree-georgette-pastel',    N'Georgette Saree Pastel Pink',     @B_W,          N'Flowy georgette saree with sequin work.',               N'Lightweight georgette in a soft pastel-pink finish, with delicate hand-embroidered sequins across the body.', 5999, 3299, @SC_WSarees, @C_WClothing, N'Pure Georgette',    N'Dry clean only',                       N'Free Size', N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home'),
(N'women-saree-cotton-handloom',     N'Handloom Cotton Saree Indigo',    @B_Biba,       N'Breathable handloom cotton with contrast border.',      N'Earthy handloom cotton in indigo with a temple-motif contrast border. Soft hand-feel, perfect for daywear.', 3499, 1999, @SC_WSarees, @C_WClothing, N'Handloom Cotton',   N'Hand wash separately in cold water',   N'Free Size', N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'home');

-- WOMEN > Clothing > Kurtas & Kurtis
IF @SC_WKurtas IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'women-kurta-straight-mustard',    N'Straight Cotton Kurta Mustard',   @B_Biba,       N'A-line cotton kurta in mustard yellow.',                N'Soft cotton with block-print motifs along the neckline. Side slits and three-quarter sleeves for everyday wear.', 1999, 1199, @SC_WKurtas, @C_WClothing, N'100% Cotton',       N'Machine wash cold, line dry',          N'Straight Fit', N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'women-kurti-anarkali-teal',       N'Anarkali Kurti Teal',             @B_W,          N'Floor-grazing anarkali with flared hem.',               N'Pure rayon anarkali in deep teal with intricate gota-patti work on the bodice and hem.', 3499, 2199, @SC_WKurtas, @C_WClothing, N'Pure Rayon',        N'Dry clean recommended',                N'Anarkali',     N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'women-kurta-printed-white',       N'Printed Cotton Kurta White',      @B_HM,         N'White cotton kurta with floral print.',                 N'Lightweight cotton in pure white with a delicate all-over floral print and tassel ties at the neckline.', 1499, 899,  @SC_WKurtas, @C_WClothing, N'100% Cotton',       N'Machine wash gentle',                  N'Regular Fit',  N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel');

-- WOMEN > Clothing > Ethnic Wear (lehenga, sharara, etc.)
IF @SC_WEthnic IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'women-lehenga-bridal-maroon',     N'Bridal Lehenga Choli Maroon',     @B_Biba,       N'Three-piece bridal lehenga with heavy zari work.',      N'Velvet lehenga in deep maroon with intricate zari and stone work. Includes matching blouse and dupatta.', 24999, 17999, @SC_WEthnic, @C_WClothing, N'Velvet + Silk Blend', N'Dry clean only',                     N'Tailored Fit', N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 5-7 business days.', N'apparel'),
(N'women-sharara-set-mint',          N'Sharara Set Mint Green',          @B_W,          N'Three-piece sharara set in mint green.',                N'Flowy georgette sharara with a short kurta and matching organza dupatta. Subtle sequin scatter throughout.', 5999, 3499, @SC_WEthnic, @C_WClothing, N'Pure Georgette',    N'Dry clean only',                       N'Regular Fit',  N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel'),
(N'women-palazzo-set-coral',         N'Palazzo Set Coral Pink',          @B_Biba,       N'Kurti with palazzo and dupatta.',                       N'Three-piece set: kurti, wide-leg palazzo, and matching dupatta. Soft cotton-rayon blend with thread embroidery.', 3499, 1899, @SC_WEthnic, @C_WClothing, N'Cotton-Rayon Blend',N'Machine wash cold, gentle cycle',      N'Regular Fit',  N'India', N'30-day quality guarantee', N'Free shipping above ₹999. Ships in 1-2 business days.', N'apparel');

-- WOMEN > Footwear > All Shoes
IF @SC_WShoes IS NOT NULL
INSERT INTO @ProductDefs (Slug,Name,BrandId,ShortDesc,LongDesc,MRP,Selling,SubCategoryId,CategoryId,Material,Care,FitType,CountryOfOrigin,WarrantyInfo,DeliveryInfo,SizeKind) VALUES
(N'women-heels-block-nude',          N'Block Heel Sandals Nude',         @B_HM,          N'2-inch block heel sandals in nude.',                    N'Comfortable 2-inch block heel with adjustable ankle strap. Padded footbed for all-day wear.', 2999, 1799, @SC_WShoes, @C_WFootwear, N'Faux Leather',     N'Wipe clean with damp cloth',            N'True to size', N'India',   N'30-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear'),
(N'women-flats-ballet-rosegold',     N'Ballet Flats Rose Gold',          @B_Zara,        N'Slip-on ballet flats with metallic finish.',            N'Soft faux-leather ballet flats with a subtle rose-gold shimmer. Cushioned insole, flexible rubber outsole.', 2499, 1399, @SC_WShoes, @C_WFootwear, N'Faux Leather',     N'Wipe clean with damp cloth',            N'True to size', N'India',   N'30-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear'),
(N'women-sneakers-white-pink',       N'Lifestyle Sneakers White Pink',   @B_Adidas,      N'Low-top lifestyle sneakers in white with pink trim.',   N'Breathable mesh and faux-leather upper, EVA midsole for everyday cushioning, gum rubber outsole.', 4999, 3299, @SC_WShoes, @C_WFootwear, N'Mesh & Synthetic', N'Spot clean with mild detergent',        N'True to size', N'Vietnam', N'90-day manufacturer warranty', N'Free shipping above ₹999. Ships in 1-2 business days.', N'footwear');

-- ── Loop: insert each product + children if not already present ─────────────
DECLARE @max INT = (SELECT MAX(Idx) FROM @ProductDefs);
DECLARE @i   INT = 1;

DECLARE @cur_slug NVARCHAR(300), @cur_name NVARCHAR(300), @cur_brand INT,
        @cur_short NVARCHAR(500), @cur_long NVARCHAR(MAX),
        @cur_mrp DECIMAL(18,2), @cur_sell DECIMAL(18,2),
        @cur_subcat INT, @cur_cat INT,
        @cur_material NVARCHAR(200), @cur_care NVARCHAR(500),
        @cur_fit NVARCHAR(50), @cur_country NVARCHAR(100),
        @cur_warranty NVARCHAR(500), @cur_delivery NVARCHAR(500),
        @cur_sizekind NVARCHAR(20);

WHILE @i <= ISNULL(@max, 0)
BEGIN
    SELECT
        @cur_slug = Slug, @cur_name = Name, @cur_brand = BrandId,
        @cur_short = ShortDesc, @cur_long = LongDesc,
        @cur_mrp = MRP, @cur_sell = Selling,
        @cur_subcat = SubCategoryId, @cur_cat = CategoryId,
        @cur_material = Material, @cur_care = Care, @cur_fit = FitType,
        @cur_country = CountryOfOrigin, @cur_warranty = WarrantyInfo, @cur_delivery = DeliveryInfo,
        @cur_sizekind = SizeKind
    FROM @ProductDefs WHERE Idx = @i;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE SlugUrl = @cur_slug AND IsDeleted = 0)
    BEGIN
        INSERT INTO Products
            (SellerId, BrandId, CategoryId, SubCategoryId, ProductName, SlugUrl,
             ShortDescription, LongDescription, MRP, SellingPrice, Sku,
             ApprovalStatus, IsActive, IsDeleted, CreatedBy,
             Material, CareInstructions, FitType, CountryOfOrigin, WarrantyInfo, DeliveryInfo)
        VALUES
            (@SellerId, @cur_brand, @cur_cat, @cur_subcat, @cur_name, @cur_slug,
             @cur_short, @cur_long, @cur_mrp, @cur_sell,
             N'FC-' + UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''), 8)),
             2, 1, 0, @AdminId,
             @cur_material, @cur_care, @cur_fit, @cur_country, @cur_warranty, @cur_delivery);

        DECLARE @newPid INT = SCOPE_IDENTITY();
        DECLARE @skuBase NVARCHAR(50) = N'V' + RIGHT(N'000000' + CAST(@newPid AS NVARCHAR(10)), 6);

        -- Two images, rotated through the shared pool
        INSERT INTO ProductImages (ProductId, ImageUrl, AltText, SortOrder, IsPrimary, IsDeleted)
        VALUES
            (@newPid, (SELECT Url FROM @IMGS WHERE Idx = (@i * 2)     % @ImgCount), @cur_name + N' - main',      0, 1, 0),
            (@newPid, (SELECT Url FROM @IMGS WHERE Idx = (@i * 2 + 1) % @ImgCount), @cur_name + N' - alternate', 1, 0, 0);

        -- Variants by SizeKind
        IF @cur_sizekind = N'apparel'
        BEGIN
            -- 2 colors x 3 sizes = 6 variants
            INSERT INTO ProductVariants (ProductId, Color, ColorHexCode, Size, VariantSku, AdditionalPrice, StockQuantity, LowStockThreshold, IsActive, IsDeleted)
            VALUES
                (@newPid, N'Black', N'#000000', N'S', @skuBase + N'-BK-S', 0, 30 + (@i % 20), 5, 1, 0),
                (@newPid, N'Black', N'#000000', N'M', @skuBase + N'-BK-M', 0, 30 + (@i % 20), 5, 1, 0),
                (@newPid, N'Black', N'#000000', N'L', @skuBase + N'-BK-L', 0, 30 + (@i % 20), 5, 1, 0),
                (@newPid, N'Navy',  N'#1E3A8A', N'S', @skuBase + N'-NV-S', 0, 30 + (@i % 20), 5, 1, 0),
                (@newPid, N'Navy',  N'#1E3A8A', N'M', @skuBase + N'-NV-M', 0, 30 + (@i % 20), 5, 1, 0),
                (@newPid, N'Navy',  N'#1E3A8A', N'L', @skuBase + N'-NV-L', 0, 30 + (@i % 20), 5, 1, 0);
        END
        ELSE IF @cur_sizekind = N'footwear'
        BEGIN
            -- 1 color x 4 sizes (UK 8-11)
            INSERT INTO ProductVariants (ProductId, Color, ColorHexCode, Size, VariantSku, AdditionalPrice, StockQuantity, LowStockThreshold, IsActive, IsDeleted)
            VALUES
                (@newPid, N'Default', NULL, N'8',  @skuBase + N'-DF-8',  0, 20 + (@i % 20), 5, 1, 0),
                (@newPid, N'Default', NULL, N'9',  @skuBase + N'-DF-9',  0, 20 + (@i % 20), 5, 1, 0),
                (@newPid, N'Default', NULL, N'10', @skuBase + N'-DF-10', 0, 20 + (@i % 20), 5, 1, 0),
                (@newPid, N'Default', NULL, N'11', @skuBase + N'-DF-11', 0, 20 + (@i % 20), 5, 1, 0);
        END
        ELSE
        BEGIN
            -- home / beauty / accessory — 2 colors, no apparel size
            INSERT INTO ProductVariants (ProductId, Color, ColorHexCode, Size, VariantSku, AdditionalPrice, StockQuantity, LowStockThreshold, IsActive, IsDeleted)
            VALUES
                (@newPid, N'Default', NULL, NULL, @skuBase + N'-DF', 0, 40 + (@i % 20), 5, 1, 0),
                (@newPid, N'Variant', NULL, NULL, @skuBase + N'-V2', 0, 40 + (@i % 20), 5, 1, 0);
        END

        -- 5 specifications
        INSERT INTO ProductSpecifications (ProductId, SpecKey, SpecValue, SortOrder, IsDeleted)
        VALUES
            (@newPid, N'Material',          @cur_material, 1, 0),
            (@newPid, N'Care Instructions', @cur_care,     2, 0),
            (@newPid, N'Country of Origin', @cur_country,  3, 0),
            (@newPid, N'Fit / Type',        @cur_fit,      4, 0),
            (@newPid, N'Warranty',          @cur_warranty, 5, 0);
    END

    SET @i = @i + 1;
END

PRINT N'Seed_FullCatalog.sql complete.';
