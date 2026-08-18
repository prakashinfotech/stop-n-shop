# StopNShop API Endpoints Reference

> **CRITICAL**: Update this document whenever DTOs, stored procedures, or database schemas change.
> Verify all endpoints still match this spec after any backend modification.

---

## Auth Endpoints

### POST /api/auth/{role}/register
**Roles**: Admin, Buyer, Seller  
**Auth**: None  
**Request**:
```json
{
  "email": "user@example.com",
  "mobile": "9876543210",
  "password": "Test@123",
  "firstName": "John",
  "lastName": "Doe"
}
```
**Response** (200):
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "userId": 1,
    "email": "user@example.com",
    "roleId": 2
  }
}
```

### POST /api/auth/{role}/login
**Roles**: Admin, Buyer, Seller  
**Auth**: None  
**Request**:
```json
{
  "email": "user@example.com",
  "password": "Test@123"
}
```
**Response** (200):
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "userId": 1,
    "roleId": 2,
    "email": "user@example.com"
  }
}
```

---

## Orders Endpoints

### GET /api/orders
**Auth**: Buyer (JWT required)  
**Query Params**: None  
**Response** (200):
```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": 1,
      "orderNumber": "SNS-20260515-00001",
      "status": "PLACED",
      "finalAmount": 1349.15,
      "paymentMethod": "1",
      "createdAt": "2026-05-15T10:30:00",
      "primaryImage": "https://...",
      "itemCount": 1
    }
  ]
}
```
**Fields**:
- `id` (int): Order ID — **REQUIRED** for detail navigation
- `orderNumber` (string): Order reference number
- `status` (string): PLACED|CONFIRMED|PACKED|DISPATCHED|DELIVERED|CANCELLED|RETURNED
- `finalAmount` (decimal): Total order amount
- `paymentMethod` (string): "1"=COD, "2"=Online, "3"=Wallet
- `createdAt` (datetime): Order creation timestamp
- `primaryImage` (string|null): First item's primary image URL
- `itemCount` (int): Number of items in order

### GET /api/orders/{id}
**Auth**: Buyer (JWT required)  
**Path Params**: `id` (int) - Order ID  
**Response** (200):
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": 1,
    "orderNumber": "SNS-20260515-00001",
    "status": "PLACED",
    "paymentMethod": "1",
    "paymentStatus": "1",
    "createdAt": "2026-05-15T10:30:00",
    "totalMRP": 2999,
    "totalDiscount": 1200,
    "couponDiscount": 449.85,
    "couponCode": "FESTIVE15",
    "deliveryCharge": 0,
    "finalAmount": 1349.15,
    "addressLine1": "K 102",
    "addressLine2": "Ahmedabad",
    "city": "Ahmedabad",
    "state": "Gujarat",
    "pincode": "380058",
    "items": [
      {
        "id": 1,
        "productId": 5,
        "productName": "Sterling Silver Chain Bracelet",
        "brandName": "Fastrack",
        "imageUrl": "https://...",
        "quantity": 1,
        "sellingPrice": 1799
      }
    ]
  }
}
```

### POST /api/orders
**Auth**: Buyer (JWT required)  
**Request**:
```json
{
  "addressId": 1,
  "paymentMethod": "COD",
  "couponCode": "SAVE50"
}
```
**Response** (200):
```json
{
  "success": true,
  "message": "Order placed successfully.",
  "data": {
    "orderId": 1
  }
}
```
**Status Codes**:
- 200: Order placed
- 400: Cart empty, out of stock, invalid coupon, invalid address
- 401: Unauthorized
- 500: Server error (check stored procedure)

**Stored Procedure**: `usp_Commerce_Order_Place`  
**Parameters**:
- `@UserId` (int): Buyer user ID
- `@ShippingAddressId` (int): Address ID
- `@PaymentMode` (tinyint): 1=COD, 2=Online, 3=Wallet
- `@CouponCode` (nvarchar(50)): Optional coupon code

### DELETE /api/orders/{id}
**Auth**: Buyer (JWT required)  
**Path Params**: `id` (int) - Order ID  
**Request**:
```json
{
  "reason": "Changed my mind"
}
```
**Response** (200):
```json
{
  "success": true,
  "message": "Order cancelled successfully.",
  "data": {
    "id": 1,
    "orderNumber": "SNS-...",
    "status": "CANCELLED",
    "createdAt": "2026-05-15T10:30:00",
    "finalAmount": 1349.15
  }
}
```

---

## Cart Endpoints

### GET /api/cart
**Auth**: Buyer (JWT required)  
**Response** (200):
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [
      {
        "cartId": 1,
        "productId": 5,
        "productName": "Sterling Silver Chain Bracelet",
        "brandName": "Fastrack",
        "primaryImage": "https://...",
        "sizeLabel": "Free Size",
        "colorName": "Gold",
        "quantity": 1,
        "mrp": 2999,
        "sellingPrice": 1799,
        "discountPct": 40.0,
        "itemMRP": 2999,
        "itemTotal": 1799
      }
    ],
    "summary": {
      "totalMRP": 2999,
      "totalDiscount": 1200,
      "deliveryCharge": 0,
      "finalAmount": 1799
    }
  }
}
```

### POST /api/cart
**Auth**: Buyer (JWT required)  
**Request**:
```json
{
  "productId": 5,
  "quantity": 1,
  "sizeLabel": "Free Size",
  "colorName": "Gold"
}
```
**Response** (200):
```json
{
  "success": true,
  "message": "Added to cart",
  "data": {
    "cartId": 1
  }
}
```

### PATCH /api/cart/{cartId}
**Auth**: Buyer (JWT required)  
**Path Params**: `cartId` (int)  
**Request**:
```json
{
  "quantity": 2
}
```
**Response** (200):
```json
{
  "success": true,
  "message": "Cart updated",
  "data": "updated"
}
```

### DELETE /api/cart/{cartId}
**Auth**: Buyer (JWT required)  
**Path Params**: `cartId` (int)  
**Response** (200):
```json
{
  "success": true,
  "message": "Item removed from cart",
  "data": null
}
```

---

## Profile / Addresses Endpoints

### GET /api/profile
**Auth**: Any (Buyer|Seller|Admin)  
**Response** (200):
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "userId": 1,
    "email": "dolly@example.com",
    "firstName": "Dolly",
    "lastName": "Mishra",
    "mobile": "9876543210",
    "profileImageUrl": "https://..."
  }
}
```

### GET /api/profile/addresses
**Auth**: Any (Buyer|Seller|Admin)  
**Response** (200):
```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": 1,
      "name": "Home",
      "mobile": "9876543210",
      "addressLine1": "K 102",
      "addressLine2": "Ahmedabad",
      "city": "Ahmedabad",
      "state": "Gujarat",
      "pincode": "380058",
      "isDefault": true
    }
  ]
}
```
**Fields**:
- `id` (int): Address ID — **REQUIRED** for order placement
- `name` (string): Address label (Home/Work/Other)
- `mobile` (string): Contact number
- `addressLine1` (string): Street address
- `addressLine2` (string|null): Apt/Suite
- `city` (string)
- `state` (string)
- `pincode` (string)
- `isDefault` (bool)

### POST /api/profile/addresses
**Auth**: Any  
**Request**:
```json
{
  "name": "Home",
  "mobile": "9876543210",
  "addressLine1": "K 102",
  "addressLine2": "Ahmedabad",
  "city": "Ahmedabad",
  "state": "Gujarat",
  "pincode": "380058",
  "isDefault": true
}
```
**Response** (200):
```json
{
  "success": true,
  "message": "Address saved",
  "data": {
    "id": 1
  }
}
```

---

## Seller Dashboard Endpoints

### GET /api/seller/dashboard
**Auth**: Seller (JWT required)  
**Response** (200):
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "totalProducts": 15,
    "activeProducts": 12,
    "lowStockCount": 2,
    "totalOrders": 45,
    "totalSales": 125000.00
  }
}
```
**Stored Procedure**: `sp_SellerGetDashboard`  
**Parameters**: `@SellerId` (int)

### GET /api/seller/analytics
**Auth**: Seller (JWT required)  
**Query Params**:
- `fromDate` (date, optional): Default -29 days
- `toDate` (date, optional): Default today

**Response** (200):
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "fromDate": "2026-04-16",
    "toDate": "2026-05-15",
    "totalRevenue": 125000.00,
    "totalOrders": 45,
    "totalUnitsSold": 78,
    "averageOrderValue": 2777.78,
    "newOrders": 5,
    "processingOrders": 8,
    "shippedOrders": 12,
    "deliveredOrders": 15,
    "cancelledOrders": 5
  }
}
```
**Stored Procedure**: `usp_Seller_Dashboard_GetAnalytics`  
**Parameters**:
- `@SellerId` (int)
- `@FromDate` (date, nullable): Default GETUTCDATE() - 29 days
- `@ToDate` (date, nullable): Default GETUTCDATE()

---

## Verification Checklist

**After ANY change to:**
- ✓ DTOs (request/response objects)
- ✓ Stored procedures (parameters, return columns)
- ✓ Database schema (new/removed columns)
- ✓ API controllers (endpoint signature changes)

**Run these verification steps:**

1. **Check DTO matches response**: Compare response JSON with DTO properties
2. **Verify field names**: Ensure camelCase in JSON matches C# properties
3. **Check field types**: int, string, decimal, bool, datetime are correct
4. **Verify null handling**: Nullable fields marked with `?` in DTO
5. **Test each endpoint**: Use Postman or browser DevTools Network tab
6. **Check stored procedure parameters**: Match parameter names exactly (`@UserId`, not `@userid`)
7. **Verify response status codes**: 200, 400, 401, 404, 500 as documented

---

## Common Issues & Fixes

### Issue: `NaN` in URL (e.g., `/orders/NaN`)
**Cause**: Response missing `id` field or field is null  
**Fix**: Check response JSON has `id` field with non-null integer value

### Issue: 500 Server Error on order placement
**Cause**: Cart empty, products out of stock, or stored procedure error  
**Fix**: Check `usp_Commerce_Order_Place` SP parameters match exactly

### Issue: Field returns null unexpectedly
**Cause**: DTO property not being set from database query result  
**Fix**: Verify stored procedure SELECT includes the column, and repository maps it

### Issue: camelCase vs PascalCase mismatch
**Cause**: C# property `FirstName` → JSON `firstName` (automatic by ASP.NET)  
**Fix**: DTOs use PascalCase, JSON serialization handles conversion automatically

---

**Last Updated**: 2026-05-15  
**By**: Claude  
**Next Review**: After any backend/database changes
