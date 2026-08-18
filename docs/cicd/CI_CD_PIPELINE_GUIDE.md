# CI/CD Pipeline Setup Guide

## Overview

This document describes the complete CI/CD pipeline for the StopNShop project. The pipeline automatically builds, tests, and deploys changes to the database, API, and UI whenever code is pushed to the repository.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  (main branch = production, develop branch = staging)        │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   Database      API          UI
   Workflow      Workflow     Workflow
        │            │            │
        ▼            ▼            ▼
   Validate    Build & Test  Build & Test
   Schema      Run Tests     Run Linter
        │            │            │
        ▼            ▼            ▼
   Deploy to   Deploy to    Deploy to
   Dev/Prod    Dev/Prod     Dev/Prod
```

---

## Workflows

### 1. Database Deployment Workflow

**File:** `.github/workflows/database-deploy.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Changes in `ShopNStopDB/` or `db/scripts/` directories

**Steps:**
1. **Validate Database Schema**
   - Checks out code
   - Restores NuGet packages
   - Builds database project
   - Validates SQL syntax (ensures no `CREATE OR ALTER` in SSDT files)

2. **Deploy Database Changes**
   - Builds database project
   - Generates deployment script
   - Deploys to development (on `develop` branch)
   - Deploys to production (on `main` branch)

**Database Project Structure:**
```
ShopNStopDB/
├── dbo/
│   ├── Tables/
│   │   └── *.sql (CREATE TABLE statements)
│   ├── Stored Procedures/
│   │   └── *.sql (CREATE PROCEDURE statements)
│   ├── Views/
│   │   └── *.sql
│   └── Functions/
│       └── *.sql
└── ShopNStopDB.sqlproj
```

**Important:** All stored procedures in the database project must use `CREATE PROCEDURE` (not `CREATE OR ALTER PROCEDURE`) for SSDT compatibility.

---

### 2. API Deployment Workflow

**File:** `.github/workflows/api-deploy.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Changes in `api/` directory

**Steps:**
1. **Build API**
   - Checks out code
   - Sets up .NET 8.0
   - Restores dependencies
   - Builds project
   - Runs tests
   - Publishes release build

2. **Deploy to Development** (on `develop` branch)
   - Publishes API
   - Copies files to development server

3. **Deploy to Production** (on `main` branch)
   - Publishes API
   - Copies files to production server
   - Restarts API service

---

### 3. UI Deployment Workflow

**File:** `.github/workflows/ui-deploy.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Changes in `stopnshop-ui/` directory

**Steps:**
1. **Build UI**
   - Checks out code
   - Sets up Node.js 18
   - Installs dependencies
   - Runs linter
   - Runs tests
   - Builds production bundle

2. **Deploy to Development** (on `develop` branch)
   - Downloads build artifacts
   - Deploys to development server

3. **Deploy to Production** (on `main` branch)
   - Downloads build artifacts
   - Deploys to production server
   - Invalidates CDN cache

---

## Setup Instructions

### Step 1: Configure GitHub Secrets

Add the following secrets to your GitHub repository settings:

**For Database Deployment:**
```
DEV_DB_CONNECTION_STRING
PROD_DB_CONNECTION_STRING
PROD_DB_SERVER
PROD_DB_USER
PROD_DB_PASSWORD
```

**For API Deployment:**
```
DEV_API_PATH
PROD_API_PATH
```

**For UI Deployment:**
```
CLOUDFRONT_DIST_ID (optional, for CDN invalidation)
```

### Step 2: Configure Branch Protection Rules

1. Go to Repository Settings → Branches
2. Add protection rule for `main` branch:
   - Require status checks to pass before merging
   - Require all workflows to pass:
     - Database Deployment
     - API Deployment
     - UI Deployment

### Step 3: Set Up Deployment Servers

**Development Server:**
- Create directories for API and UI
- Set up IIS or similar web server
- Configure database connection

**Production Server:**
- Create directories for API and UI
- Set up IIS or similar web server
- Configure database connection
- Set up SSL certificates
- Configure CDN (optional)

### Step 4: Configure Local Development

**For Database Changes:**
```bash
# Make changes to ShopNStopDB project
# Commit and push to develop branch
git add ShopNStopDB/
git commit -m "Update database schema"
git push origin develop
```

**For API Changes:**
```bash
# Make changes to api/
# Commit and push to develop branch
git add api/
git commit -m "Update API endpoint"
git push origin develop
```

**For UI Changes:**
```bash
# Make changes to stopnshop-ui/
# Commit and push to develop branch
git add stopnshop-ui/
git commit -m "Update UI component"
git push origin develop
```

---

## Database Deployment Details

### Important: SSDT Syntax Rules

The database project uses SQL Server Data Tools (SSDT) which has specific requirements:

**✅ Correct Syntax (for SSDT):**
```sql
CREATE PROCEDURE [dbo].[sp_GetProducts]
    @CategoryId INT = NULL
AS
BEGIN
    -- Procedure body
END
```

**❌ Incorrect Syntax (for SSDT):**
```sql
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProducts]
    @CategoryId INT = NULL
AS
BEGIN
    -- Procedure body
END
```

### Script Files vs Database Project

**Script Files** (`db/scripts/`):
- Used for manual deployments
- Can use `CREATE OR ALTER PROCEDURE`
- Used for initial database setup

**Database Project** (`ShopNStopDB/`):
- Used for automated deployments via CI/CD
- Must use `CREATE PROCEDURE`
- Generates deployment scripts automatically
- Tracks schema changes in version control

### Deployment Process

1. **Local Development:**
   - Make changes to database project
   - Build project to validate syntax
   - Commit changes

2. **CI/CD Pipeline:**
   - Validates schema
   - Generates deployment script
   - Deploys to target environment
   - Logs deployment results

3. **Rollback (if needed):**
   - Revert commit
   - Push to trigger new deployment
   - Previous schema is restored

---

## Monitoring and Troubleshooting

### View Workflow Status

1. Go to GitHub repository
2. Click "Actions" tab
3. Select workflow to view details
4. Check logs for any errors

### Common Issues

**Issue: Database deployment fails with syntax error**
- Solution: Ensure all SPs use `CREATE PROCEDURE` (not `CREATE OR ALTER`)
- Run: `scripts/fix-sp-syntax.ps1` to auto-fix

**Issue: API deployment fails**
- Check .NET version compatibility
- Verify connection strings in appsettings
- Check deployment server permissions

**Issue: UI deployment fails**
- Check Node.js version
- Verify npm dependencies
- Check build output for errors

### Logs Location

- **GitHub Actions:** Repository → Actions → Workflow Run
- **Deployment Server:** Check application logs
- **Database:** SQL Server error logs

---

## Best Practices

### 1. Branch Strategy

```
main (production)
  ↑
  └─ Pull Request (requires all checks to pass)
  
develop (staging)
  ↑
  └─ Feature branches
```

### 2. Commit Messages

```
[DATABASE] Update product schema
[API] Add new endpoint for sellers
[UI] Fix product filter component
```

### 3. Testing Before Push

```bash
# Database
dotnet build ShopNStopDB/ShopNStopDB.sln

# API
dotnet build api/ShopNShop.Api.csproj
dotnet test api/ShopNShop.Api.csproj

# UI
cd stopnshop-ui
npm run lint
npm run test -- --run
npm run build
```

### 4. Code Review

- All PRs require review before merge
- Verify changes don't break existing functionality
- Check for security issues
- Ensure proper error handling

---

## Deployment Checklist

### Before Deploying to Production

- [ ] All tests pass
- [ ] Code review completed
- [ ] Database changes validated
- [ ] API changes tested
- [ ] UI changes tested
- [ ] Documentation updated
- [ ] Backup created
- [ ] Rollback plan documented

### After Deployment

- [ ] Verify all services are running
- [ ] Check error logs
- [ ] Test critical workflows
- [ ] Monitor performance
- [ ] Notify stakeholders

---

## Advanced Configuration

### Custom Deployment Scripts

Create custom scripts in `scripts/` directory:

```powershell
# scripts/deploy-database.ps1
param(
    [string]$Environment = "dev",
    [string]$Server = "localhost\SQLEXPRESS01",
    [string]$Database = "ShopNShop_db"
)

Write-Host "Deploying to $Environment..."
# Custom deployment logic
```

### Environment-Specific Configuration

Create environment files:

```
config/
├── dev.json
├── staging.json
└── prod.json
```

### Slack Notifications

Add to workflow:

```yaml
- name: Notify Slack
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Deployment ${{ job.status }}"
      }
```

---

## Support and Documentation

- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **SSDT Documentation:** https://learn.microsoft.com/en-us/sql/ssdt/
- **SQL Server Deployment:** https://learn.microsoft.com/en-us/sql/relational-databases/

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05-11 | Initial CI/CD pipeline setup |

---

**Last Updated:** May 11, 2026  
**Status:** ✅ Ready for Implementation
