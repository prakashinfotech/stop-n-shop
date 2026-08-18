# Database Architecture — ShopNStopDB

## Connection
- **Engine:** SQL Server Express (`SQLEXPRESS01`)
- **Database:** `ShopNShop_db`
- **Connection string key in API:** `DefaultConnection` in `appsettings.json`
- **Project type:** SSDT (SQL Server Data Tools) — `.sqlproj`

## Table Inventory (34 tables)
### Users & Auth
| Table | Purpose |
|---|---|
| `Users` | Customer accounts (email, phone, bcrypt password, role FK) |
| `Roles` | Role lookup (Customer, Seller, Admin) |
| `OtpVerifications` | OTP codes for email/phone login |
| `RefreshTokens` | JWT refresh token store |
| `UserAddresses` | Delivery addresses per user |

### Sellers
| Table | Purpose |
|---|---|
| `Sellers` | Seller accounts (businessName, GST, `isApproved`, `isActive`) |
| `SellerDocuments` | KYC document uploads |
| `SellerBrandMappings` | Which brands a seller can sell |
| `SellerAnalyticsDaily` | Daily sales/revenue snapshots per seller |

### Products & Catalogue
| Table | Purpose |
|---|---|
| `Products` | Core product (name, mrp, sellingPrice, sellerId, `isApproved`) |
| `ProductImages` | Product image URLs (isPrimary, sortOrder) |
| `ProductVariants` | Size/color variants per product |
| `ProductSpecifications` | Key-value specs per product |
| `ProductViewLogs` | View tracking for analytics |
| `PriceHistory` | Price change audit trail |
| `Categories` | Top-level category (Men, Women, Kids…) |
| `SubCategories` | Sub under category (T-Shirts, Jeans…) |
| `Brands` | Brand master (name, logoUrl) |
| `GenderTypes` | M/F/U/K gender type lookup |

### Commerce
| Table | Purpose |
|---|---|
| `Cart` | User cart items (userId, productId, variantId, qty) |
| `Orders` | Order header (userId, status, totalAmount, paymentStatus) |
| `OrderItems` | Line items per order |
| `Wishlist` | User wishlist (userId, productId) |
| `Coupons` | Discount codes |
| `Offers` | Product/category offers |

### Content & Misc
| Table | Purpose |
|---|---|
| `Banners` | Hero/promo banner images |
| `HomeSections` | Homepage section config |
| `FooterContent` | Footer links/content CMS |
| `Notifications` | User notification records |
| `RecentlyViewed` | User browsing history |
| `SearchLogs` | Search term tracking |
| `Reviews` | Product reviews (userId, productId, rating) |
| `ReviewImages` | Images attached to reviews |
| `AuditLogs` | System-wide audit trail |

## Stored Procedure Inventory (86 SPs)
### Naming Conventions
| Prefix | Domain |
|---|---|
| `usp_Auth_*` | Customer auth, OTP, addresses, profile |
| `sp_Seller*` | Seller auth/profile (older naming) |
| `usp_Seller_*` | Seller onboarding (newer naming) |
| `usp_Product_*` | Public product operations |
| `usp_SellerProduct_*` | Seller product management |
| `usp_Cart_*` | Cart operations |
| `usp_Order_*` | Order create/update/list |
| `usp_Catalogue_*` | Categories, brands, filters |
| `usp_Wishlist_*` | Wishlist operations |
| `usp_Admin_*` | Admin approve/reject/list |
| `usp_CMS_*` | Banners, homepage content |
| `usp_Notification_*` | Notification delivery |

### Key SP Examples
| SP | Purpose |
|---|---|
| `usp_Auth_User_Register` | Create user account |
| `usp_Auth_OTP_Send` | Generate and store OTP |
| `usp_Auth_OTP_Verify` | Validate OTP, return user |
| `sp_SellerSignup` | Create seller account |
| `sp_SellerCompleteOnboarding` | Mark onboarding done |
| `usp_Admin_Seller_Approve` | Admin approves seller |
| `usp_Admin_Product_Approve` | Admin approves product |
| `usp_Product_GetList` | Paginated public product list |

## Key Business Rules (enforced at DB level)
- Products have `isApproved` — only admin-approved products show publicly.
- Sellers have `isApproved` + `isActive` — unapproved sellers cannot list products.
- Cart ties to `userId` + `productId` + `variantId` — variant-level line items.
- Orders use status enum: `PENDING → CONFIRMED → SHIPPED → DELIVERED → CANCELLED`.

## Adding a New SP
1. Create file in `ShopNStopDB/dbo/StoredProcedures/` following naming convention.
2. Use `CREATE OR ALTER PROCEDURE` pattern.
3. Add corresponding repository method in `api/Repositories/`.
4. Never write inline SQL in the API — always call the SP.
