# Seller Handbook

> Operational reference for sellers on the StopNShop platform.
> Source of truth for onboarding stages, SLA targets, commission, and
> settlement timing. Pairs with `api/Controllers/SellerLifecycleController.cs`
> for the wire contract and `ShopNStopDB/dbo/StoredProcedures/usp_Seller_*`
> for the schema of record.

## Onboarding stages

The wizard advances through six stages, each persisted via
`POST /api/seller/onboarding/stage` (`stage` string):

| Order | Stage         | What gets captured                                                | Persists into                                  |
|------:|---------------|-------------------------------------------------------------------|------------------------------------------------|
| 1     | `business`    | Business name, GST, PAN, owner name, display name                 | `Sellers`                                      |
| 2     | `bank`        | First settlement bank account (becomes primary if it's the only)  | `SellerBankAccounts`                           |
| 3     | `pickup`      | Primary pickup warehouse address                                  | `SellerWarehouses`                             |
| 4     | `documents`   | GST cert, PAN, FSSAI/other (one row per doc, verified by admin)   | `SellerDocuments`                              |
| 5     | `agreement`   | Vendor agreement acceptance (version, IP, UA)                     | `VendorAgreements`                             |
| 6     | `complete`    | Marks `Sellers.OnboardingCompleted = 1`                           | `Sellers`                                      |

Admin then moves `ApprovalStatus` 1 → 2 (Pending → Approved). Sellers
cannot list products until both `OnboardingCompleted = 1` and
`ApprovalStatus = 2`.

## SLA targets

Defaults seeded into `SellerSLAs` (per-seller overrides allowed by admin):

| Metric                    | Default | Notes                                                       |
|---------------------------|--------:|-------------------------------------------------------------|
| Dispatch SLA              |    24 h | From order-confirmed to AWB created                         |
| Delivery SLA              |   5 d   | From dispatch to delivered                                  |
| Refund SLA                |   7 d   | From return-received to refund-initiated                    |
| Cancellation cap          |   5 %   | Rolling 30-day; over this triggers warning                  |
| Return cap                |  10 %   | Rolling 30-day                                              |

Breaches enter the seller's performance score (see below) and may
trigger penalties on settlement.

## Commission and TDS

Commission and TDS rates come from `CommissionPlans`. Lookup order
during settlement:

1. `OrderItems.CommissionAmount` (already-computed snapshot from order placement)
2. Else: default plan (`IsDefault = 1`) × line gross
3. TDS is applied on commission (default 1%)

Three default plans are seeded:

| Plan                  | Category | Rate   | TDS |
|-----------------------|----------|-------:|----:|
| Default Platform Fee  | all      |  10%   |  1% |
| Apparel — Standard    | all      |   8%   |  1% |
| Footwear — Standard   | all      |  12%   |  1% |

Per-line math (kept pure in `SellerLifecycleService.ComputeLineMath` for
testability):

```
gross       = OrderItems.TotalPrice
commission  = COALESCE(OrderItems.CommissionAmount, gross × default_rate)
tds         = commission × tds_rate
penalty     = 0 (SLA-miss hook)
net         = gross − commission − tds − penalty
```

## Settlement timing — T+7

`SellerSettlementWorker` runs every 24 h. Each pass:

1. Asks `usp_Seller_Settlement_DueSellers` for sellers with at least one
   delivered order-item whose `DeliveredAt ≤ today − 7 days` and which
   hasn't been settled.
2. For each, calls `usp_Seller_Settlement_Calculate` with
   `PeriodStart = today − 13`, `PeriodEnd = today − 7`. The SP snapshots
   eligible lines into a temp table, sums into a `SellerSettlements`
   header, and writes one `SellerSettlementLines` row per order-item.
3. Status starts at `1 = Pending`. Ops moves it to `2 = Paid` after the
   bank transfer is reconciled and records the `UtrNumber`.

`SellerLifecycleService.CalculateSettlementAsync` enforces the same
T+7 guard before calling the SP, so manual admin triggers can't settle
items still in the return window.

## Performance score

`SellerScoreWorker` runs every 24 h, computing one
`SellerPerformanceScores` row per active seller per day. Snapshot is
rolling 30 days of order activity.

Composite (0–100):

```
composite = 0.40 × on_time_dispatch_pct
          + 0.20 × (100 − cancellation_pct)
          + 0.20 × (100 − return_pct)
          + 0.20 × (avg_rating × 20)
```

Tier bands:

| Composite ≥ | Tier      |
|------------:|-----------|
| 90          | Platinum  |
| 80          | Gold      |
| 70          | Silver    |
| < 70        | Bronze    |

The dashboard `PerformanceScoreCard` reads `GET
/api/seller/performance-score` (returns the latest row). Sellers can
trigger a recompute on demand via `POST .../recompute`.

## Endpoint index

| Endpoint                                              | Role         |
|-------------------------------------------------------|--------------|
| `POST /api/seller/onboarding/stage`                   | Seller       |
| `POST /api/seller/documents`                          | Seller       |
| `PUT  /api/seller/documents/{id}/verify`              | Admin        |
| `GET  /api/seller/bank-accounts`                      | Seller       |
| `POST /api/seller/bank-accounts`                      | Seller       |
| `PUT  /api/seller/bank-accounts/{id}/primary`         | Seller       |
| `GET  /api/seller/warehouses`                         | Seller       |
| `POST /api/seller/warehouses`                         | Seller       |
| `POST /api/seller/agreement/accept`                   | Seller       |
| `GET  /api/seller/agreement/latest`                   | Seller       |
| `GET  /api/seller/settlements`                        | Seller       |
| `GET  /api/seller/settlements/{id}`                   | Seller       |
| `POST /api/seller/settlements/calculate?sellerId=…`   | Admin        |
| `GET  /api/seller/performance-score`                  | Seller       |
| `POST /api/seller/performance-score/recompute`        | Seller       |

## File map

- DB: `ShopNStopDB/dbo/Tables/Seller*.sql`,
  `ShopNStopDB/dbo/Tables/CommissionPlans.sql`,
  `ShopNStopDB/dbo/Tables/VendorAgreements.sql`,
  `ShopNStopDB/dbo/StoredProcedures/usp_Seller_*.sql`,
  `ShopNStopDB/dbo/Data/Seed_CommissionPlans.sql`
- API: `api/Controllers/SellerLifecycleController.cs`,
  `api/Services/SellerLifecycleService.cs`,
  `api/Services/SellerSettlementWorker.cs`,
  `api/Services/SellerScoreWorker.cs`,
  `api/Repositories/SellerLifecycleRepository.cs`
- UI: `stopnshop-ui/src/features/seller/SellerSettlementsPage.tsx`,
  `stopnshop-ui/src/features/seller/SellerBankAccountsPage.tsx`,
  `stopnshop-ui/src/features/seller/SellerWarehousesPage.tsx`,
  `stopnshop-ui/src/features/seller/components/PerformanceScoreCard.tsx`,
  `stopnshop-ui/src/api/sellerLifecycleApi.ts`
- Tests: `tests/StopNShop.Api.UnitTests/SellerLifecycleServiceTests.cs`,
  `stopnshop-ui/src/api/sellerLifecycleApi.test.ts`
