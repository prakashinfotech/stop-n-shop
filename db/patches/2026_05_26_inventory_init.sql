/*
 * 2026-05-26 — Inventory init patch
 *
 * Purpose:
 *   Seeds the 3 platform warehouses (Mumbai / Bengaluru / Delhi) and creates
 *   an initial Stock(VariantId, WarehouseId=Mumbai DC, OnHand=StockQuantity)
 *   row for every existing ProductVariant. Without this, the seller inventory
 *   page shows zero stock rows even though variants exist.
 *
 * Safety:
 *   - Warehouses: MERGE keyed on Code — re-runnable, no duplicates.
 *   - Stock: INSERT ... SELECT with NOT EXISTS guard — only adds rows for
 *     variants that don't yet have a Stock entry in the default warehouse.
 *     Existing Stock rows (any warehouse) are never modified.
 *   - Uses the variant's own ProductVariants.StockQuantity as OnHand, so the
 *     seeded quantities mirror what the seller already entered.
 *
 * How to apply:
 *   docker cp db/patches/2026_05_26_inventory_init.sql stopnshop-db:/tmp/patch.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C \
 *     -d ShopNShop_db -b -I -i /tmp/patch.sql
 */

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '[patch] Starting 2026-05-26 inventory init...';

------------------------------------------------------------------------------
-- 1. Seed platform warehouses (SellerId = NULL means platform-owned)
------------------------------------------------------------------------------
PRINT '[patch] Warehouses: seeding 3 platform DCs...';

DECLARE @wh_before INT = (SELECT COUNT(*) FROM [dbo].[Warehouses]);

MERGE [dbo].[Warehouses] AS tgt
USING (VALUES
    (N'WH-MUM-01', N'Mumbai DC',     NULL, N'Andheri Industrial Estate', N'MIDC', N'Mumbai',    N'Maharashtra', N'400093', N'India'),
    (N'WH-BLR-01', N'Bengaluru DC',  NULL, N'Whitefield Logistics Park', NULL,    N'Bengaluru', N'Karnataka',   N'560066', N'India'),
    (N'WH-DEL-01', N'Delhi NCR DC',  NULL, N'Bilaspur Industrial Area',  NULL,    N'Gurugram',  N'Haryana',     N'122413', N'India')
) AS src ([Code], [Name], [SellerId], [AddressLine1], [AddressLine2], [City], [State], [PinCode], [Country])
ON tgt.[Code] = src.[Code]
WHEN MATCHED THEN UPDATE SET
    tgt.[Name]         = src.[Name],
    tgt.[AddressLine1] = src.[AddressLine1],
    tgt.[AddressLine2] = src.[AddressLine2],
    tgt.[City]         = src.[City],
    tgt.[State]        = src.[State],
    tgt.[PinCode]      = src.[PinCode],
    tgt.[Country]      = src.[Country],
    tgt.[UpdatedAt]    = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT
    ([Code], [Name], [SellerId], [AddressLine1], [AddressLine2], [City], [State], [PinCode], [Country])
VALUES
    (src.[Code], src.[Name], src.[SellerId], src.[AddressLine1], src.[AddressLine2],
     src.[City], src.[State], src.[PinCode], src.[Country]);

DECLARE @wh_after INT = (SELECT COUNT(*) FROM [dbo].[Warehouses]);
PRINT CONCAT('[patch] Warehouses: was ', @wh_before, ', now ', @wh_after);

------------------------------------------------------------------------------
-- 2. Initial Stock per Variant (skip variants that already have any Stock)
------------------------------------------------------------------------------
PRINT '[patch] Stock: creating initial rows for variants with no stock yet...';

DECLARE @default_wh INT = (
    SELECT TOP 1 [WarehouseId]
    FROM [dbo].[Warehouses]
    WHERE [Code] = N'WH-MUM-01' AND [IsDeleted] = 0
);

IF @default_wh IS NULL
BEGIN
    RAISERROR(N'[patch] Default warehouse WH-MUM-01 not found — aborting.', 16, 1);
    RETURN;
END

DECLARE @stock_before INT = (SELECT COUNT(*) FROM [dbo].[Stock]);

INSERT INTO [dbo].[Stock] ([VariantId], [WarehouseId], [OnHand], [Reserved])
SELECT
    pv.[VariantId],
    @default_wh,
    ISNULL(pv.[StockQuantity], 0),
    0
FROM [dbo].[ProductVariants] pv
WHERE pv.[IsDeleted] = 0
  AND pv.[IsActive]  = 1
  AND NOT EXISTS (
      SELECT 1
      FROM [dbo].[Stock] s
      WHERE s.[VariantId] = pv.[VariantId]
  );

DECLARE @stock_after INT = (SELECT COUNT(*) FROM [dbo].[Stock]);
PRINT CONCAT('[patch] Stock rows: was ', @stock_before, ', now ', @stock_after,
             ' (variants with existing stock preserved)');

PRINT '[patch] Done.';
GO
