# Database Schema Deployment — REQUIRED

## Problem
The code is calling stored procedures that don't exist in the database:
- `usp_Seller_Order_GetAll` ❌
- `sp_SellerGetOrderDetail` ❌
- `usp_Seller_Order_UpdateStatus` ❌
- `usp_Seller_Order_Cancel` ❌

**This causes 500 errors.**

---

## Solution: Deploy SQL Scripts

### Option 1: Using SQL Server Management Studio (Easiest)

1. **Open SQL Server Management Studio**
2. **Connect to**: `localhost\SQLEXPRESS`
3. **Select Database**: `ShopNShop_db`
4. **Execute each file in order**:

```
ShopNStopDB/dbo/StoredProcedures/usp_Seller_Order_GetAll.sql
ShopNStopDB/dbo/StoredProcedures/usp_Seller_Order_UpdateStatus.sql  
ShopNStopDB/dbo/StoredProcedures/usp_SellerOrder_UpdateStatus.sql
ShopNStopDB/dbo/StoredProcedures/usp_Seller_Order_Cancel.sql
ShopNStopDB/dbo/StoredProcedures/sp_SellerGetOrderDetail.sql
```

**Steps**:
1. Right-click `ShopNShop_db` → **New Query**
2. Copy content of first SQL file → **Execute**
3. Repeat for remaining files

### Option 2: Command Line

```bash
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_Seller_Order_GetAll.sql"
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_Seller_Order_UpdateStatus.sql"
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_SellerOrder_UpdateStatus.sql"
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_Seller_Order_Cancel.sql"
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\sp_SellerGetOrderDetail.sql"
```

### Option 3: Create Master Deployment Script

```bash
# Save this as deploy_seller_sps.bat
@echo off
echo Deploying Seller Order Stored Procedures...

sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_Seller_Order_GetAll.sql"
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_Seller_Order_UpdateStatus.sql"
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_SellerOrder_UpdateStatus.sql"
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_Seller_Order_Cancel.sql"
sqlcmd -S "localhost\SQLEXPRESS" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\sp_SellerGetOrderDetail.sql"

echo Done!
```

---

## Verify Deployment

After running the scripts, verify the stored procedures exist:

```sql
-- In SSMS, run this query on ShopNShop_db:
SELECT name FROM sys.objects 
WHERE type = 'P' 
AND name IN (
    'usp_Seller_Order_GetAll',
    'sp_SellerGetOrderDetail',
    'usp_Seller_Order_UpdateStatus',
    'usp_SellerOrder_UpdateStatus',
    'usp_Seller_Order_Cancel'
)
ORDER BY name;
```

Expected result: **5 rows** (all 5 stored procedures exist)

---

## Test After Deployment

1. **Restart API**:
   ```bash
   taskkill /F /IM dotnet.exe
   cd api && dotnet run
   ```

2. **Test endpoint**:
   ```bash
   curl http://localhost:5000/api/seller/orders
   # Should return 401 (auth required) - NOT 500
   ```

3. **Login and test with token**:
   ```bash
   # Login first to get JWT token
   curl -X POST http://localhost:5000/api/auth/seller/login \
     -H "Content-Type: application/json" \
     -d '{"email":"seller@test.com","password":"SecurePass123"}'
   
   # Use token in request
   curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:5000/api/seller/orders
   ```

---

## Root Cause Analysis

The database schema files exist in the repository but were never deployed to the database instance. This is why:
- Code compiles ✅
- Database exists ✅
- But endpoints throw 500 error ❌

The SSDT project needs to be published to deploy all objects.

---

## Prevention

Going forward:
1. Always deploy schema before testing endpoints
2. Use SSDT publish to deploy all objects at once
3. Verify all stored procedures exist before endpoint testing

