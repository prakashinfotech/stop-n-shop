# How to Run the CI/CD Testing Script

## Method 1: PowerShell (Easiest)

### Step 1: Open PowerShell as Administrator
```
1. Press: Win + X
2. Click: "Windows PowerShell (Admin)"
   OR
   "Terminal (Admin)"
```

**You should see:**
```
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Users\dolly>
```

### Step 2: Navigate to Project Directory
```powershell
cd C:\Users\dolly\StopNShop
```

**You should see:**
```
PS C:\Users\dolly\StopNShop>
```

### Step 3: Run the Testing Script
```powershell
.\scripts\test-cicd-locally.ps1
```

**You should see:**
```
╔════════════════════════════════════════════╗
║   StopNShop CI/CD Local Testing Script    ║
╚════════════════════════════════════════════╝

[Info] Starting CI/CD tests...
[Info] Component: all
[Info] Skip Tests: False

==========================================
Testing: Database
==========================================
[Info] Checking SQL Server connection...
[Success] SQL Server connection successful
...
```

---

## Method 2: VS Code Terminal (Recommended for Development)

### Step 1: Open VS Code
```
1. Open File Explorer
2. Navigate to: C:\Users\dolly\StopNShop
3. Right-click → "Open with Code"
   OR
   Open VS Code and File → Open Folder
```

### Step 2: Open Terminal
```
Press: Ctrl + ~
OR
Menu: Terminal → New Terminal
```

**You should see a terminal at the bottom:**
```
PS C:\Users\dolly\StopNShop>
```

### Step 3: Run the Script
```powershell
.\scripts\test-cicd-locally.ps1
```

---

## Method 3: PowerShell ISE (Visual Editor)

### Step 1: Open PowerShell ISE
```
1. Press: Win + R
2. Type: powershell_ise
3. Press: Enter
```

### Step 2: Open the Script
```
1. File → Open
2. Navigate to: C:\Users\dolly\StopNShop\scripts\test-cicd-locally.ps1
3. Click: Open
```

### Step 3: Run the Script
```
Press: F5
OR
Click: Green Play Button (▶)
```

---

## What the Script Does

The script will:

1. **Check SQL Server Connection**
   ```
   [Info] Checking SQL Server connection...
   [Success] SQL Server connection successful
   ```

2. **Deploy Database**
   ```
   [Info] Building API...
   [Success] API build successful
   ```

3. **Build API**
   ```
   [Info] Building API...
   [Success] API build successful
   ```

4. **Build UI**
   ```
   [Info] Building UI...
   [Success] UI build successful
   ```

5. **Show Results**
   ```
   ==========================================
   Test Summary
   ==========================================
   Database: ✓ PASSED
   API: ✓ PASSED
   UI: ✓ PASSED
   
   All tests passed! Ready to push to GitHub.
   ```

---

## Expected Output

### Success Output
```
╔════════════════════════════════════════════╗
║   StopNShop CI/CD Local Testing Script    ║
╚════════════════════════════════════════════╝

[Info] Starting CI/CD tests...
[Info] Component: all
[Info] Skip Tests: False

==========================================
Testing: Database
==========================================
[Info] Checking SQL Server connection...
[Success] SQL Server connection successful
[Info] Validating database schema...
[Success] Database test passed

==========================================
Testing: API
==========================================
[Info] Checking .NET installation...
[Success] Found .NET: 8.0.x
[Info] Building API...
[Info] Publishing API...
[Success] API test passed

==========================================
Testing: UI
==========================================
[Info] Checking Node.js installation...
[Success] Found Node.js: v18.x.x, npm: 9.x.x
[Info] Installing dependencies...
[Info] Running linter...
[Info] Building UI...
[Success] UI test passed

==========================================
Test Summary
==========================================
Database: ✓ PASSED
API: ✓ PASSED
UI: ✓ PASSED

All tests passed! Ready to push to GitHub.

Next steps:
  1. git add .
  2. git commit -m 'Your message'
  3. git push origin develop
```

### Error Output
If something fails, you'll see:
```
[Error] Database test failed: Connection timeout
```

**Solution:** Check the error message and fix the issue.

---

## Troubleshooting

### Issue: "PowerShell is disabled on this system"

**Solution:**
1. Open PowerShell as Administrator
2. Run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Type: `Y` and press Enter
4. Try running the script again

### Issue: "Cannot find path"

**Solution:**
1. Make sure you're in the correct directory:
   ```powershell
   cd C:\Users\dolly\StopNShop
   ```
2. Verify the script exists:
   ```powershell
   ls scripts/
   ```
3. Try again:
   ```powershell
   .\scripts\test-cicd-locally.ps1
   ```

### Issue: "SQL Server connection failed"

**Solution:**
1. Make sure SQL Server is running
2. Check the server name: `localhost\SQLEXPRESS01`
3. Verify the database exists: `ShopNShop_db`

### Issue: ".NET not found"

**Solution:**
1. Install .NET 8.0 SDK from: https://dotnet.microsoft.com/download
2. Verify installation:
   ```powershell
   dotnet --version
   ```

### Issue: "Node.js not found"

**Solution:**
1. Install Node.js 18+ from: https://nodejs.org/
2. Verify installation:
   ```powershell
   node --version
   npm --version
   ```

---

## Quick Reference

### Copy-Paste Commands

**Open PowerShell and run:**
```powershell
cd C:\Users\dolly\StopNShop
.\scripts\test-cicd-locally.ps1
```

**Or run individual components:**
```powershell
# Test database only
.\scripts\deploy-local.ps1 -Component database

# Test API only
.\scripts\deploy-local.ps1 -Component api

# Test UI only
.\scripts\deploy-local.ps1 -Component ui

# Test all
.\scripts\deploy-local.ps1 -Component all
```

---

## After Script Completes

### If All Tests Pass ✅
```bash
git add .
git commit -m "Add CI/CD pipeline"
git push origin develop
```

### If Tests Fail ❌
1. Read the error message
2. Fix the issue
3. Run the script again

---

## Visual Guide

```
┌─────────────────────────────────────────┐
│  1. Open PowerShell as Administrator    │
│     (Win + X → PowerShell Admin)        │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  2. Navigate to project directory       │
│     cd C:\Users\dolly\StopNShop         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  3. Run the testing script              │
│     .\scripts\test-cicd-locally.ps1     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  4. Wait for tests to complete          │
│     (Takes 5-10 minutes)                │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  5. Check results                       │
│     ✓ All tests passed?                 │
│     ✗ Any tests failed?                 │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  6. If passed, push to GitHub           │
│     git add .                           │
│     git commit -m "message"             │
│     git push origin develop             │
└─────────────────────────────────────────┘
```

---

## Summary

**To run the script:**

1. Open PowerShell as Administrator
2. Navigate to: `C:\Users\dolly\StopNShop`
3. Run: `.\scripts\test-cicd-locally.ps1`
4. Wait for results
5. If all pass, push to GitHub

**That's it!** 🎉

---

**Last Updated:** May 11, 2026
