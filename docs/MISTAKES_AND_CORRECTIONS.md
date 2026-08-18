# Mistakes Made & Corrections Applied (2026-05-15)

## Mistakes Identified

### 1. ❌ Made Assumptions Without Verifying All Three Layers
**What I did:** Created categories in the database without checking which API endpoint the frontend actually calls.

**Result:** Categories were created but never showed up in the navigation because:
- UI was calling `/menu` endpoint
- `/menu` calls `sp_GetMegaMenu` stored procedure
- Stored procedure expects 3-level hierarchy (Menus → Categories → SubCategories)
- I created categories without understanding the MenuId linkage requirement

**Time wasted:** Multiple debugging cycles trying to verify changes in frontend

**Fix applied:** Added Rule 1 to CLAUDE.md:
```
Before making ANY change, you MUST check:
1. Database (stored procedures, table schemas, data)
2. API (which endpoint is called, what data it returns)
3. UI (which API endpoint the frontend calls — grep for it)
```

---

### 2. ❌ Committed Unnecessary Files to Git
**What I did:** Pushed temporary scripts and planning documents:
- `kill5000.bat` — process management script (as you pointed out)
- `run_tests.ps1`, `run_tests.sh` — test runners
- `CATEGORY_RESTRUCTURE_GUIDE.md`, `SETUP_COMPLETE_SUMMARY.md`, etc. — scratch docs
- `seed_test_data.sql` — seed script
- `ShopNStopDB/..publish/` — build outputs

**Result:** Repository cluttered with files that shouldn't be committed

**Fix applied:** Added Rule 2 to CLAUDE.md:
```
Before running `git commit`, execute:
  git status --short

Files to NEVER commit:
- *.bat, *.sh, run_tests.* — process/test scripts
- WHAT_TO_PUSH.md, READY_TO_PUSH.md, scratch docs
- *.log, *.tmp — temporary files
- node_modules/, bin/, obj/, dist/ — build outputs
```

---

### 3. ❌ Didn't Read Constraints Before Starting Work
**What I did:** Jumped into creating database categories without:
- Reading the stored procedure `sp_GetMegaMenu` first
- Understanding the existing Menus table structure
- Grepping for how the frontend fetches categories

**Result:** Had to iterate and debug instead of getting it right the first time

**Fix applied:** Added Rule 3 to CLAUDE.md:
```
ALWAYS read relevant files before starting work:
- CLAUDE.md in repo root and sub-projects
- ARCHITECTURE.md for the module you're touching
- Existing patterns in the codebase

Never skip this step.
```

---

### 4. ❌ Made Assumptions Instead of Verifying API Calls
**What I did:** Assumed the categories endpoint was `/api/catalog/categories` without checking.

**Result:** Spent time documenting the wrong endpoint; frontend wasn't calling it at all.

**Fix applied:** Now required to:
1. Use `grep` to find which API functions the UI component uses
2. Read the API service file to see actual endpoint URL
3. Search backend controllers for that endpoint
4. Find the service/repository implementation
5. Trace to stored procedure

---

## Checklist to Prevent Future Mistakes

### Before Any Database Change:
- [ ] Read CLAUDE.md and ARCHITECTURE.md for the module
- [ ] Grep in UI codebase: `grep -r "endpoint_name\|api_function_name" stopnshop-ui/src/`
- [ ] Verify the API endpoint file: Check `src/api/*.ts` to see actual endpoint path
- [ ] Check backend: Find the controller method that handles that endpoint
- [ ] Check the service/repository: Understand the database access pattern
- [ ] Check the stored procedure: Understand what data structure it expects/returns
- [ ] Document: "API calls X endpoint → Service calls SP Y → Returns structure Z"

### Before Any Commit:
- [ ] Run: `git status --short`
- [ ] Run: `git diff --name-only`
- [ ] Review each file: Is it source code or a temporary file?
- [ ] Remove unwanted files: `git reset HEAD filename`
- [ ] Stage only necessary files explicitly (NOT `git add .` or `git add -A`)
- [ ] Create commit message with format:
  ```
  type: brief description
  
  - Changed UI: [files and changes]
  - Changed API: [endpoints/services and changes]
  - Changed DB: [SPs/tables and changes]
  
  Reason: [why]
  ```

### For Any Feature:
- [ ] Identify all three layers that need changes (or document why only some change)
- [ ] Make changes in order: Database → API → UI (bottom-up)
- [ ] Test each layer independently:
  - Database: Run SQL queries to verify structure
  - API: Call endpoint with Postman or curl to verify response
  - UI: Load in browser and verify displays correctly
- [ ] Document the complete flow: "User does X → UI calls endpoint Y → API calls SP Z → Returns data W"

---

## What NOT to Do Again

1. ❌ Create database changes without understanding the existing schema and stored procedures
2. ❌ Assume an API endpoint exists without grepping for it
3. ❌ Commit temporary files, scripts, or scratch documents
4. ❌ Skip reading instructions and making assumptions
5. ❌ Debug frontend when the issue is actually in the database layer
6. ❌ Commit without reviewing what files are being committed

---

## How to Apply These Lessons

Every time you start work:
1. **Read first** — Open CLAUDE.md from the current directory
2. **Read the code** — Use grep to find existing patterns
3. **Document your understanding** — Write out which files will change and why
4. **Verify all three layers** — Database, API, UI must be in sync
5. **Review before commit** — Check git status and only commit source files

---

**Created:** 2026-05-15
**Author:** Claude (after user correction)
**Purpose:** Prevent repeating these mistakes
