# GitHub Setup and Pipeline Viewing Guide

**Date:** May 11, 2026  
**Status:** Ready to Push to GitHub

---

## Step 1: Create GitHub Repository

### 1.1 Go to GitHub
1. Open browser: https://github.com
2. Sign in to your account (or create one if needed)

### 1.2 Create New Repository
1. Click **+** icon (top right)
2. Select **New repository**
3. Fill in details:
   - **Repository name:** `StopNShop`
   - **Description:** `E-commerce marketplace platform with CI/CD pipeline`
   - **Visibility:** Public (or Private if preferred)
   - **Initialize with:** Leave unchecked
4. Click **Create repository**

### 1.3 Copy Repository URL
After creation, you'll see:
```
https://github.com/YOUR_USERNAME/StopNShop.git
```

Copy this URL (you'll need it in Step 2)

---

## Step 2: Push Code to GitHub

### 2.1 Open PowerShell
```
Win + X → Windows PowerShell (Admin)
```

### 2.2 Navigate to Project
```powershell
cd C:\Users\dolly\StopNShop
```

### 2.3 Initialize Git (if not already done)
```powershell
git init
```

### 2.4 Add All Files
```powershell
git add .
```

### 2.5 Create Initial Commit
```powershell
git commit -m "Initial commit: Add CI/CD pipeline and database updates"
```

### 2.6 Add Remote Repository
Replace `YOUR_USERNAME` with your GitHub username:
```powershell
git remote add origin https://github.com/YOUR_USERNAME/StopNShop.git
```

### 2.7 Create and Push to Develop Branch
```powershell
git branch -M develop
git push -u origin develop
```

**Expected Output:**
```
Enumerating objects: 150, done.
Counting objects: 100% (150/150), done.
Delta compression using up to 8 threads
Compressing objects: 100% (120/120), done.
Writing objects: 100% (150/150), 2.50 MiB | 500 KiB/s, done.
Total 150 (delta 50), reused 0 (delta 0), reused pack 0 (delta 0)
remote: Resolving deltas: 100% (50/50), done.
remote:
remote: Create a pull request for 'develop' on GitHub by visiting:
remote:      https://github.com/YOUR_USERNAME/StopNShop/pull/new/develop
remote:
To https://github.com/YOUR_USERNAME/StopNShop.git
 * [new branch]      develop -> develop
Branch 'develop' set up to track remote branch 'develop' from 'origin'.
```

---

## Step 3: Configure GitHub Secrets

### 3.1 Go to Repository Settings
1. Go to: https://github.com/YOUR_USERNAME/StopNShop
2. Click **Settings** tab
3. Left sidebar → **Secrets and variables** → **Actions**

### 3.2 Add Database Secrets
Click **New repository secret** and add:

**Secret 1: DEV_DB_CONNECTION_STRING**
```
Server=localhost\SQLEXPRESS01;Database=ShopNShop_db;Trusted_Connection=True;TrustServerCertificate=True;
```

**Secret 2: PROD_DB_CONNECTION_STRING**
```
Server=YOUR_PROD_SERVER\SQLEXPRESS;Database=ShopNShop_db;User Id=sa;Password=YOUR_PASSWORD;TrustServerCertificate=True;
```

**Secret 3: PROD_DB_SERVER**
```
YOUR_PROD_SERVER
```

**Secret 4: PROD_DB_USER**
```
sa
```

**Secret 5: PROD_DB_PASSWORD**
```
YOUR_PASSWORD
```

### 3.3 Add API Secrets
**Secret 6: DEV_API_PATH**
```
C:\inetpub\wwwroot\api-dev
```

**Secret 7: PROD_API_PATH**
```
C:\inetpub\wwwroot\api-prod
```

---

## Step 4: View Workflows in GitHub

### 4.1 Go to Actions Tab
1. Go to: https://github.com/YOUR_USERNAME/StopNShop
2. Click **Actions** tab

**You should see:**
```
All workflows
├── Database Deployment
├── API Deployment
└── UI Deployment
```

### 4.2 View Workflow Runs
1. Click on a workflow name (e.g., "Database Deployment")
2. You'll see all runs of that workflow

**Example:**
```
Database Deployment

Run #1 - develop branch - 2 minutes ago - PASSED
Run #2 - develop branch - 5 minutes ago - PASSED
```

### 4.3 View Workflow Details
1. Click on a specific run
2. You'll see:
   - **Status:** PASSED or FAILED
   - **Jobs:** List of jobs that ran
   - **Logs:** Detailed output

---

## Step 5: Trigger Workflows

### 5.1 Trigger Database Workflow
```powershell
# Make a change to database
# Edit: ShopNStopDB/dbo/Stored Procedures/sp_GetBrands.sql
# Add a comment

git add ShopNStopDB/
git commit -m "[DATABASE] Test workflow"
git push origin develop
```

**Watch in GitHub:**
1. Go to Actions tab
2. Click "Database Deployment"
3. Watch the workflow run in real-time

### 5.2 Trigger API Workflow
```powershell
# Make a change to API
# Edit: api/Program.cs
# Add a comment

git add api/
git commit -m "[API] Test workflow"
git push origin develop
```

### 5.3 Trigger UI Workflow
```powershell
# Make a change to UI
# Edit: stopnshop-ui/src/App.tsx
# Add a comment

git add stopnshop-ui/
git commit -m "[UI] Test workflow"
git push origin develop
```

---

## Step 6: View Workflow Logs

### 6.1 Access Workflow Run
1. Go to Actions tab
2. Click workflow name
3. Click specific run

### 6.2 View Job Details
1. Click on a job (e.g., "build-api")
2. Expand steps to see logs

**Example:**
```
build-api
├── Checkout code
├── Setup .NET
├── Restore dependencies
├── Build
├── Run tests
└── Publish
```

### 6.3 View Step Logs
1. Click on a step (e.g., "Build")
2. See detailed output:
```
Build succeeded.
0 Warning(s)
0 Error(s)
```

---

## Step 7: Create Pull Request (Optional)

### 7.1 Create Feature Branch
```powershell
git checkout -b feature/test-pr
```

### 7.2 Make Changes
```powershell
# Make some changes
# Commit
git add .
git commit -m "Test feature"
git push origin feature/test-pr
```

### 7.3 Create PR on GitHub
1. Go to: https://github.com/YOUR_USERNAME/StopNShop
2. Click **Pull requests** tab
3. Click **New pull request**
4. Select:
   - **Base:** develop
   - **Compare:** feature/test-pr
5. Click **Create pull request**

### 7.4 Watch Status Checks
1. Scroll down to see status checks
2. Watch workflows run
3. All must pass before merging

---

## Understanding Workflow Status

### Green Checkmark ✓
```
✓ Database Deployment - PASSED
✓ API Deployment - PASSED
✓ UI Deployment - PASSED
```
All workflows passed successfully!

### Red X ✗
```
✗ Database Deployment - FAILED
```
Workflow failed. Click to see error logs.

### Yellow Circle ⏳
```
⏳ Database Deployment - IN PROGRESS
```
Workflow is currently running.

---

## Workflow Files Location

The workflows are stored in your repository:
```
.github/workflows/
├── database-deploy.yml
├── api-deploy.yml
└── ui-deploy.yml
```

You can view/edit them on GitHub:
1. Go to repository
2. Click **Code** tab
3. Navigate to `.github/workflows/`
4. Click on a workflow file to view

---

## Quick Reference

### View Workflows
```
GitHub → Repository → Actions tab
```

### View Specific Workflow
```
Actions → Click workflow name
```

### View Workflow Run
```
Actions → Workflow name → Click run
```

### View Job Logs
```
Actions → Workflow run → Click job → Expand steps
```

### Trigger Workflow
```
Push code to develop or main branch
```

### View Secrets
```
Settings → Secrets and variables → Actions
```

---

## Troubleshooting

### Workflows Not Showing
**Solution:**
1. Make sure `.github/workflows/` directory exists
2. Verify workflow files are committed
3. Push to GitHub: `git push origin develop`
4. Refresh GitHub page

### Workflow Fails
**Solution:**
1. Click workflow run
2. Click failed job
3. Expand steps to see error
4. Fix issue locally
5. Push fix to GitHub

### Secrets Not Working
**Solution:**
1. Go to Settings → Secrets
2. Verify secret names match workflow file
3. Verify secret values are correct
4. Re-run workflow

---

## Next Steps

### After Pushing to GitHub
1. ✅ Go to Actions tab
2. ✅ Watch workflows run
3. ✅ Verify all pass
4. ✅ Make changes and push
5. ✅ Watch workflows trigger automatically

### Set Up Branch Protection (Optional)
1. Settings → Branches
2. Add rule for `main` branch
3. Require status checks to pass
4. Require code review

### Monitor Deployments
1. Check Actions tab regularly
2. Review workflow logs
3. Verify deployments succeeded

---

## Visual Guide

```
┌─────────────────────────────────────────┐
│  1. Create GitHub Repository            │
│     https://github.com/new              │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  2. Push Code to GitHub                 │
│     git push origin develop             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  3. Configure Secrets                   │
│     Settings → Secrets and variables    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  4. View Workflows                      │
│     Actions tab                         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  5. Trigger Workflows                   │
│     Push code to develop/main           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  6. Monitor Deployments                 │
│     Watch workflow runs                 │
└─────────────────────────────────────────┘
```

---

## Summary

**To see pipelines in GitHub:**

1. Create repository on GitHub
2. Push code: `git push origin develop`
3. Go to Actions tab
4. Watch workflows run automatically
5. Click on workflow to see details

**That's it!** Your CI/CD pipeline is now live on GitHub! 🎉

---

**Last Updated:** May 11, 2026
