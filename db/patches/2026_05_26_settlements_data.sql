/*
 * 2026-05-26 — Demo settlement data patch
 *
 * Purpose:
 *   - Seed the Demo Seller (SellerId=1) with one primary bank account.
 *   - Insert 5 delivered + paid orders attributable to that seller's products,
 *     spread across the settlement-eligible window (today - 30 .. today - 7),
 *     so SellerSettlements can be calculated and the Dashboard revenue card
 *     has a number to display.
 *   - Run usp_Seller_Settlement_Calculate to materialise the SellerSettlement
 *     row + its line items.
 *
 * Safety:
 *   - Bank account: skipped if the seller already has any bank account.
 *   - Orders: keyed on OrderNumber 'DEMO-S1-NNN'. Re-running this patch is a
 *     no-op (existing rows preserved).
 *   - Settlement: Calculate SP itself is idempotent (UNIQUE on (SellerId,
 *     PeriodStart, PeriodEnd) — second run returns the existing settlement).
 *
 * Apply:
 *   docker cp db/patches/2026_05_26_settlements_data.sql stopnshop-db:/tmp/sd.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C -d ShopNShop_db -b -I -i /tmp/sd.sql
 */

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @SellerId      INT = 1;
DECLARE @BuyerUserId   INT = 3;   -- dolly.km08@yopmail.com
DECLARE @BuyerAddrId   INT = 1;   -- Ahmedabad
DECLARE @AdminUserId   INT = 1;

PRINT '[patch] Starting settlements demo data...';

------------------------------------------------------------------------------
-- 1. Seed primary bank account (only if seller has none)
------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM [dbo].[SellerBankAccounts]
    WHERE [SellerId] = @SellerId AND [IsDeleted] = 0
)
BEGIN
    INSERT INTO [dbo].[SellerBankAccounts]
        ([SellerId], [AccountHolderName], [BankName], [AccountNumber], [IfscCode],
         [BranchName], [IsPrimary], [IsVerified], [VerifiedAt], [VerifiedBy], [CreatedBy], [UpdatedBy])
    VALUES
        (@SellerId, N'Demo Seller Store', N'HDFC Bank', N'50100123456789', N'HDFC0000123',
         N'Andheri West', 1, 1, GETUTCDATE(), @AdminUserId, @AdminUserId, @AdminUserId);

    PRINT '[patch] Bank account: created HDFC Bank primary account.';
END
ELSE
BEGIN
    PRINT '[patch] Bank account: seller already has accounts on file — skipping.';
END

------------------------------------------------------------------------------
-- 2. Insert 5 demo orders (idempotent on OrderNumber)
------------------------------------------------------------------------------
-- Pull 5 of the seller's active variants up front so the inserts can reference them.
DECLARE @v1 INT, @v2 INT, @v3 INT, @v4 INT, @v5 INT;
DECLARE @p1 INT, @p2 INT, @p3 INT, @p4 INT, @p5 INT;
DECLARE @b1 INT, @b2 INT, @b3 INT, @b4 INT, @b5 INT;
DECLARE @pr1 DECIMAL(18,2), @pr2 DECIMAL(18,2), @pr3 DECIMAL(18,2), @pr4 DECIMAL(18,2), @pr5 DECIMAL(18,2);
DECLARE @n1 NVARCHAR(300), @n2 NVARCHAR(300), @n3 NVARCHAR(300), @n4 NVARCHAR(300), @n5 NVARCHAR(300);

;WITH Picks AS (
    SELECT TOP 5
        p.ProductId, p.ProductName, p.SellingPrice, p.BrandId, pv.VariantId,
        ROW_NUMBER() OVER (ORDER BY p.ProductId) AS rn
    FROM [dbo].[Products] p
    JOIN [dbo].[ProductVariants] pv ON pv.ProductId = p.ProductId
    WHERE p.SellerId = @SellerId AND p.IsDeleted = 0 AND pv.IsDeleted = 0
    ORDER BY p.ProductId
)
SELECT
    @p1 = MAX(CASE WHEN rn = 1 THEN ProductId    END),
    @p2 = MAX(CASE WHEN rn = 2 THEN ProductId    END),
    @p3 = MAX(CASE WHEN rn = 3 THEN ProductId    END),
    @p4 = MAX(CASE WHEN rn = 4 THEN ProductId    END),
    @p5 = MAX(CASE WHEN rn = 5 THEN ProductId    END),
    @v1 = MAX(CASE WHEN rn = 1 THEN VariantId    END),
    @v2 = MAX(CASE WHEN rn = 2 THEN VariantId    END),
    @v3 = MAX(CASE WHEN rn = 3 THEN VariantId    END),
    @v4 = MAX(CASE WHEN rn = 4 THEN VariantId    END),
    @v5 = MAX(CASE WHEN rn = 5 THEN VariantId    END),
    @b1 = MAX(CASE WHEN rn = 1 THEN BrandId      END),
    @b2 = MAX(CASE WHEN rn = 2 THEN BrandId      END),
    @b3 = MAX(CASE WHEN rn = 3 THEN BrandId      END),
    @b4 = MAX(CASE WHEN rn = 4 THEN BrandId      END),
    @b5 = MAX(CASE WHEN rn = 5 THEN BrandId      END),
    @pr1 = MAX(CASE WHEN rn = 1 THEN SellingPrice END),
    @pr2 = MAX(CASE WHEN rn = 2 THEN SellingPrice END),
    @pr3 = MAX(CASE WHEN rn = 3 THEN SellingPrice END),
    @pr4 = MAX(CASE WHEN rn = 4 THEN SellingPrice END),
    @pr5 = MAX(CASE WHEN rn = 5 THEN SellingPrice END),
    @n1 = MAX(CASE WHEN rn = 1 THEN ProductName  END),
    @n2 = MAX(CASE WHEN rn = 2 THEN ProductName  END),
    @n3 = MAX(CASE WHEN rn = 3 THEN ProductName  END),
    @n4 = MAX(CASE WHEN rn = 4 THEN ProductName  END),
    @n5 = MAX(CASE WHEN rn = 5 THEN ProductName  END)
FROM Picks;

IF @p1 IS NULL
BEGIN
    RAISERROR(N'[patch] Seller has no active products — cannot create demo orders.', 16, 1);
    RETURN;
END

DECLARE @order_inserts INT = 0;

-- Helper pattern: for each demo order, insert Order header + OrderItem if the
-- OrderNumber doesn't yet exist. Quantities + dates spread across the period.
DECLARE @orders TABLE (
    OrderNumber NVARCHAR(50),
    ProductId   INT,
    VariantId   INT,
    BrandId     INT,
    UnitPrice   DECIMAL(18,2),
    Quantity    INT,
    ProductName NVARCHAR(300),
    CreatedDays INT,           -- days ago order was created
    DeliveredDays INT          -- days ago order was delivered
);

INSERT INTO @orders VALUES
    (N'DEMO-S1-001', @p1, @v1, @b1, @pr1, 2, @n1, 25, 22),
    (N'DEMO-S1-002', @p2, @v2, @b2, @pr2, 1, @n2, 21, 18),
    (N'DEMO-S1-003', @p3, @v3, @b3, @pr3, 1, @n3, 18, 14),
    (N'DEMO-S1-004', @p4, @v4, @b4, @pr4, 1, @n4, 14, 11),
    (N'DEMO-S1-005', @p5, @v5, @b5, @pr5, 2, @n5, 12,  9);

DECLARE @on NVARCHAR(50), @pid INT, @vid INT, @bid INT, @price DECIMAL(18,2), @qty INT, @pname NVARCHAR(300);
DECLARE @createdDays INT, @deliveredDays INT;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT OrderNumber, ProductId, VariantId, BrandId, UnitPrice, Quantity, ProductName, CreatedDays, DeliveredDays
    FROM @orders;

OPEN cur;
FETCH NEXT FROM cur INTO @on, @pid, @vid, @bid, @price, @qty, @pname, @createdDays, @deliveredDays;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Orders] WHERE [OrderNumber] = @on)
    BEGIN
        DECLARE @lineTotal DECIMAL(18,2) = @price * @qty;
        DECLARE @createdAt DATETIME2(0) = DATEADD(DAY, -@createdDays,   GETUTCDATE());
        DECLARE @deliveredAt DATETIME2(0) = DATEADD(DAY, -@deliveredDays, GETUTCDATE());

        INSERT INTO [dbo].[Orders]
            ([UserId], [OrderNumber], [OrderStatus], [SubTotal], [DiscountAmount], [CouponDiscount],
             [TaxAmount], [ShippingCharge], [TotalAmount], [ShippingAddressId], [PaymentMode],
             [PaymentStatus], [PaymentGatewayRef], [DeliveredAt], [CreatedAt], [UpdatedAt], [CreatedBy])
        VALUES
            (@BuyerUserId, @on, 5, @lineTotal, 0, 0,
             0, 0, @lineTotal, @BuyerAddrId, 2,
             2, CONCAT(N'DEMO-PG-', @on), @deliveredAt, @createdAt, @deliveredAt, @AdminUserId);

        DECLARE @oid INT = SCOPE_IDENTITY();

        INSERT INTO [dbo].[OrderItems]
            ([OrderId], [ProductId], [VariantId], [SellerId], [BrandId], [ProductName],
             [Quantity], [UnitPrice], [DiscountAmount], [TaxAmount], [TotalPrice],
             [OrderStatus], [ConfirmedAt], [CreatedAt], [UpdatedAt], [CreatedBy])
        VALUES
            (@oid, @pid, @vid, @SellerId, @bid, @pname,
             @qty, @price, 0, 0, @lineTotal,
             5, @createdAt, @createdAt, @deliveredAt, @AdminUserId);

        SET @order_inserts += 1;
    END

    FETCH NEXT FROM cur INTO @on, @pid, @vid, @bid, @price, @qty, @pname, @createdDays, @deliveredDays;
END
CLOSE cur;
DEALLOCATE cur;

PRINT CONCAT('[patch] Orders inserted: ', @order_inserts, ' (existing demo orders preserved).');

------------------------------------------------------------------------------
-- 3. Run settlement calculation for the eligible window (today-30 .. today-7)
------------------------------------------------------------------------------
DECLARE @periodStart DATE = DATEADD(DAY, -30, CAST(GETUTCDATE() AS DATE));
DECLARE @periodEnd   DATE = DATEADD(DAY,  -7, CAST(GETUTCDATE() AS DATE));

-- Skip if a settlement already covers this window (unique constraint would
-- block the insert anyway; this just gives a cleaner log line).
IF NOT EXISTS (
    SELECT 1 FROM [dbo].[SellerSettlements]
    WHERE [SellerId] = @SellerId AND [PeriodStart] = @periodStart AND [PeriodEnd] = @periodEnd
)
BEGIN
    PRINT CONCAT('[patch] Running Settlement_Calculate for ', @periodStart, ' .. ', @periodEnd, '...');
    EXEC [dbo].[usp_Seller_Settlement_Calculate]
         @SellerId     = @SellerId,
         @PeriodStart  = @periodStart,
         @PeriodEnd    = @periodEnd,
         @CalculatedBy = @AdminUserId;
END
ELSE
BEGIN
    PRINT '[patch] Settlement for this window already exists — skipping.';
END

PRINT '[patch] Done.';
GO
