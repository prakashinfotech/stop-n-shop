# Admin Runbook

Operational guide for routine admin tasks. Pairs with [docs/api/admin.md](./api/admin.md).

## First-time setup

The admin user (`admin@stopnshop.com`) ships with a placeholder password
hash. On first boot:

1. `POST /api/admin/setup { "password": "<strong-password>" }` — works
   exactly once while the hash still has the placeholder prefix.
2. Log in via the buyer login endpoint with the admin email; role claim
   is `Admin`.

## Approving a seller

1. UI: `/admin/sellers` → filter `Pending`.
2. Click **Approve**. Repo call hits `usp_Admin_Seller_Approve`; service
   writes an `APPROVE_SELLER` audit entry.
3. Verify on `/admin/audit` (filter table=`Sellers`).

## Moderating a product submission

1. UI: `/admin/products/moderation` shows pending-only, oldest-first.
2. Approve → product becomes visible on the storefront.
3. Reject → requires a reason; the seller sees it on their products page.

## Suspending a user

Self-suspend is blocked at the SP layer (`THROW 50131`) → HTTP 400. To
re-enable a suspended user, use the `Activate` action; a soft-deleted
user cannot be activated (`IsDeleted=1` filters out of `usp_Admin_User_*`).

## Force-cancelling an order

Used when a buyer's regular cancel window has passed but the order has
not yet shipped. Terminal states (Delivered/Cancelled/Returned) are
rejected by the SP. Cancelling does NOT auto-refund — call
`POST /api/admin/orders/{id}/refund` separately after the gateway side
of the refund is confirmed.

## Issuing a manual refund

1. Cancel the order if appropriate (see above).
2. Process the refund in the payment gateway dashboard. Note the
   gateway reference id.
3. `PATCH /api/admin/orders/{id}/refund` with the actual `refundAmount`
   and `gatewayRef`. The SP validates: order exists, is currently Paid,
   and refund amount is positive and ≤ total. A refund recording on a
   non-Paid order returns HTTP 400.

## Coupon lifecycle

- Create: `POST /admin/coupons` (existing endpoint).
- Edit:   `PUT  /admin/coupons/{id}` — code uniqueness re-checked.
- Toggle: `PATCH /admin/coupons/{id}/toggle` — flips both coupon and
  parent offer.
- Delete: `DELETE /admin/coupons/{id}` — soft-delete both.

## Reading the audit trail

`GET /api/admin/audit` returns every admin write. The verb is on
`newValues` as `{"verb":"...","data":{...}}`. The UI page at
`/admin/audit` parses this and shows the verb as a chip. Filter by
table, date range, or actor (changedBy=userId).

## Where audit entries come from

Two sources both write to `AuditLogs`:

- Phase 1's explicit `usp_Admin_AuditTrail_Log` — called from
  `AdminService` after every write; carries a rich verb in `newValues`.
- Pre-existing triggers (`tr_Users_Audit`, `tr_Orders_Audit`,
  `tr_Sellers_Audit`, `tr_Products_Audit`) — fire on raw UPDATE/DELETE
  and capture column-level OLD/NEW.

When debugging a state change, look at both. The trigger row tells you
what columns changed; the admin-service row tells you which admin
action caused it.

## Performance notes

`AuditLogs` indexes:

- `(TableName, RecordId, ChangedAt DESC)` — fast per-record history.
- `(ChangedAt DESC)` — fast recent-activity feed.

The audit query SP supports all filter combinations the UI exposes;
unfiltered queries scan `(ChangedAt DESC)` and paginate cleanly.

## Known limitations (carried into Phase 3+)

- Seller score endpoint is a live aggregate over Orders/Reviews. When
  the dedicated `SellerPerformanceScore` table lands in Phase 3, this
  SP will read from the cache and an aggregate worker will populate
  the cache nightly.
- Refund SP only records post-conditions; it does not call any payment
  gateway. Webhook signature verification hardening is tracked in
  ENHANCEMENT_PLAN.md §3 under Payment.
