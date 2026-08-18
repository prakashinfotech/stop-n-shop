# STOP-N-SHOP E-COMMERCE PLATFORM
## Technical Documentation & System Architecture

**Document Version:** 1.0  
**Date:** May 2026  
**Platform:** Enterprise Fashion E-Commerce Platform  
**Technology Stack:** ASP.NET Core 8, React 18 + TypeScript, SQL Server 2022

---

## TABLE OF CONTENTS
1. [Technology Stack](#technology-stack)
2. [System Architecture](#system-architecture)
3. [Database Schema & Entities](#database-schema--entities)
4. [User Authentication & Authorization Flow](#user-authentication--authorization-flow)
5. [Admin Module](#admin-module)
6. [Seller Module](#seller-module)
7. [Buyer Module](#buyer-module)
8. [API Endpoints Reference](#api-endpoints-reference)
9. [Email Notification System](#email-notification-system)
10. [Error Handling & Validation](#error-handling--validation)

---

## TECHNOLOGY STACK

### Backend
- **Framework:** ASP.NET Core 8 (.NET 8)
- **Language:** C# 12
- **Database:** Microsoft SQL Server 2022
- **Data Access:** Dapper ORM (stored procedures only)
- **Authentication:** JWT Bearer Tokens (30-day expiry)
- **Email Service:** SMTP (Office365)
- **Logging:** Serilog
- **API Documentation:** Swagger/OpenAPI with XML comments

### Frontend
- **Framework:** React 18
- **State Management:** TanStack React Query v5
- **Styling:** Tailwind CSS 3.3
- **Language:** TypeScript 5.3
- **Routing:** React Router v6
- **HTTP Client:** Axios
- **Charts:** Recharts
- **UI Components:** Lucide React Icons
- **Animations:** Framer Motion
- **Build Tool:** Vite 5.4
- **Package Manager:** npm

### DevOps & Infrastructure
- **Version Control:** Git
- **Build Process:** SSDT (SQL Server Data Tools) for database
- **API Server:** Kestrel (IIS compatible)
- **UI Server:** Nginx/Node.js
- **Database Connection:** TCP/IP with SSL encryption

---

## SYSTEM ARCHITECTURE

### Layered Architecture

```
┌─────────────────────────────────────────────────────────┐
│               React Frontend (SPA)                       │
│         [Components] [Pages] [Hooks] [Services]         │
└─────────────────────────────┬───────────────────────────┘
                              │
                      HTTP/HTTPS (REST)
                              │
┌─────────────────────────────────────────────────────────┐
│           ASP.NET Core 8 API Layer                       │
├─────────────────────────────────────────────────────────┤
│  Controllers (HTTP Endpoints)                            │
│  ├── AuthController                                      │
│  ├── ProfileController                                   │
│  ├── OrdersController                                    │
│  ├── SellerOrderController                               │
│  ├── CatalogController                                   │
│  ├── SellerProductController                             │
│  ├── AdminController                                     │
│  └── CMSController                                       │
├─────────────────────────────────────────────────────────┤
│  Services (Business Logic)                               │
│  ├── AuthService (JWT, Password hashing, OTP)            │
│  ├── OrderService (Order placement, cancellation)        │
│  ├── SellerOrderService (Status updates, notifications)  │
│  ├── CartService (Cart operations)                       │
│  ├── CatalogService (Product queries, filtering)         │
│  ├── EmailService (SMTP notifications)                   │
│  └── SellerDashboardService (Analytics, stats)           │
├─────────────────────────────────────────────────────────┤
│  Repositories (Data Access)                              │
│  ├── AuthRepository (Users, OTPs, Profiles)              │
│  ├── OrderRepository (Orders, via stored procedures)     │
│  ├── CartRepository (Cart items)                         │
│  ├── CatalogRepository (Products, categories, brands)    │
│  ├── SellerOrderRepository (Seller-specific queries)     │
│  └── SellerDashboardRepository (Analytics data)          │
└─────────────────────────────┬───────────────────────────┘
                              │
                    SQL Server via Dapper
                              │
┌─────────────────────────────────────────────────────────┐
│         SQL Server 2022 Database (ShopNShop_db)          │
├─────────────────────────────────────────────────────────┤
│  Tables: Users, Orders, OrderItems, Products,            │
│  ProductVariants, Cart, Wishlist, Addresses,             │
│  Sellers, Brands, Categories, Coupons, etc.              │
│                                                          │
│  Stored Procedures: All data operations routed through   │
│  usp_* naming convention. NO inline SQL in C#.           │
│                                                          │
│  Security: Encrypted passwords (PBKDF2 SHA256),          │
│  SQL injection prevention via parameterized queries      │
└─────────────────────────────────────────────────────────┘
```

### Role-Based Access Control (RBAC)

Three distinct roles with separate authentication flows:

1. **ADMIN** (RoleId: 1)
   - System management, vendor approvals, order management
   - Separate login endpoint: `POST /api/auth/admin/login`

2. **SELLER** (RoleId: 2)
   - Product management, order fulfillment, analytics
   - Separate login endpoint: `POST /api/auth/seller/login`

3. **BUYER** (RoleId: 3)
   - Shopping, checkout, order tracking
   - Standard login endpoint: `POST /api/auth/buyer/login` (or `/api/auth/login` legacy alias)

All JWT tokens include role claims for authorization at controller level.

---

## DATABASE SCHEMA & ENTITIES

### Core Entities

#### Users Table
```
UserId (PK, Int, Identity)
Email (NVarchar(256), Unique)
Mobile (NVarchar(15), Unique)
PasswordHash (NVarchar(500))
RoleId (FK → Roles)
FirstName, LastName (NVarchar(100))
ProfileImageUrl (NVarchar(500))
IsEmailVerified, IsMobileVerified (Bit)
IsApproved (Bit) - Seller approval flag
LastLoginAt (DateTime2)
IsFirstLogin (Bit) - Tracks first-time user for wallet credit
LoyaltyPoints (Int)
ReferralCode (NVarchar(20), Unique)
CreatedAt, UpdatedAt (DateTime2)
IsActive, IsDeleted (Bit) - Soft delete pattern
```

**Relationships:**
- Users.RoleId → Roles.RoleId
- Users.CreatedBy, UpdatedBy → Users.UserId (Self-referencing)

#### Orders Table
```
OrderId (PK, Int, Identity)
UserId (FK → Users)
OrderNumber (NVarchar(50), Unique)
OrderStatus (TinyInt) - 1=Pending, 2=Confirmed, 3=Processing, 
                        4=Shipped, 5=Delivered, 6=Cancelled, 7=Returned
SubTotal, DiscountAmount, CouponDiscount, TaxAmount, 
ShippingCharge, TotalAmount (Decimal(18,2))
ShippingAddressId (FK → UserAddresses)
PaymentMode (TinyInt) - 1=COD, 2=Online, 3=Wallet
PaymentStatus (TinyInt) - 1=Pending, 2=Paid, 3=Failed, 4=Refunded
CouponId (FK → Coupons, Nullable)
ExpectedDeliveryDate (Date)
DeliveredAt, CancelledAt (DateTime2, Nullable)
CancellationReason (NVarchar(500))
EmailSentAt, SmsSentAt (DateTime2)
CreatedAt, UpdatedAt, IsActive, IsDeleted
```

**Relationships:**
- Orders.UserId → Users.UserId
- Orders.CouponId → Coupons.CouponId
- Orders.ShippingAddressId → UserAddresses.AddressId

#### OrderItems Table
```
OrderItemId (PK, Int, Identity)
OrderId (FK → Orders)
ProductId, VariantId (FK → Products, ProductVariants)
SellerId (FK → Sellers)
BrandId (FK → Brands)
ProductName, VariantSnapshot (NVarchar(300))
Quantity, UnitPrice (Decimal(18,2))
DiscountAmount, TaxAmount, TotalPrice (Decimal(18,2))
SellerCommissionRate, CommissionAmount, SellerEarning (Decimal)
IsReturned (Bit)
ReturnReason (NVarchar(500))
CreatedAt, UpdatedAt, IsActive, IsDeleted
```

**Relationships:**
- OrderItems.OrderId → Orders.OrderId
- OrderItems.SellerId → Sellers.SellerId
- OrderItems.ProductId → Products.ProductId
- OrderItems.VariantId → ProductVariants.VariantId

#### Sellers Table
```
SellerId (PK, Int, Identity)
UserId (FK → Users)
BusinessName, GstNumber, PanNumber (NVarchar)
ApprovalStatus (TinyInt) - 0=Pending, 1=Approved, 2=Rejected
BusinessAddressId (FK → UserAddresses)
BankAccountNumber, BankIfscCode, BankName (NVarchar)
RejectionReason (NVarchar(500), Nullable)
SuspensionReason (NVarchar(500), Nullable)
CommissionRate (Decimal(5,2))
CreatedAt, UpdatedAt, IsActive, IsDeleted
```

#### Products Table
```
ProductId (PK, Int, Identity)
SellerId (FK → Sellers)
BrandId (FK → Brands)
CategoryId, SubCategoryId (FK → Categories, SubCategories)
ProductName (NVarchar(300))
SlugUrl (NVarchar(500), Unique)
ShortDescription, LongDescription (NVarchar(Max))
MRP, SellingPrice, CostPrice (Decimal(18,2))
GstRate (Decimal(5,2))
Sku (NVarchar(50), Unique)
GenderTypeId (TinyInt) - Product gender classification
Tags, MetaTitle, MetaDescription, MetaKeywords (NVarchar)
ApprovalStatus (TinyInt) - 0=Pending, 1=Approved, 2=Rejected
CreatedAt, UpdatedAt, IsActive, IsDeleted
```

#### Cart Table
```
CartId (PK, Int, Identity)
UserId (FK → Users)
ProductId, VariantId (FK → Products, ProductVariants)
Quantity (Int)
SavedForLater (Bit)
CreatedAt, UpdatedAt, IsDeleted
```

#### UserAddresses Table
```
AddressId (PK, Int, Identity)
UserId (FK → Users)
Label, AddressLine1, AddressLine2 (NVarchar)
City, State, Country (NVarchar)
PinCode (NVarchar(10))
IsDefault (Bit)
CreatedAt, UpdatedAt, IsActive, IsDeleted
```

---

## USER AUTHENTICATION & AUTHORIZATION FLOW

### **AUTHENTICATION PHASE**

#### Step 1: User Registration (All Roles)
**Endpoint:** `POST /api/auth/buyer/register`

**Request:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "mobile": "9876543210",
  "password": "SecurePass123!"
}
```

**Backend Processing:**
1. **Validation:**
   - Email format check (RFC 5322)
   - Mobile length check (10 digits)
   - Password strength (8+ chars, uppercase, lowercase, number, special char)
   - Duplicate email/mobile check via database

2. **Data Processing:**
   - Password hashing: PBKDF2 with SHA256 (100,000 iterations)
   - Salt generation: 16 random bytes
   - SQL Execution: `usp_Auth_User_Register`
     - Parameters: @Email, @Mobile, @PasswordHash, @RoleId, @FirstName, @LastName
     - Returns: @UserId, @ErrorCode (50001=EMAIL_EXISTS, 50002=MOBILE_EXISTS)

3. **Response:**
   - Auto-login on success
   - JWT token generated
   - User profile returned with `IsFirstLogin = true` (wallet credit trigger)

**Database Operations:**
```sql
INSERT INTO Users (Email, Mobile, PasswordHash, RoleId, FirstName, LastName, 
                   IsFirstLogin, CreatedAt, IsActive)
VALUES (@Email, @Mobile, @PasswordHash, @RoleId, @FirstName, @LastName, 1, GETUTCDATE(), 1)
```

---

#### Step 2: User Login (All Roles)
**Endpoints:**
- Buyer: `POST /api/auth/buyer/login`
- Seller: `POST /api/seller/auth/login`
- Admin: `POST /api/admin/auth/login`

**Request:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Backend Processing:**
1. **Lookup:**
   - SQL Execution: `usp_Auth_User_Login`
   - Parameters: @Email
   - Returns: UserId, PasswordHash, RoleId, IsApproved, IsEmailVerified, IsMobileVerified, IsFirstLogin

2. **Validation:**
   - User exists check
   - Password verification: PBKDF2 hash comparison
   - For Sellers: IsApproved flag must be 1
   - Error handling with specific error codes (50003=NOT_FOUND, 50004=WRONG_ROLE)

3. **JWT Token Generation:**
   - Claims included:
     - `ClaimTypes.NameIdentifier`: UserId (string)
     - `ClaimTypes.Role`: Role name (Admin/Seller/Buyer)
     - `ClaimTypes.Email`: User email
     - Custom claim `mobile`: User's mobile number
   - Expiry: 30 days from creation
   - Algorithm: HS256 with secret key from appsettings.json

4. **Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGc...",
    "expiresAt": "2026-06-15T10:30:00Z",
    "user": {
      "id": 1,
      "email": "john@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "Buyer",
      "isFirstLogin": true,
      "createdAt": "2026-05-15T10:30:00Z"
    }
  }
}
```

**First-Time User Trigger:**
- If `IsFirstLogin = true`:
  - Frontend displays congratulatory modal
  - Modal offers ₹500 wallet credit
  - User can accept/dismiss
  - On acceptance: API call to `/api/auth/mark-first-login-complete`
  - Backend: `usp_Auth_MarkFirstLoginComplete` sets `IsFirstLogin = 0`
  - Wallet transaction created (if wallet system implemented)

---

#### Step 3: OTP-Based Login (Alternative Flow)
**Endpoint:** `POST /api/auth/otp/send`

**Request:**
```json
{
  "mobile": "9876543210"
}
```

**Backend Processing:**
1. **Lookup:** `usp_Auth_User_GetIdByMobile`
2. **OTP Generation:** 6-digit random number
3. **Storage:** `usp_Auth_OTP_Send`
   - Parameters: @UserId, @OtpCode, @OtpType (2=Mobile), @ExpiresAt (5 min)
4. **Delivery:** Twilio SMS (configured, currently in test mode)
5. **Response:**
```json
{
  "success": true,
  "data": {
    "otpCode": "123456"
  }
}
```

**Verification:** `POST /api/auth/otp/verify`
```json
{
  "mobile": "9876543210",
  "otp": "123456"
}
```

**Backend Processing:**
1. **Validation:** `usp_Auth_OTP_Verify`
   - Checks OTP code matches and hasn't expired
   - Throws SQL error 50005/50006/50007/50008 on failure
2. **JWT Issuance:** Same as login flow
3. **OTP Cleanup:** Marked as used, cannot be reused

---

### **AUTHORIZATION PHASE**

#### JWT Token Validation
**Every protected endpoint** requires Authorization header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Middleware Processing:**
1. Token extraction from header
2. Signature verification using secret key
3. Expiry check (throw 401 if expired)
4. Claims extraction:
   - `ClaimTypes.NameIdentifier` → `CurrentUserId`
   - `ClaimTypes.Role` → Role-based access control

**Controller-Level Authorization:**
```csharp
[Authorize]  // Any authenticated user
[Authorize(Roles = "Seller")]  // Seller only
[Authorize(Roles = "Admin")]  // Admin only
[Authorize(Roles = "Buyer,Seller")]  // Multiple roles
```

---

### **PASSWORD RESET FLOW**

**Endpoint:** `POST /api/auth/forgot-password`

**Request:**
```json
{
  "email": "john@example.com"
}
```

**Backend Processing:**
1. **Lookup:** `usp_Auth_User_ForgotPassword`
   - Returns: UserId, Email, FirstName
   - User NOT found → returns null (anti-enumeration)
2. **OTP Generation:** 6-digit code
3. **Storage:** `usp_Auth_OTP_Send` with @OtpType = 1 (Email)
4. **Email:** Sends OTP via `emailService.SendForgotPasswordOtpAsync()`
5. **Response:** Always returns 200 (prevents user enumeration)

**OTP Verification:** `POST /api/auth/forgot-password/verify-otp`
```json
{
  "userId": 1,
  "otp": "123456"
}
```

**Password Reset:** `POST /api/auth/reset-password`
```json
{
  "userId": 1,
  "newPassword": "NewSecurePass123!"
}
```

**Backend Processing:**
1. Password hashing with new PBKDF2
2. `usp_Auth_User_ResetPassword` updates password hash
3. All active sessions invalidated (JWT tokens still valid until expiry)

---

## ADMIN MODULE

### **Overview**
The Admin module provides comprehensive platform management including seller approvals, product approvals, user management, order oversight, and platform analytics.

### **Admin Dashboard**
**Endpoint:** `GET /api/admin/dashboard`

**Response:**
```json
{
  "success": true,
  "data": {
    "totalUsers": 1250,
    "totalSellers": 48,
    "totalOrders": 5432,
    "totalRevenue": 2500000,
    "pendingSellerApprovals": 12,
    "pendingProductApprovals": 87,
    "lastMonthOrders": 450,
    "lastMonthRevenue": 185000
  }
}
```

**Business Logic:**
- Seller approval tracking
- Product approval pipeline monitoring
- Revenue aggregation by period
- User growth metrics

### **Seller Management**
**Endpoints:**
- `GET /api/admin/sellers?page=1&pageSize=20` - List all sellers with approval status
- `GET /api/admin/sellers/{sellerId}` - Seller details and business verification
- `POST /api/admin/sellers/{sellerId}/approve` - Approve pending seller
- `POST /api/admin/sellers/{sellerId}/reject` - Reject seller with reason
- `POST /api/admin/sellers/{sellerId}/suspend` - Suspend active seller

**Approve Seller Flow:**
**Endpoint:** `POST /api/admin/sellers/{sellerId}/approve`

**Database Operation:** `usp_Admin_Seller_Approve`
- Parameters: @SellerId, @AdminUserId
- Sets seller ApprovalStatus = 1
- Logs admin action in audit table
- Sends approval notification email

**Reject Seller Flow:**
**Endpoint:** `POST /api/admin/sellers/{sellerId}/reject`

**Request:**
```json
{
  "rejectionReason": "Incomplete business verification documents"
}
```

**Database Operation:** `usp_Admin_Seller_Reject`
- Parameters: @SellerId, @AdminUserId, @RejectionReason
- Sets ApprovalStatus = 2
- Stores rejection reason
- Sends rejection email with reason

### **Product Approval Workflow**
**Endpoints:**
- `GET /api/admin/products?approvalStatus=pending&page=1` - List pending products
- `GET /api/admin/products/{productId}` - Product details with seller info
- `POST /api/admin/products/{productId}/approve` - Approve product
- `POST /api/admin/products/{productId}/reject` - Reject product with reason

**Approve Product:**
**Endpoint:** `POST /api/admin/products/{productId}/approve`

**Database Operation:** `usp_Admin_Product_Approve`
- Parameters: @ProductId, @AdminUserId
- Validation:
  - Product exists
  - Current status is "Pending" (ApprovalStatus = 0)
- Sets ApprovalStatus = 1
- Makes product visible in store
- Sends seller notification email

**Reject Product:**
**Request:**
```json
{
  "rejectionReason": "Image quality does not meet standards"
}
```

**Database Operation:** `usp_Admin_Product_Reject`
- Parameters: @ProductId, @AdminUserId, @RejectionReason
- Sets ApprovalStatus = 2
- Hides product from store
- Seller can edit and resubmit
- Sends rejection email with reason

### **User Management**
**Endpoints:**
- `GET /api/admin/users?roleId=3&page=1` - List users by role
- `GET /api/admin/users/{userId}` - User profile and activity

**Features:**
- Filter by role (1=Admin, 2=Seller, 3=Buyer)
- View user registration date
- See last login timestamp
- Track wallet balance and loyalty points
- View user's orders and returns

### **Order Management**
**Endpoints:**
- `GET /api/admin/orders?orderStatus=pending&page=1` - List orders
- `GET /api/admin/orders/{orderId}` - Order details with items and seller breakdown

**Features:**
- Monitor order flow across all sellers
- See payment status verification
- Track delivery progress
- Handle escalated customer issues
- View commission calculations by seller

---

## SELLER MODULE

### **Overview**
Sellers manage products, view orders, update fulfillment status, and track business analytics.

### **Seller Dashboard & Analytics**

**Endpoint:** `GET /api/seller/dashboard`

**Response:**
```json
{
  "success": true,
  "data": {
    "totalProducts": 142,
    "activeProducts": 128,
    "lowStockCount": 8,
    "totalOrders": 542,
    "totalSales": 892345
  }
}
```

**Analytics Endpoint:** `GET /api/seller/analytics?fromDate=2026-05-01&toDate=2026-05-15`

**Response:**
```json
{
  "success": true,
  "data": {
    "fromDate": "2026-05-01",
    "toDate": "2026-05-15",
    "totalRevenue": 125000,
    "totalOrders": 45,
    "totalUnitsSold": 89,
    "averageOrderValue": 2778,
    "newOrders": 15,
    "processingOrders": 20,
    "shippedOrders": 8,
    "deliveredOrders": 35,
    "cancelledOrders": 2
  }
}
```

**Business Logic:**
- Real-time sales tracking
- Order status distribution
- Low-stock alerts for inventory management
- Revenue trends

---

### **Seller Orders Management**

**List Orders Endpoint:** `GET /api/seller/orders?orderStatus=pending&page=1&pageSize=20`

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "orderId": 1,
        "orderNumber": "ORD-20260515-001",
        "status": "Pending",
        "customerName": "John Doe",
        "totalAmount": 5999,
        "createdAt": "2026-05-15T10:30:00Z"
      }
    ],
    "totalCount": 47,
    "pageNo": 1,
    "pageSize": 20
  }
}
```

**Get Order Details:** `GET /api/seller/orders/{orderId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "orderId": 1,
    "orderNumber": "ORD-20260515-001",
    "orderStatus": "Pending",
    "customerName": "John Doe",
    "totalAmount": 5999,
    "address": {
      "line1": "123 Main Street",
      "city": "Mumbai",
      "state": "Maharashtra"
    },
    "items": [
      {
        "productName": "T-Shirt",
        "quantity": 2,
        "unitPrice": 2999
      }
    ]
  }
}
```

---

### **Order Status Update Workflow**

**Endpoint:** `PATCH /api/seller/orders/update/{orderId}/status`

**Request:**
```json
{
  "newStatus": 2
}
```

**Status Codes:**
- 1 = Pending (Initial)
- 2 = Confirmed (Seller accepts)
- 3 = Processing (Being packed)
- 4 = Shipped (In transit)
- 5 = Delivered (Arrived at buyer)
- 6 = Cancelled (By seller)

**Backend Processing:**
1. **Authentication:** Verify seller owns the order items
2. **Validation via SP:** `usp_SellerOrder_UpdateStatus`
   - Only seller who sold items can update
   - Status transitions must be forward-only (1→2→3→4→5)
   - Cannot revert (e.g., 4→2 not allowed)
   - Status 6 (cancel) allowed from any state
3. **Update Operation:**
   - If status = 5 (Delivered): Set DeliveredAt = GETUTCDATE()
   - Update UpdatedAt timestamp
4. **Email Notification:** Fire-and-forget `SendOrderStatusUpdateAsync()`
   - Recipient: Buyer's registered email
   - Template: Dynamic based on status
   - Content: Order number, new status, delivery estimate
5. **Response:**
```json
{
  "success": true,
  "data": {
    "orderId": 1,
    "orderNumber": "ORD-20260515-001",
    "orderStatus": "Confirmed",
    "updatedAt": "2026-05-15T11:00:00Z"
  }
}
```

**Status Update Email Templates:**

**On Status → Confirmed:**
- Subject: "Order #{orderNumber} Confirmed"
- Body:
  - ✓ Order confirmed by seller
  - Expected delivery date
  - "Track My Order" button linking to `/orders/{orderId}`
  - Seller contact info

**On Status → Shipped:**
- Subject: "Order #{orderNumber} Shipped 🚚"
- Body:
  - ✓ Order shipped and in transit
  - Expected delivery date (today + 3-7 days typical)
  - Tracking link
  - Carrier info (if integrated)

**On Status → Delivered:**
- Subject: "Order #{orderNumber} Delivered ✓"
- Body:
  - ✓ Order successfully delivered
  - Delivery timestamp
  - Request for product review
  - Return window notification (15 days)

---

### **Order Cancellation by Seller**

**Endpoint:** `POST /api/seller/orders/{orderId}/cancel`

**Request:**
```json
{
  "cancellationReason": "Item out of stock"
}
```

**Backend Processing:**
1. **Validation via SP:** `usp_Seller_Order_Cancel`
   - Verify seller has items in order
   - Only Pending/Confirmed/Processing orders cancellable
   - Cannot cancel if already Shipped
2. **Database Update:**
   - Set OrderStatus = 6 (Cancelled)
   - Set CancelledAt = GETUTCDATE()
   - Store CancellationReason
3. **Email Notification:** `SendOrderCancellationAsync()`
   - Recipient: Buyer
   - Include cancellation reason
   - If paid online: "Refund will be credited to your wallet"
   - If COD: "No payment needed"
4. **Response:**
```json
{
  "success": true,
  "data": {
    "orderId": 1,
    "orderNumber": "ORD-20260515-001",
    "status": "Cancelled",
    "cancellationReason": "Item out of stock",
    "cancelledAt": "2026-05-15T11:30:00Z"
  }
}
```

**Cancellation Email Template:**
- Subject: "Order #{orderNumber} Cancelled"
- Alert icon + "Order Cancelled" header
- Cancellation reason prominently displayed
- Refund status (if applicable)
- "View My Orders" button
- Return to shop CTA

---

### **Product Management**

**Create Product:**
**Endpoint:** `POST /api/seller/products`

**Request:**
```json
{
  "brandId": 5,
  "categoryId": 10,
  "subCategoryId": 45,
  "productName": "Premium Cotton T-Shirt",
  "slugUrl": "premium-cotton-tshirt",
  "shortDescription": "Soft, breathable cotton",
  "longDescription": "Made from 100% organic cotton...",
  "mrp": 1999,
  "sellingPrice": 1299,
  "costPrice": 600,
  "gstRate": 5,
  "sku": "TSHIRT-001-BLU-M",
  "genderTypeId": 1
}
```

**Approval Status:**
- Created as "Pending" (ApprovalStatus = 0)
- Visible to admin for review
- NOT visible in store until admin approves
- Seller notified of approval/rejection

**Product Variants:**
- Size (S, M, L, XL, XXL)
- Color (e.g., Blue, Red, Black)
- Material, Pattern, Fit Type
- Each variant has separate SKU and stock tracking

---

## BUYER MODULE

### **Overview**
Buyers browse products, manage cart, place orders, track shipments, and interact with customer service.

### **Product Browsing & Search**

**Catalog Endpoint:** `GET /api/products?search=shirt&categoryId=10&minPrice=500&maxPrice=5000&sortBy=LATEST&pageNo=1&pageSize=20`

**Query Parameters:**
- `search`: Free-text search in product name/description
- `categoryId`, `subCategoryId`: Filter by category
- `brandIds`: Comma-separated brand IDs
- `minPrice`, `maxPrice`: Price range filter
- `sortBy`: LATEST, PRICE_ASC, PRICE_DESC, RATING
- `pageNo`, `pageSize`: Pagination (default 20 items)

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "productName": "Premium T-Shirt",
        "brand": "Nike",
        "mrp": 1999,
        "sellingPrice": 1299,
        "discountPercent": 35,
        "rating": 4.5,
        "reviews": 234,
        "primaryImage": "/uploads/products/1.jpg",
        "inStock": true
      }
    ],
    "totalCount": 342,
    "pageNo": 1,
    "pageSize": 20
  }
}
```

**Product Detail:**
**Endpoint:** `GET /api/products/{productId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "productName": "Premium Cotton T-Shirt",
    "brand": "Nike",
    "description": "100% organic cotton...",
    "mrp": 1999,
    "sellingPrice": 1299,
    "discount": 35,
    "rating": 4.5,
    "totalReviews": 234,
    "seller": "Nike Store Official",
    "variants": [
      {
        "id": 1,
        "size": "M",
        "color": "Blue",
        "stock": 45,
        "sku": "TSHIRT-001-BLU-M"
      }
    ],
    "images": [
      {
        "url": "/uploads/products/1.jpg",
        "altText": "Front view",
        "isPrimary": true
      }
    ]
  }
}
```

---

### **Shopping Cart Management**

**Get Cart:** `GET /api/cart`

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "cartId": 1,
        "productId": 10,
        "productName": "T-Shirt",
        "brand": "Nike",
        "size": "M",
        "color": "Blue",
        "quantity": 2,
        "mrp": 1999,
        "sellingPrice": 1299,
        "discountPercent": 35,
        "itemMrp": 3998,
        "itemTotal": 2598,
        "imageUrl": "/uploads/products/10.jpg"
      }
    ],
    "summary": {
      "totalMrp": 3998,
      "totalDiscount": 1400,
      "deliveryCharge": 49,
      "finalAmount": 2647
    }
  }
}
```

**Add to Cart:** `POST /api/cart`

**Request:**
```json
{
  "productId": 10,
  "sizeLabel": "M",
  "colorName": "Blue",
  "quantity": 2
}
```

**Backend Logic:**
- Variant lookup by product, size, color
- Stock validation (quantity available)
- If item already in cart: update quantity
- If new item: create cart entry

**Update Quantity:** `PATCH /api/cart/{cartId}`

**Request:**
```json
{
  "quantity": 3
}
```

**Delete Item:** `DELETE /api/cart/{cartId}`

---

### **Checkout & Order Placement**

**Place Order:** `POST /api/orders`

**Request:**
```json
{
  "addressId": 5,
  "paymentMethod": "COD",
  "couponCode": "SAVE50"
}
```

**Backend Processing - 3 Step Validation:**

1. **User Validation:**
   - User is authenticated
   - Address belongs to user
   - Address exists and is not deleted

2. **Cart Validation:**
   - Cart has items
   - All items in stock
   - Prices match current product prices
   - No deleted products in cart

3. **Coupon Validation (if provided):**
   - Coupon exists and is active
   - Coupon not expired
   - User hasn't exceeded usage limit
   - Order total meets minimum purchase requirement

**Order Creation via SP:** `usp_Commerce_Order_Place`
- Parameters:
  - @UserId, @ShippingAddressId
  - @PaymentMode (1=COD, 2=Online, 3=Wallet)
  - @CouponCode (optional)
- Operations:
  - Create Orders record
  - Create OrderItems for each cart item
  - Deduct stock from ProductVariants
  - Clear user's cart
  - Set ExpectedDeliveryDate = TODAY + 5 days (configurable)
- Returns: @OrderId

**Email Notification (Fire-and-Forget):**
- `SendOrderConfirmationAsync()` called after order creation
- Does NOT block API response
- If email fails: logged, order still created

**Order Confirmation Email Template:**
- Subject: "Order Confirmed! #{orderNumber} — Stop-N-Shop"
- ✓ Success checkmark icon
- "Congratulations, {Name}! 🎉"
- Order ID, date, total amount
- "Track My Order →" button linking to `/orders/{orderId}`
- Expected delivery date
- What's next (payment instructions for COD)

**Response:**
```json
{
  "success": true,
  "data": {
    "orderId": 542,
    "orderNumber": "ORD-20260515-542"
  }
}
```

---

### **Order Tracking & History**

**Get My Orders:** `GET /api/orders`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 542,
      "orderNumber": "ORD-20260515-542",
      "status": "Confirmed",
      "totalAmount": 5999,
      "paymentMethod": "COD",
      "createdAt": "2026-05-15T10:30:00Z",
      "itemCount": 2,
      "primaryImage": "/uploads/products/10.jpg"
    }
  ]
}
```

**Get Order Details:** `GET /api/orders/{orderId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 542,
    "orderNumber": "ORD-20260515-542",
    "status": "Shipped",
    "paymentMethod": "COD",
    "paymentStatus": "Pending",
    "createdAt": "2026-05-15T10:30:00Z",
    "address": {
      "name": "John Doe",
      "mobile": "9876543210",
      "line1": "123 Main Street",
      "line2": "Apt 4B",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pincode": "400001"
    },
    "summary": {
      "totalMrp": 9998,
      "totalDiscount": 2800,
      "couponDiscount": 500,
      "couponCode": "SAVE50",
      "deliveryCharge": 0,
      "finalAmount": 6698
    },
    "items": [
      {
        "id": 1,
        "productId": 10,
        "productName": "Premium T-Shirt",
        "brand": "Nike",
        "imageUrl": "/uploads/products/10.jpg",
        "size": "M",
        "color": "Blue",
        "quantity": 2,
        "sellingPrice": 1299
      }
    ],
    "tracking": [
      {
        "status": "Confirmed",
        "description": "Your order has been confirmed",
        "createdAt": "2026-05-15T11:00:00Z"
      },
      {
        "status": "Shipped",
        "description": "Your order is on the way",
        "createdAt": "2026-05-16T08:30:00Z"
      }
    ]
  }
}
```

---

### **Order Cancellation by Buyer**

**Endpoint:** `DELETE /api/orders/{orderId}`

**Request:**
```json
{
  "reason": "Change color/size"
}
```

**Validation via SP:** `usp_Order_CancelByBuyer`
- User owns the order
- Order status is Pending (1) or Confirmed (2)
- Cannot cancel after seller has processed

**Backend Processing:**
1. Set OrderStatus = 6 (Cancelled)
2. Set CancelledAt = GETUTCDATE()
3. Store CancellationReason
4. Send email: `SendOrderCancellationAsync()`
5. If refundable (online payment): Credit wallet
6. Restore product stock in ProductVariants

**Cancellation Email Template:**
- Subject: "Order #{orderNumber} Cancelled"
- Red alert: "Order Cancelled"
- Cancellation reason shown
- "Refund will be credited to your wallet in 3-5 business days"
- "View My Orders" button

---

## API ENDPOINTS REFERENCE

### **Authentication Endpoints**
```
POST   /api/auth/buyer/register          Register new buyer
POST   /api/auth/buyer/login             Login with email/password
POST   /api/auth/otp/send                Send OTP to mobile
POST   /api/auth/otp/verify              Verify OTP and login
POST   /api/auth/forgot-password         Initiate password reset
POST   /api/auth/forgot-password/verify-otp  Verify reset OTP
POST   /api/auth/reset-password          Reset password
POST   /api/auth/mark-first-login-complete   Mark first login done
GET    /api/auth/profile                 Get user profile
PUT    /api/auth/profile                 Update user profile
```

### **Orders Endpoints (Buyer)**
```
POST   /api/orders                       Place order
GET    /api/orders                       List user's orders
GET    /api/orders/{id}                  Get order details
DELETE /api/orders/{id}                  Cancel order (buyer)
```

### **Orders Endpoints (Seller)**
```
GET    /api/seller/orders                List seller's orders
GET    /api/seller/orders/{id}           Get order details
PATCH  /api/seller/orders/update/{id}/status  Update order status
POST   /api/seller/orders/{id}/cancel    Cancel order (seller)
```

### **Products Endpoints**
```
GET    /api/products                     Search/list products
GET    /api/products/{id}                Get product details
GET    /api/categories                   Get all categories
GET    /api/categories/{id}/subcategories Get subcategories
GET    /api/brands                       Get all brands
```

### **Cart Endpoints**
```
GET    /api/cart                         Get user's cart
POST   /api/cart                         Add item to cart
PATCH  /api/cart/{id}                    Update cart item quantity
DELETE /api/cart/{id}                    Remove item from cart
```

### **Seller Endpoints**
```
GET    /api/seller/dashboard             Get dashboard stats
GET    /api/seller/analytics             Get analytics
GET    /api/seller/products              List seller's products
POST   /api/seller/products              Create new product
PUT    /api/seller/products/{id}         Update product
DELETE /api/seller/products/{id}         Delete product
```

### **Admin Endpoints**
```
GET    /api/admin/dashboard              Admin dashboard
GET    /api/admin/sellers                List sellers
POST   /api/admin/sellers/{id}/approve   Approve seller
POST   /api/admin/sellers/{id}/reject    Reject seller
GET    /api/admin/products               List products (pending/approved)
POST   /api/admin/products/{id}/approve  Approve product
POST   /api/admin/products/{id}/reject   Reject product
GET    /api/admin/users                  List users
GET    /api/admin/orders                 List all orders
```

---

## EMAIL NOTIFICATION SYSTEM

### **Email Service Architecture**

**Service Class:** `EmailService.cs`
- **SMTP Provider:** Office365 (smtp.office365.com:587)
- **Authentication:** SSL/TLS encryption required
- **From Email:** notification@prakashinfotech.com
- **Sender Name:** Stop-N-Shop

**Configuration (appsettings.json):**
```json
{
  "Smtp": {
    "Host": "smtp.office365.com",
    "Port": "587",
    "EnableSsl": true,
    "User": "notification@prakashinfotech.com",
    "Password": "<secured-password>",
    "FromEmail": "notification@prakashinfotech.com",
    "FromName": "Stop-N-Shop",
    "ToEmail": "dolly@prakashinfotech.com"
  }
}
```

### **Email Sending Pattern**

All emails follow **fire-and-forget** pattern:
```csharp
_ = Task.Run(async () => {
    try {
        await emailService.SendOrderConfirmationAsync(...);
    }
    catch (Exception ex) {
        logger.LogError(ex, "Email sending failed");
        // Never blocks main request
    }
});
```

**Rationale:**
- Email delays don't impact API response time
- Email failures don't break order creation
- Async, non-blocking improves throughput

### **Email Templates**

#### 1. **Order Confirmation Email**
**Trigger:** Immediately after order creation
**Template:** `BuildHtmlBody()` in EmailService
**Content:**
- Success checkmark (✓) icon in green circle
- "Congratulations, {Name}! 🎉"
- "Your order has been placed successfully"
- Order summary table:
  - Order ID: #{orderNumber}
  - Total Amount: ₹{amount}
  - Status: PLACED badge
- "Track My Order →" button (links to `/orders/{orderId}`)
- Footer: "Thank you for shopping with Stop-N-Shop"

#### 2. **Order Status Update Email**
**Trigger:** When seller updates order status
**Template:** `BuildStatusUpdateHtmlBody()` in EmailService
**Variable by Status:**

**Status = Confirmed:**
- Header: "Order Confirmed, {Name}!"
- Icon: ✓ (green checkmark)
- Message: "Your order has been confirmed by the seller"
- Details: Expected delivery date

**Status = Processing:**
- Header: "Order Being Prepared"
- Icon: 📦 (package)
- Message: "Your order is being carefully packed"

**Status = Shipped:**
- Header: "Order Shipped 🚚"
- Icon: 🚚 (truck)
- Message: "Your order is on the way"
- Includes delivery estimate

**Status = Delivered:**
- Header: "Order Delivered ✓"
- Icon: ✓ (green check)
- Message: "Your order has been successfully delivered"
- Delivery timestamp
- CTA: "Rate this product" (review modal)

#### 3. **Order Cancellation Email**
**Trigger:** When order is cancelled (by buyer or seller)
**Template:** `BuildCancellationHtmlBody()` in EmailService
**Content:**
- Red alert icon (✕)
- "Order Cancelled, {Name}"
- Cancellation reason (if provided)
- Refund status:
  - If COD: "No payment required"
  - If Online Payment: "Refund will be credited to wallet in 3-5 days"
- "View My Orders" button
- Footer message about return policy

#### 4. **Forgot Password OTP Email**
**Trigger:** User initiates forgot password
**Template:** `BuildOtpEmailBody()` in EmailService
**Content:**
- Key icon (🔑) in gold circle
- "Here's your reset code"
- 6-digit OTP in large monospace font
- "This code expires in 10 minutes"
- Security notice: "If you didn't request this, ignore"

### **Email Delivery Guarantees**

**Non-Critical Path:** Emails are NOT critical to order flow
- Email failure doesn't prevent order creation
- Failed emails are logged for manual retry
- Retry mechanism: Can be implemented in background job

**Monitoring:**
- Serilog logs all email send attempts
- Success rate tracked
- Failed recipient list maintained

---

## ERROR HANDLING & VALIDATION

### **Global Exception Handling**

**Middleware:** `ExceptionMiddleware.cs`
- Catches all unhandled exceptions
- Converts to standardized ApiResponse format
- Never exposes stack traces to client
- Logs full exception via Serilog

**Standard Error Response:**
```json
{
  "success": false,
  "message": "An unexpected error occurred",
  "data": null
}
```

### **HTTP Status Codes**

| Code | Meaning | Example |
|------|---------|---------|
| 200 | Success | Order placed successfully |
| 400 | Bad Request | Invalid email format |
| 401 | Unauthorized | Missing/invalid JWT token |
| 403 | Forbidden | Seller accessing admin endpoint |
| 404 | Not Found | Order doesn't exist |
| 409 | Conflict | Email already registered |
| 422 | Unprocessable Entity | Validation failed |
| 500 | Server Error | Unexpected exception |

### **Validation Rules**

**Email:**
- RFC 5322 format required
- Must be unique in Users table
- Case-insensitive duplicate check

**Password:**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character (!@#$%^&*)

**Mobile Number:**
- Exactly 10 digits
- India phone numbers
- Must be unique in Users table

**Product Price:**
- MRP ≥ SellingPrice
- SellingPrice ≥ CostPrice
- All positive decimal values

**Coupon:**
- MinOrderValue ≤ OrderSubTotal
- Current date between StartDate and EndDate
- UsageCount < UsageLimit

---

## SECURITY MEASURES

### **Password Security**
- **Algorithm:** PBKDF2-SHA256
- **Iterations:** 100,000
- **Salt Length:** 16 bytes
- **Output Length:** 32 bytes
- **Format:** "{Base64Salt}:{Base64Hash}"

### **JWT Security**
- **Algorithm:** HS256 (HMAC SHA256)
- **Secret:** 256-bit key from appsettings
- **Expiry:** 30 days
- **Claims Verified:** Signature, expiry, not-before time
- **Token Rotation:** Not implemented (30-day expiry sufficient)

### **Database Security**
- **Connections:** SSL/TLS encrypted
- **Credentials:** Managed via Azure Key Vault (production)
- **SQL Injection:** Prevented via parameterized queries (Dapper)
- **Privilege:** Minimal database user with only EXECUTE permission on SPs

### **API Security**
- **CORS:** Configured for localhost:3000 (dev)
- **HTTPS:** Required for production
- **Rate Limiting:** Not implemented (can be added via middleware)
- **Input Validation:** Via FluentValidation on all request DTOs

---

## CONCLUSION

Stop-N-Shop is a comprehensive, multi-role e-commerce platform built on modern architectural principles:

✓ **Layered Architecture:** Separation of concerns (Controllers → Services → Repositories)
✓ **Database-Driven:** All transactions via stored procedures, zero inline SQL
✓ **Async-First:** All I/O operations non-blocking
✓ **Fire-and-Forget Notifications:** Emails don't delay order flow
✓ **Role-Based Security:** Distinct admin/seller/buyer authorization
✓ **JWT Authentication:** Stateless, scalable token-based auth
✓ **Email Notifications:** HTML templates for all user-facing transactions
✓ **Comprehensive Validation:** Input/business logic validation at service layer
✓ **Error Handling:** Standardized responses with logging

The platform supports end-to-end workflows from user registration through order delivery, with clear separation between admin oversight, seller operations, and buyer shopping experience.

