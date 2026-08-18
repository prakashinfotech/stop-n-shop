# Auth & Identity — Endpoint Checklist

> Phase 1 — Foundation: Auth & Identity  
> Base URL: `http://localhost:5000/api`  
> All responses use `ApiResponse<T>`: `{ success, message, data, errors }`

---

## Buyer Auth

### POST `/api/auth/buyer/register`
> SP: `usp_Auth_User_Register`  
> Status: ✅ Implemented

**Request**
```json
{
  "firstName": "Rahul",
  "lastName":  "Sharma",
  "email":     "rahul@example.com",
  "mobile":    "9876543210",
  "password":  "StrongPass@123"
}
```

**Response 200**
```json
{
  "success": true,
  "message": "Account created successfully.",
  "data": {
    "token":     "<jwt>",
    "expiresAt": "2026-06-11T00:00:00Z",
    "user": {
      "id":        1,
      "email":     "rahul@example.com",
      "mobile":    "9876543210",
      "firstName": "Rahul",
      "lastName":  "Sharma",
      "role":      "Customer",
      "createdAt": "2026-05-12T10:00:00Z"
    }
  }
}
```

**Response 409** — email or mobile already registered  
**Response 400** — missing fields or password < 8 chars

---

### POST `/api/auth/buyer/login`
> SP: `usp_Auth_User_Login`  
> Status: ✅ Implemented

**Request**
```json
{
  "email":    "rahul@example.com",
  "password": "StrongPass@123"
}
```

**Response 200**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token":     "<jwt>",
    "expiresAt": "2026-06-11T00:00:00Z",
    "user": {
      "id":        1,
      "email":     "rahul@example.com",
      "mobile":    "9876543210",
      "firstName": "Rahul",
      "lastName":  "Sharma",
      "role":      "Customer",
      "createdAt": "2026-05-12T10:00:00Z"
    }
  }
}
```

**Response 401** — invalid credentials  
**Response 400** — missing email or password

---

### POST `/api/auth/otp/send`
> SP: `usp_Auth_User_GetIdByMobile` → `usp_Auth_OTP_Send`  
> Status: ✅ Implemented  
> ⚠️ Requires `usp_Auth_User_GetIdByMobile` to be deployed to DB

**Request**
```json
{ "mobile": "9876543210" }
```

**Response 200**
```json
{ "success": true, "message": "OTP sent successfully.", "data": null }
```

**Response 404** — mobile not registered  
**Response 400** — invalid mobile format

---

### POST `/api/auth/otp/verify`
> SP: `usp_Auth_User_GetIdByMobile` → `usp_Auth_OTP_Verify`  
> Status: ✅ Implemented  
> ⚠️ Requires `usp_Auth_User_GetIdByMobile` to be deployed to DB

**Request**
```json
{ "mobile": "9876543210", "otp": "123456" }
```

**Response 200**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": { "token": "<jwt>", "expiresAt": "...", "user": { ... } }
}
```

**Response 401** — OTP invalid, expired, or max attempts exceeded

---

### POST `/api/auth/forgot-password`
> SP: `usp_Auth_User_ForgotPassword`  
> Status: ✅ Implemented  
> Note: Always returns 200 (prevents user enumeration). No email is actually sent yet — the userId is returned only in logs; a real token flow should be added.

**Request**
```json
{ "email": "rahul@example.com" }
```

**Response 200**
```json
{ "success": true, "message": "If an account exists, a reset link has been sent.", "data": null }
```

**Response 400** — missing email

---

### POST `/api/auth/reset-password`
> SP: `usp_Auth_User_ResetPassword`  
> Status: ✅ Implemented  
> Note: Accepts `userId` directly (evaluation scope — production would use a signed token).

**Request**
```json
{ "userId": 1, "newPassword": "NewPass@456" }
```

**Response 200**
```json
{ "success": true, "message": "Password reset successfully.", "data": null }
```

**Response 400** — missing fields, password < 8 chars, or user not found

---

## Seller Auth

### POST `/api/seller/auth/signup`
> SP: `sp_SellerSignup`  
> Status: ✅ Implemented

**Request**
```json
{
  "email":           "seller@brand.com",
  "phoneNumber":     "9123456789",
  "password":        "SellerPass@1",
  "confirmPassword": "SellerPass@1"
}
```

**Response 200**
```json
{
  "success": true,
  "message": "Seller registered. OTPs generated.",
  "data": {
    "sellerId": 5,
    "email":    "seller@brand.com"
  }
}
```

**Response 400** — passwords don't match, email exists, or missing fields

---

### POST `/api/seller/auth/login`
> SP: `sp_SellerLogin`  
> Status: ✅ Implemented

**Request**
```json
{ "email": "seller@brand.com", "password": "SellerPass@1" }
```

**Response 200**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token":     "<jwt>",
    "expiresAt": "2026-06-11T00:00:00Z",
    "seller": {
      "id":                 5,
      "email":              "seller@brand.com",
      "businessName":       "My Brand",
      "onboardingCompleted": false,
      "isApproved":         false
    }
  }
}
```

**Response 401** — invalid credentials

---

## Protected Endpoints (require `Authorization: Bearer <token>`)

| Method | Path | Role | SP | Status |
|--------|------|------|----|--------|
| GET | `/api/auth/profile` | Customer | `usp_Auth_User_GetProfile` | ✅ |
| GET | `/api/auth/me` | Customer | `usp_Auth_User_GetProfile` | ✅ |
| PUT | `/api/auth/profile` | Customer | `usp_Auth_User_UpdateProfile` | ✅ |
| GET | `/api/seller/auth/profile` | Seller | `sp_SellerGetProfile` | ✅ |
| PUT | `/api/seller/auth/profile` | Seller | `sp_SellerUpdateProfile` | ✅ |
| POST | `/api/seller/auth/onboarding` | Seller | `sp_SellerCompleteOnboarding` | ✅ |

---

## Checklist

| Endpoint | SP exists? | C# wired? | UI wired? | Tested? |
|----------|-----------|-----------|-----------|---------|
| `POST /auth/buyer/register` | ✅ | ✅ | ✅ | ⬜ |
| `POST /auth/buyer/login` | ✅ | ✅ | ✅ | ⬜ |
| `POST /auth/otp/send` | ✅ (needs GetIdByMobile deployed) | ✅ | ✅ | ⬜ |
| `POST /auth/otp/verify` | ✅ (needs GetIdByMobile deployed) | ✅ | ✅ | ⬜ |
| `POST /auth/forgot-password` | ✅ | ✅ | ✅ | ⬜ |
| `POST /auth/reset-password` | ✅ | ✅ | ✅ | ⬜ |
| `POST /seller/auth/signup` | ✅ | ✅ | ✅ | ⬜ |
| `POST /seller/auth/login` | ✅ | ✅ | ✅ | ⬜ |
| `GET /auth/profile` | ✅ | ✅ | ✅ | ⬜ |
| `PUT /auth/profile` | ✅ | ✅ | ✅ | ⬜ |
| `GET /seller/auth/profile` | ✅ | ✅ | ✅ | ⬜ |
| `PUT /seller/auth/profile` | ✅ | ✅ | ✅ | ⬜ |
| `POST /seller/auth/onboarding` | ✅ | ✅ | ✅ | ⬜ |

---

## Legacy Route Aliases (still work)
| Old path | New path |
|----------|----------|
| `POST /auth/signup` | `POST /auth/buyer/register` |
| `POST /auth/login` | `POST /auth/buyer/login` |
| `POST /auth/send-otp` | `POST /auth/otp/send` |
| `POST /auth/verify-otp` | `POST /auth/otp/verify` |

---

## DB Deployment Required

Run the following SP in SSMS on `Server=localhost\SQLEXPRESS01;Database=ShopNShop_db`:

```
ShopNStopDB/dbo/StoredProcedures/usp_Auth_User_GetIdByMobile.sql
```

This is required for OTP send/verify to work. All other auth SPs already exist in the DB.
