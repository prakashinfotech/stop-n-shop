# StopNShopDB — SQL Server Database Project

Enterprise-grade SQL Server Database Project for the **StopNShop** multi-brand e-commerce platform.

## Tech Stack
| Component | Version |
|-----------|---------|
| SQL Server | 2022 (DSP160) |
| SSDT SDK | `Microsoft.Build.Sql` 0.1.20 |
| .NET SDK | 8.x (for CLI build) |
| Deployment | DACPAC via `sqlpackage` |

## Project Structure
```
StopNShopDB/
├── .github/workflows/ci-cd.yml     GitHub Actions CI/CD
├── ShellScripts/                   Reserved helper scripts
├── Storage/
│   └── Catalogs.sql                Full-text catalog definition
├── dbo/
│   ├── Data/                       Seed scripts (excluded from model)
│   ├── Functions/                  Scalar/table-valued functions
│   ├── StoredProcedures/           All usp_* stored procedures
│   ├── Tables/                     One CREATE TABLE per file
│   ├── Triggers/                   Audit + UpdatedAt triggers
│   └── Views/                      Reporting views
├── Script.PostDeployment.sql       Seeds run after every deploy
├── StopNShop.sqlproj               SDK-style project file
├── BuildProject.bat                Local build + deploy helper
└── README.md
```

## Prerequisites
- [.NET 8 SDK](https://dotnet.microsoft.com/download)
- [sqlpackage CLI](https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage): `dotnet tool install -g microsoft.sqlpackage`
- SQL Server 2019/2022 instance

## Build

```bat
BuildProject.bat
```

Output: `bin\Release\StopNShopDB.dacpac`

## Deploy

```bat
BuildProject.bat --deploy <ServerName> [<DatabaseName>]
```

Example (local default instance):
```bat
BuildProject.bat --deploy . StopNShopDB
```

Example (named instance):
```bat
BuildProject.bat --deploy ".\SQLEXPRESS" StopNShopDB
```

## CI/CD (GitHub Actions)
| Branch | Action |
|--------|--------|
| `develop` → push | Build + deploy to **Staging** |
| `main` → push | Build + deploy to **Production** |
| PR → `main` | Build only (no deploy) |

Add these secrets to your GitHub repository:
- `STAGING_SQL_CONN` — ADO.NET connection string for staging
- `PROD_SQL_CONN` — ADO.NET connection string for production

## Domains

| # | Domain | Key Tables |
|---|--------|-----------|
| 1 | Identity & Auth | Users, Roles, OtpVerifications, UserAddresses, RefreshTokens |
| 2 | Seller & Brand | Sellers, Brands, SellerDocuments, SellerBrandMappings |
| 3 | Catalog | Products, ProductVariants, Categories, SubCategories, ProductImages |
| 4 | Pricing | Offers, Coupons, PriceHistory |
| 5 | Commerce | Orders, OrderItems, Cart, Wishlist |
| 6 | Engagement | Reviews, ReviewImages, RecentlyViewed |
| 7 | CMS | Banners, HomeSections, FooterContent |
| 8 | Analytics | ProductViewLogs, SearchLogs, SellerAnalyticsDaily |
| 9 | Audit & Notifications | AuditLogs, Notifications |

## Conventions
- **Stored procedures:** `usp_[Domain]_[Entity]_[Action]`
- **Primary keys:** `[TableName]Id INT IDENTITY(1,1)` (TINYINT for lookups)
- **Currency:** `DECIMAL(18,2)` — never FLOAT or MONEY
- **Text:** Always `NVARCHAR` — never `VARCHAR`
- **Deletes:** Soft-delete via `IsDeleted = 1` — no hard DELETEs on business tables
- **Audit:** Every business table has `CreatedAt`, `UpdatedAt`, `CreatedBy`, `UpdatedBy`, `IsActive`, `IsDeleted`

END of file
