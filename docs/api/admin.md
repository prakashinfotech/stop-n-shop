# Admin API Reference

All routes require `Authorization: Bearer <jwt>` with `role=Admin`. Every
write below produces a row in `AuditLogs` via `usp_Admin_AuditTrail_Log`
(verb stored in `NewValues` as `{"verb":"...","data":{...}}`).

Base path: `/api/admin`

## Dashboard

| Method | Path        | Description |
|--------|-------------|-------------|
| GET    | `/dashboard` | Aggregate counts (buyers, sellers, products, orders, revenue, pending approvals). |

## Sellers

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/sellers?pageNo=&pageSize=&approvalStatus=&search=` | Paged seller list. `approvalStatus`: 1=Pending, 2=Approved, 3=Rejected, 4=Suspended. |
| PATCH  | `/sellers/{id}/approve` | Approve a seller. Audit verb `APPROVE_SELLER`. |
| PATCH  | `/sellers/{id}/reject`  | Body: `{ "reason": "..." }`. Audit verb `REJECT_SELLER`. |
| PATCH  | `/sellers/{id}/suspend` | Audit verb `SUSPEND_SELLER`. |
| GET    | `/sellers/{id}/score?from=&to=` | Live performance snapshot (orders, GMV, delivery/cancellation rates, avg rating). 30-day window by default. |

## Products

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/products?pageNo=&pageSize=&approvalStatus=&search=` | Paged product list (all statuses). |
| GET    | `/products/moderation-queue?pageNo=&pageSize=` | Pending-only queue, oldest-first. |
| PATCH  | `/products/{id}/approve` | Audit verb `APPROVE_PRODUCT`. |
| PATCH  | `/products/{id}/reject`  | Body: `{ "reason": "..." }`. Audit verb `REJECT_PRODUCT`. |

## Users

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/users?pageNo=&pageSize=&roleId=&search=` | Paged user list. |
| PATCH  | `/users/{id}/suspend`  | Body: `{ "reason": "..." }`. Sets `IsActive=0`. Audit verb `SUSPEND_USER`. Self-suspend rejected (HTTP 400). |
| PATCH  | `/users/{id}/activate` | Sets `IsActive=1`. Audit verb `ACTIVATE_USER`. |
| DELETE | `/users/{id}` | Soft-delete (`IsDeleted=1`, `IsActive=0`). Audit verb `SOFT_DELETE_USER`. Self-delete rejected. |

## Orders

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/orders?pageNo=&pageSize=&status=&search=` | Paged order list. |
| PATCH  | `/orders/{id}/force-cancel` | Body: `{ "reason": "..." }`. Bypasses buyer-cancel guard but rejects terminal states (Delivered/Cancelled/Returned → HTTP 400). Audit verb `FORCE_CANCEL_ORDER`. |
| PATCH  | `/orders/{id}/refund` | Body: `{ "refundAmount": 250.00, "reason": "...", "gatewayRef": "pay_..." }`. Marks `PaymentStatus=Refunded`. Does NOT call any payment gateway — caller must reconcile. Audit verb `MANUAL_REFUND_ORDER`. |

## Coupons

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/coupons?page=&pageSize=` | List all coupons (active + disabled). |
| POST   | `/coupons` | Create new coupon. Body shape in `CreateCouponRequest`. |
| PATCH  | `/coupons/{id}/toggle` | Body: `{ "isActive": true\|false }`. |
| PUT    | `/coupons/{id}` | Body matches `UpdateCouponRequest`. Audit verb `UPDATE_COUPON`. |
| DELETE | `/coupons/{id}` | Soft-deletes coupon and parent Offer. Audit verb `DELETE_COUPON`. |

## Reviews

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/reviews?pageNo=&pageSize=&isApproved=` | Paged review list. |
| PATCH  | `/reviews/{id}/approve` | Audit verb `APPROVE_REVIEW`. |

## Audit Trail

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/audit?tableName=&recordId=&changedBy=&from=&to=&pageNo=&pageSize=` | Paged audit feed. `tableName` is one of `Sellers`, `Products`, `Users`, `Orders`, `Coupons`, `Reviews`. Results include the actor's name/email and the parsed `NewValues` envelope on the client. |

## CMS (banners)

Untouched by Phase 1; see [CMS endpoints](./cms-endpoints.md) when written.

## Response envelope

Every endpoint returns:

```json
{ "success": true,  "message": "…", "data": …  }
{ "success": false, "message": "…", "data": null }
```

Paged endpoints place the page in `data`:

```json
{ "items": [...], "totalCount": 120, "pageNo": 1, "pageSize": 20 }
```

## Validation

`UpdateCouponRequest`, `ForceCancelOrderRequest`, and `ManualRefundRequest`
are FluentValidation-validated inside `AdminService` before any DB call.
A failing validator surfaces as HTTP 400 with the failure message.
