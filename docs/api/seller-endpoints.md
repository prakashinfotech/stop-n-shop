# Seller API Endpoints Reference

## Base URL

```
http://localhost:5000/api/seller
```

---

## Authentication Endpoints

### POST /auth/signup

Register a new seller account.

**Auth:** None  
**Body:**

```json
{
  "businessName": "XYZ Apparel",
  "ownerName": "John Doe",
  "email": "john@xyzapparel.com",
  "phoneNumber": "9876543210",
  "gstNumber": "27AABCT1234A1Z0",
  "address": "123 Market St",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!"
}
```

**Response 200:**

```json
{
  "success": true,
  "message": "Seller registered successfully.",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-06-10T14:30:00Z",
    "seller": {
      "id": 1,
      "businessName": "XYZ Apparel",
      "ownerName": "John Doe",
      "email": "john@xyzapparel.com",
      "phoneNumber": "9876543210",
      "gstNumber": "27AABCT1234A1Z0",
      "address": "123 Market St",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pincode": "400001",
      "isActive": true,
      "isApproved": false,
      "createdAt": "2026-05-10T14:30:00Z"
    }
  }
}
```

**Response 400:** Email exists / Invalid input

---

### POST /auth/login

Authenticate seller with email and password.

**Auth:** None  
**Body:**

```json
{
  "email": "john@xyzapparel.com",
  "password": "SecurePass123!"
}
```

**Response 200:**

```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-06-10T14:30:00Z",
    "seller": {
      "id": 1,
      "businessName": "XYZ Apparel",
      "email": "john@xyzapparel.com",
      "isApproved": true
    }
  }
}
```

**Response 401:** Invalid email/password  
**Response 400:** Account pending approval

---

### GET /auth/profile

Get current seller profile.

**Auth:** Seller Bearer Token  
**Headers:**

```
Authorization: Bearer {token}
```

**Response 200:**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "businessName": "XYZ Apparel",
    "ownerName": "John Doe",
    "email": "john@xyzapparel.com",
    "phoneNumber": "9876543210",
    "gstNumber": "27AABCT1234A1Z0",
    "address": "123 Market St",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "bannerUrl": "https://cdn.example.com/banner.jpg",
    "logoUrl": "https://cdn.example.com/logo.jpg",
    "supportEmail": "support@xyzapparel.com",
    "supportPhone": "9876543210",
    "description": "Premium apparel brand",
    "isActive": true,
    "isApproved": true,
    "createdAt": "2026-05-10T14:30:00Z",
    "updatedAt": "2026-05-10T14:30:00Z"
  }
}
```

---

### PUT /auth/profile

Update seller profile information.

**Auth:** Seller Bearer Token  
**Body:** (all fields optional)

```json
{
  "businessName": "XYZ Apparel Ltd",
  "ownerName": "John Doe",
  "phoneNumber": "9876543210",
  "gstNumber": "27AABCT1234A1Z0",
  "address": "456 Fashion Ave",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "bannerUrl": "https://cdn.example.com/new-banner.jpg",
  "logoUrl": "https://cdn.example.com/new-logo.jpg",
  "supportEmail": "support@xyzapparel.com",
  "supportPhone": "9876543210",
  "description": "Premium apparel brand — official"
}
```

**Response 200:** Updated profile (same as GET /auth/profile)

---

## Product Management Endpoints

### GET /products

List seller's products (paginated).

**Auth:** Seller  
**Query Params:**

```
pageNo=1&pageSize=20&search=shirt
```

**Response 200:**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 101,
        "name": "Cotton T-Shirt",
        "mrp": 999.00,
        "sellingPrice": 699.00,
        "discountPercent": 30.03,
        "stockQuantity": 50,
        "lowStockThreshold": 10,
        "primaryImage": "/images/shirt-1.jpg",
        "isApproved": false,
        "createdAt": "2026-05-10T14:30:00Z"
      }
    ],
    "totalCount": 1,
    "pageNo": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### GET /products/{id}

Get full product detail with images, sizes, colors.

**Auth:** Seller  
**Response 200:**

```json
{
  "success": true,
  "data": {
    "id": 101,
    "productTypeId": 5,
    "brandId": 2,
    "name": "Cotton T-Shirt",
    "description": "Premium cotton t-shirt",
    "mrp": 999.00,
    "sellingPrice": 699.00,
    "discountPercent": 30.03,
    "gender": "M",
    "stockQuantity": 50,
    "lowStockThreshold": 10,
    "isActive": true,
    "isApproved": false,
    "createdAt": "2026-05-10T14:30:00Z",
    "images": [
      {
        "id": 1,
        "imageUrl": "/uploads/products/img-1.jpg",
        "sortOrder": 0,
        "isPrimary": true
      }
    ],
    "sizes": [
      { "id": 1, "sizeLabel": "S", "stockQuantity": 15 },
      { "id": 2, "sizeLabel": "M", "stockQuantity": 20 },
      { "id": 3, "sizeLabel": "L", "stockQuantity": 15 }
    ],
    "colors": [
      { "id": 1, "colorName": "Black", "colorHex": "#000000" },
      { "id": 2, "colorName": "White", "colorHex": "#FFFFFF" }
    ]
  }
}
```

---

### POST /products

Create a new product.

**Auth:** Seller  
**Body:**

```json
{
  "name": "Cotton T-Shirt",
  "description": "Premium 100% cotton t-shirt",
  "productTypeId": 5,
  "brandId": 2,
  "mrp": 999.00,
  "sellingPrice": 699.00,
  "gender": "M",
  "stockQuantity": 100,
  "lowStockThreshold": 10
}
```

**Response 200:** Product detail (same as GET /products/{id})

---

### PUT /products/{id}

Update product details.

**Auth:** Seller  
**Body:** (all fields optional)

```json
{
  "name": "Premium Cotton T-Shirt",
  "description": "Updated description",
  "mrp": 1099.00,
  "sellingPrice": 749.00,
  "gender": "M",
  "stockQuantity": 120
}
```

**Response 200:**

```json
{
  "success": true,
  "message": "Product updated successfully."
}
```

---

### DELETE /products/{id}

Soft-delete product (marks as inactive).

**Auth:** Seller  
**Response 200:**

```json
{
  "success": true,
  "message": "Product deactivated successfully."
}
```

---

### PATCH /products/{id}/inventory

Update stock and low-stock threshold.

**Auth:** Seller  
**Body:**

```json
{
  "stockQuantity": 150,
  "lowStockThreshold": 15
}
```

**Response 200:**

```json
{
  "success": true,
  "message": "Inventory updated successfully."
}
```

---

### POST /products/images/upload

Upload one or more product images.

**Auth:** Seller  
**Content-Type:** multipart/form-data  
**Form Data:**

```
files: [file1.jpg, file2.jpg, ...]  (max 10 files, 5MB each)
```

**Response 200:**

```json
{
  "success": true,
  "message": "2 image(s) uploaded.",
  "data": [
    {
      "fileName": "550e8400-e29b-41d4-a716-446655440000.jpg",
      "url": "/uploads/products/550e8400-e29b-41d4-a716-446655440000.jpg"
    },
    {
      "fileName": "660e8400-e29b-41d4-a716-446655440001.jpg",
      "url": "/uploads/products/660e8400-e29b-41d4-a716-446655440001.jpg"
    }
  ]
}
```

---

## Inventory Endpoints

### GET /inventory

Get stock levels for all seller products.

**Auth:** Seller  
**Response 200:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "productId": 101,
      "productName": "Cotton T-Shirt",
      "stockQuantity": 100,
      "reservedQuantity": 20,
      "availableQuantity": 80,
      "lowStockThreshold": 10,
      "isLowStock": false
    },
    {
      "id": 2,
      "productId": 102,
      "productName": "Denim Jeans",
      "stockQuantity": 8,
      "reservedQuantity": 0,
      "availableQuantity": 8,
      "lowStockThreshold": 10,
      "isLowStock": true
    }
  ]
}
```

---

### GET /inventory/low-stock

Get products below low-stock threshold.

**Auth:** Seller  
**Response 200:**

```json
{
  "success": true,
  "message": "1 item(s) low on stock.",
  "data": [
    {
      "id": 2,
      "productId": 102,
      "productName": "Denim Jeans",
      "stockQuantity": 8,
      "lowStockThreshold": 10,
      "availableQuantity": 8
    }
  ]
}
```

---

## Order Endpoints

### GET /orders

Get paginated list of seller's orders.

**Auth:** Seller  
**Query Params:**

```
pageNo=1&pageSize=20
```

**Response 200:**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "orderId": 5001,
        "orderNumber": "SNS5001",
        "orderStatus": "SHIPPED",
        "finalAmount": 1500.00,
        "itemCount": 2,
        "createdAt": "2026-05-08T10:30:00Z"
      }
    ],
    "totalCount": 15,
    "pageNo": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### GET /orders/{orderId}

Get full order detail with items and shipping address.

**Auth:** Seller  
**Response 200:**

```json
{
  "success": true,
  "data": {
    "id": 5001,
    "orderNumber": "SNS5001",
    "status": "SHIPPED",
    "paymentStatus": "COMPLETED",
    "finalAmount": 1500.00,
    "deliveryCharge": 50.00,
    "createdAt": "2026-05-08T10:30:00Z",
    "items": [
      {
        "id": 1,
        "productId": 101,
        "productName": "Cotton T-Shirt",
        "imageUrl": "/images/shirt-1.jpg",
        "sizeLabel": "M",
        "colorName": "Black",
        "quantity": 1,
        "mrp": 999.00,
        "sellingPrice": 699.00,
        "lineTotal": 699.00
      },
      {
        "id": 2,
        "productId": 102,
        "productName": "Denim Jeans",
        "imageUrl": "/images/jeans-1.jpg",
        "sizeLabel": "32",
        "colorName": "Blue",
        "quantity": 1,
        "mrp": 2499.00,
        "sellingPrice": 1899.00,
        "lineTotal": 1899.00
      }
    ],
    "address": {
      "name": "Jane Smith",
      "mobile": "9123456789",
      "addressLine1": "123 Main St",
      "addressLine2": "Apt 4B",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pincode": "400001"
    }
  }
}
```

---

## Dashboard Endpoints

### GET /dashboard

Get dashboard statistics for the seller.

**Auth:** Seller  
**Response 200:**

```json
{
  "success": true,
  "data": {
    "totalProducts": 42,
    "activeProducts": 38,
    "lowStockCount": 3,
    "totalOrders": 127,
    "totalSales": 456789.50
  }
}
```

---

## Error Responses

All endpoints return standardized error responses:

**400 Bad Request:**

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": ["Email format is invalid", "Password too weak"]
}
```

**401 Unauthorized:**

```json
{
  "success": false,
  "message": "Invalid email or password.",
  "errors": null
}
```

**403 Forbidden:**

```json
{
  "success": false,
  "message": "Unauthorized",
  "errors": null
}
```

**404 Not Found:**

```json
{
  "success": false,
  "message": "Product not found.",
  "errors": null
}
```

**500 Internal Server Error:**

```json
{
  "success": false,
  "message": "An error occurred",
  "errors": null
}
```

---

## HTTP Status Codes

| Code | Meaning |
|---|---|
| 200 | Success |
| 400 | Bad request (validation error) |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not found |
| 500 | Internal server error |

---

## Authentication Header

All protected endpoints require:

```
Authorization: Bearer {jwt_token}
```

Token obtained from `POST /auth/signup` or `POST /auth/login`.

Token expires in 30 days. Include in all subsequent requests.
