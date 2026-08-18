# Inventory Model

> Phase 2 deliverable. Companion to [api/ARCHITECTURE.md](../api/ARCHITECTURE.md) and [ShopNStopDB/ARCHITECTURE.md](../ShopNStopDB/ARCHITECTURE.md).

## Why a new model

`ProductVariants.StockQuantity` is a flat counter — single number, single tier. It cannot model:

- multiple warehouses / 3PL locations,
- soft holds while a buyer is checking out,
- a write-once history of stock movements for audit,
- concurrent order placement without overselling.

Phase 2 introduces a five-table warehouse-aware ledger. The legacy `ProductVariants.StockQuantity` is kept as a denormalized cache (sum of `Stock.OnHand` across warehouses for that variant) so existing read paths keep working with no schema break.

## Tables

| Table | Role |
|---|---|
| `Warehouses` | Physical or virtual stock locations. `SellerId IS NULL` ⇒ platform/1P warehouse. |
| `Stock` | One row per `(VariantId, WarehouseId)`. Holds `OnHand`, `Reserved`, and a `ROWVERSION` for optimistic concurrency. Source of truth. |
| `StockReservations` | Soft holds placed during checkout with `ExpiresAt`. Status: 1 Active, 2 Committed (became an order), 3 Released, 4 Expired. |
| `StockMovements` | Append-only ledger. Every change to `Stock.OnHand` or `Stock.Reserved` writes one row. |
| `StockTransfers` | Two-step movement between warehouses (InTransit → Received → Cancelled). |

### Invariants enforced at DB level

- `Stock.OnHand >= 0`
- `Stock.Reserved >= 0`
- `Stock.Reserved <= Stock.OnHand`
- `Stock` UNIQUE on `(VariantId, WarehouseId)`
- `StockTransfers.FromWarehouseId <> ToWarehouseId`

## Available = OnHand − Reserved

The number we sell on `/products/:id` is **`SUM(OnHand - Reserved)` across active warehouses**. Reservations protect a buyer who's mid-checkout from being undercut by a faster buyer.

## Concurrency strategy

Every mutation of `Stock` is wrapped in:

```sql
BEGIN TRANSACTION;
SELECT … FROM dbo.Stock WITH (UPDLOCK, HOLDLOCK)
WHERE VariantId = @v AND WarehouseId = @wh;
-- decide
UPDATE dbo.Stock SET … WHERE …;
COMMIT;
```

`UPDLOCK` upgrades the read to an update lock; `HOLDLOCK` (serializable) prevents another transaction from inserting a phantom or reading the row until commit. This is the standard SQL Server pattern for "read-modify-write under contention" and gives us oversell safety on the `(VariantId, WarehouseId)` row without a global table lock.

The `ROWVERSION` column on `Stock` is reserved for future optimistic-concurrency paths (e.g. bulk seller imports) that prefer a retry-on-conflict loop over a pessimistic lock.

## Movement types (`StockMovements.MovementType`)

| Code | Verb | Quantity effect | Reserved effect |
|---|---|---|---|
| 1 | Receipt    | +OnHand     | 0 |
| 2 | Adjustment | ± OnHand    | 0 |
| 3 | Reserve    | 0           | +Reserved |
| 4 | Release    | 0           | −Reserved |
| 5 | Ship (commit) | −OnHand  | −Reserved |
| 6 | Return     | +OnHand     | 0 |
| 7 | TransferOut | −OnHand    | 0 |
| 8 | TransferIn  | +OnHand    | 0 |

The ledger never updates — only inserts. Reconciliation: `SUM(QuantityDelta) per (VariantId, WarehouseId)` from `StockMovements` must equal `Stock.OnHand`.

## Reservation lifecycle

```
Buyer adds to cart            → soft check (read-only)
Buyer starts checkout         → POST /api/inventory/stock/reserve     (TTL 15 min)
   Stock.Reserved += qty
   StockReservations row inserted, Status=1 Active
Buyer pays / order placed     → POST /api/inventory/stock/release with commitToOrderId
   Stock.OnHand   -= qty
   Stock.Reserved -= qty
   StockReservations Status → 2 Committed, OrderId set
Buyer abandons cart           → POST /api/inventory/stock/release
   Stock.Reserved -= qty
   StockReservations Status → 3 Released
TTL elapses                   → ReservationExpiryWorker (every 60s)
   usp_Inventory_Reservation_ExpireDue runs
   StockReservations Status → 4 Expired, Stock.Reserved decremented
```

`ReservationExpiryWorker` is an `IHostedService` registered in `api/Program.cs`. It uses `READPAST, UPDLOCK` and a batch size of 200 so concurrent reservation creates aren't blocked.

## Transfer lifecycle

```
Admin initiates transfer      → POST /api/inventory/transfers
   FromWarehouse.OnHand -= qty
   StockTransfers row inserted, Status=1 InTransit
Destination warehouse receives→ PATCH /api/inventory/transfers/{id}/receive
   ToWarehouse.OnHand += qty
   StockTransfers Status → 2 Received
```

Each leg emits its own `StockMovements` row (type 7 then 8), so the ledger always reconciles.

## Audit hook

`InventoryService` wraps every mutating call with `IInventoryRepository.WriteAuditAsync`, writing to the existing `AuditLogs` table with:

- `TableName` = the affected table (`Stock`, `StockReservations`, `StockTransfers`)
- `Action` = `UPDATE` (the table is `CHECK`-constrained to INSERT/UPDATE/DELETE)
- `NewValues` = `{"verb":"ADJUST_STOCK","data":{…request…}}`
- `ChangedBy` = JWT user id
- `IpAddress` = `HttpContext.Connection.RemoteIpAddress`

Audit reads are not yet wired in this phase — they reuse the admin audit-query SP added in Phase 1 once that lands on `main`.

## API surface

Documented in [api/Controllers/InventoryController.cs](../api/Controllers/InventoryController.cs); the OpenAPI doc is generated by Swashbuckle from XML comments.

| Method | Route | Roles | Purpose |
|---|---|---|---|
| GET    | `/api/inventory/warehouses`                       | Admin, Seller | List warehouses |
| GET    | `/api/inventory/variants/{id}/stock`              | Admin, Seller | Per-variant stock across warehouses |
| GET    | `/api/inventory/matrix`                           | Admin         | SKU × warehouse matrix |
| GET    | `/api/inventory/low-stock`                        | Admin, Seller | Low-stock alert feed |
| GET    | `/api/inventory/variants/{id}/movements`          | Admin, Seller | Movement history |
| POST   | `/api/inventory/stock/adjust`                     | Admin, Seller | Manual adjustment |
| POST   | `/api/inventory/stock/reserve`                    | Admin, Seller, Buyer | Place TTL hold |
| POST   | `/api/inventory/stock/release`                    | Admin, Seller, Buyer | Release or commit hold |
| POST   | `/api/inventory/transfers`                        | Admin         | Initiate transfer |
| PATCH  | `/api/inventory/transfers/{id}/receive`           | Admin         | Receive transfer |

## Stored procedure index

| SP | Purpose |
|---|---|
| `usp_Inventory_Warehouse_GetAll`              | List warehouses (admin: all, seller: own + platform) |
| `usp_Inventory_Stock_GetByVariant`            | All warehouse rows for a variant |
| `usp_Inventory_Stock_Adjust`                  | Apply signed delta + ledger entry |
| `usp_Inventory_Stock_Reserve`                 | Place hold, increment Reserved, log movement |
| `usp_Inventory_Stock_ReleaseReservation`      | Release or commit (decrement OnHand) |
| `usp_Inventory_Movement_Log`                  | Direct ledger write (opening balances, imports) |
| `usp_Inventory_Movement_GetByVariant`         | Paged movement history |
| `usp_Inventory_LowStock_Alerts`               | Variants with Available ≤ LowStockThreshold |
| `usp_Inventory_Transfer_Initiate`             | Decrement source, mark InTransit |
| `usp_Inventory_Transfer_Receive`              | Credit destination, mark Received |
| `usp_Inventory_StockMatrix_Get`               | Paged SKU × warehouse matrix |
| `usp_Inventory_Reservation_ExpireDue`         | Worker hook — sweep TTL-expired holds |

## SQL error codes

| Code | Meaning |
|---|---|
| 50300 | QuantityDelta must be non-zero |
| 50301 | Variant not found |
| 50302 | Warehouse not found |
| 50303 | Adjustment would drive OnHand negative |
| 50304 | Adjustment would drop OnHand below current Reserved |
| 50310 | Reserve quantity must be positive |
| 50311 | Reserve TtlMinutes must be positive |
| 50312 | No stock record exists for variant/warehouse |
| 50313 | Insufficient available stock to reserve |
| 50320 | Reservation not found |
| 50330 | Transfer quantity must be positive |
| 50331 | Transfer warehouses must differ |
| 50332 | Source warehouse has no stock for variant |
| 50333 | Insufficient available stock at source |
| 50340 | Transfer not found |
| 50341 | Transfer is not in transit |

## What is NOT in Phase 2

- Bulk CSV upload from seller inventory page → deferred to Phase 3 (seller module).
- Multi-warehouse picking strategy (closest warehouse, split shipment) → deferred.
- Cart/checkout integration to actually call `/stock/reserve` during real flows → wiring tracked in Phase 3 (commerce uses the new SPs).
- Concurrency soak test under 50 parallel order placements → Phase 5 test pass.
