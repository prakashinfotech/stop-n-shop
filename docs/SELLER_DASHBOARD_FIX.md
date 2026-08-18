# Seller Dashboard Not Working — Fix Guide

## Problem
- Endpoint: `/api/seller/orders` returns 401 (Unauthorized)
- Seller Dashboard shows empty
- No orders appearing

---

## Root Causes

### 1. ❌ Not Logged In As Seller
The endpoint requires **seller authentication** with JWT token.

**Fix**: Login as seller in UI
1. Go to http://localhost:3003
2. Click "Seller Dashboard" or "Login"
3. Enter credentials:
   - **Email**: seller@test.com
   - **Password**: SecurePass123
4. Refresh page → Dashboard should populate

---

### 2. ❌ No Test Data in Database
The database might be empty (no products, no orders).

**Fix**: Seed test data

#### Option A: Using SQL Server Management Studio

1. Open **SQL Server Management Studio**
2. Connect to: `localhost\SQLEXPRESS`
3. Select database: `ShopNShop_db`
4. Open file: `seed_test_data.sql`
5. Click **Execute**
6. Verify results

#### Option B: Using Command Line
```bash
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i seed_test_data.sql
```

#### Option C: Using dotnet
```bash
cd api
dotnet ef database update
# (if migrations are set up)
```

---

### 3. ❌ Database Connection String Wrong
The API connects to: `Server=localhost\SQLEXPRESS;Database=ShopNShop_db`

**Verify**:
1. Open SQL Server Management Studio
2. Check: Does `ShopNShop_db` exist?
3. If not → Restore from BACPAC:
   - File: `ShopNStopDB/db-export/ShopNShop_db.bacpac`
   - Restore to `localhost\SQLEXPRESS`

---

## Complete Fix Process

### Step 1: Verify Database Connection

```sql
-- In SQL Server Management Studio
-- Query on master database
SELECT COUNT(*) FROM [ShopNShop_db].[dbo].[Orders]
SELECT COUNT(*) FROM [ShopNShop_db].[dbo].[Users]
SELECT COUNT(*) FROM [ShopNShop_db].[dbo].[Products]
```

Expected: Should not error. If error → database doesn't exist or connection is wrong.

### Step 2: Check Seller Exists

```sql
-- In ShopNShop_db
SELECT UserId, Email, Role, FirstName 
FROM Users 
WHERE Role = 'Seller' AND IsDeleted = 0
```

If empty → Create seller account

### Step 3: Check Orders Exist

```sql
-- In ShopNShop_db
SELECT OrderId, OrderNumber, Status, TotalAmount 
FROM Orders 
WHERE IsDeleted = 0 
ORDER BY CreatedAt DESC
```

If empty → Create test order

### Step 4: Check Order Items Exist

```sql
-- In ShopNShop_db
SELECT o.OrderId, o.OrderNumber, COUNT(oi.OrderItemId) as ItemCount
FROM Orders o
LEFT JOIN OrderItems oi ON o.OrderId = oi.OrderId
WHERE o.IsDeleted = 0
GROUP BY o.OrderId, o.OrderNumber
```

---

## Quick Fix (5 minutes)

### If Database is Empty:

1. **Execute seed script**:
   ```bash
   sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i seed_test_data.sql
   ```

2. **Restart API**:
   ```bash
   # Kill API process
   taskkill /F /IM dotnet.exe
   
   # Restart
   cd api
   dotnet run
   ```

3. **Login as seller**:
   - Go to http://localhost:3003
   - Click "Seller Dashboard"
   - Login with: seller@test.com / SecurePass123

4. **Refresh page**: Dashboard should now show test order

---

## Verify Fix Works

### Endpoint Test
```bash
# Get JWT token
curl -X POST http://localhost:5000/api/auth/seller/login \
  -H "Content-Type: application/json" \
  -d '{"email":"seller@test.com","password":"SecurePass123"}'

# Use token in request
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:5000/api/seller/orders
```

### Expected Response
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "orderNumber": "TEST001",
        "status": "Pending",
        "totalAmount": 994,
        "createdAt": "2026-05-15T..."
      }
    ],
    "totalCount": 1,
    "page": 1,
    "pageSize": 20
  },
  "message": "Success"
}
```

---

## Dashboard in UI

### Expected View:
1. Login as seller → Redirects to dashboard
2. Dashboard shows:
   - Total Orders count
   - Recent orders table
   - Order status breakdown
   - Order chart (if analytics enabled)
3. Can filter by status
4. Can click order to view details
5. Can update order status

### If Still Empty After Login:

1. Check browser console (F12) for errors
2. Check network tab → API call to `/api/seller/orders`
3. Verify Authorization header contains JWT token
4. Check API logs for error details

---

## Troubleshooting

### Error: "Database doesn't exist"
- Restore BACPAC file
- Update connection string if needed

### Error: "Login failed"
- Check SQL Server is running
- Verify credentials
- Check connection string in `appsettings.json`

### Error: "No orders found"
- Execute `seed_test_data.sql`
- Or manually create order in database

### Error: "401 Unauthorized"
- Login as seller in UI first
- Or use valid JWT token in API request

### Error: "403 Forbidden"
- Seller role not in JWT token
- Check `Roles = "Seller"` in controller

---

## Test Data Created

After running `seed_test_data.sql`:

| Item | Value |
|------|-------|
| Seller Email | seller@test.com |
| Seller Password | SecurePass123 |
| Seller ID | 1 |
| Buyer Email | buyer@test.com |
| Buyer ID | 2 |
| Test Order | TEST001 |
| Order Status | Pending |
| Order Total | ₹994 |

---

## Next Steps

1. ✅ Run seed script
2. ✅ Restart API
3. ✅ Login as seller
4. ✅ View dashboard
5. ✅ Test order status update
6. ✅ Check email notification

---

## Support

**Still having issues?**

1. Check all 3 steps above
2. Verify database connection
3. Check browser console (F12)
4. Check API logs
5. Run query manually in SSMS

