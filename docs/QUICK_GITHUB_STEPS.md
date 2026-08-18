# Quick GitHub Setup (5 Minutes)

## Step 1: Create Repository (1 minute)

1. Go to: https://github.com/new
2. Name: `StopNShop`
3. Click **Create repository**
4. Copy the URL shown

---

## Step 2: Push Code (2 minutes)

Open PowerShell and run:

```powershell
cd C:\Users\dolly\StopNShop

git init
git add .
git commit -m "Initial commit: Add CI/CD pipeline"
git branch -M develop
git remote add origin https://github.com/YOUR_USERNAME/StopNShop.git
git push -u origin develop
```

Replace `YOUR_USERNAME` with your GitHub username.

---

## Step 3: Add Secrets (1 minute)

1. Go to: https://github.com/YOUR_USERNAME/StopNShop
2. Click **Settings**
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add these secrets:

| Name | Value |
|------|-------|
| `DEV_DB_CONNECTION_STRING` | `Server=localhost\SQLEXPRESS01;Database=ShopNShop_db;Trusted_Connection=True;TrustServerCertificate=True;` |
| `PROD_DB_CONNECTION_STRING` | Your production connection string |
| `PROD_DB_SERVER` | Your production server |
| `PROD_DB_USER` | Your production user |
| `PROD_DB_PASSWORD` | Your production password |
| `DEV_API_PATH` | `C:\inetpub\wwwroot\api-dev` |
| `PROD_API_PATH` | `C:\inetpub\wwwroot\api-prod` |

---

## Step 4: View Pipelines (1 minute)

1. Go to: https://github.com/YOUR_USERNAME/StopNShop
2. Click **Actions** tab
3. You should see:
   - Database Deployment
   - API Deployment
   - UI Deployment

---

## Step 5: Trigger Workflows

Make a change and push:

```powershell
# Make a small change
# Edit any file

git add .
git commit -m "Test workflow"
git push origin develop
```

Then watch in GitHub Actions tab!

---

## Done! 🎉

Your CI/CD pipeline is now live on GitHub!

**Next time you push code:**
- Workflows run automatically
- Tests execute
- Deployments happen
- All visible in Actions tab

---

## Useful Links

- **Your Repository:** https://github.com/YOUR_USERNAME/StopNShop
- **Actions Tab:** https://github.com/YOUR_USERNAME/StopNShop/actions
- **Settings:** https://github.com/YOUR_USERNAME/StopNShop/settings

---

**That's it!** 🚀
