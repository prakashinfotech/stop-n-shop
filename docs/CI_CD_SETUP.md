# CI/CD Pipeline Setup — Stop-N-Shop

## Overview
Complete GitHub Actions CI/CD pipeline for automated testing, building, and deployment.

---

## Workflows Configured

### 1. **test.yml** — Comprehensive Test Suite ✅ NEW
Runs on every push and pull request to main/develop.

**Jobs:**
- `backend-tests`: .NET API unit tests
  - Builds Release configuration
  - Runs xUnit tests
  - Uploads test results (TRX format)
  - Codecov coverage report
  
- `frontend-tests`: React UI unit tests
  - Installs npm dependencies
  - Runs Vitest suite with coverage
  - Linting checks
  - Codecov coverage report
  
- `build-verify`: Verifies both can build
  - Dotnet build (Release)
  - npm build (Vite)
  - Catches configuration issues early
  
- `code-quality`: TypeScript + security checks
  - Type checking (`tsc --noEmit`)
  - npm audit for vulnerabilities
  - Non-blocking warnings
  
- `test-summary`: Aggregates results
  - Shows combined test status
  - Fails workflow if ANY test fails
  - Email notifications on failure

**Triggers:**
- Push to main, develop, feature/* branches
- Pull requests to main/develop
- Manual trigger (workflow_dispatch)

---

### 2. **regression-tests.yml** — Regression Test Matrix ✅ NEW
Detailed regression testing by feature area.

**Jobs:**
- `regression-matrix`: Parallel test execution
  - Authentication tests
  - Orders tests
  - Cart & Checkout tests
  - Seller Operations tests
  - Email Notifications tests
  - Non-blocking (fail-fast: false)

- `critical-path`: End-to-end critical flows
  - Starts actual API server
  - Builds UI
  - Tests API endpoints
  - Verifies dist artifacts
  - **Blocks merge if fails**

- `regression-report`: Summary and analysis
  - Aggregates all results
  - Generates report in run summary
  - Shows artifact locations

**Triggers:**
- Push to main/develop
- Pull requests to main/develop
- Manual dispatch (with test type selection)

**Test Type Options (manual trigger):**
- `all` — Run complete suite
- `backend` — API only
- `frontend` — UI only
- `integration` — Integration tests

---

### 3. **api-deploy.yml** — API Deployment (Existing)
Builds and deploys API to dev/prod.

**Modified to include:**
- Unit test execution in build step (continue-on-error)
- Test result artifacts upload
- Separate dev/prod deployment stages

---

### 4. **ui-deploy.yml** — UI Deployment (Existing)
Builds and deploys React UI.

**Triggers on:**
- UI code changes
- `.github/workflows/ui-deploy.yml` changes

---

### 5. **database-deploy.yml** — Database Deployment (Existing)
Deploys database migrations and stored procedures.

---

### 6. **deploy.yml** — Main Orchestration (Existing)
Coordinates all three deployments.

---

## Test Execution Flow

```
┌─────────────────┐
│  Push/PR Event  │
└────────┬────────┘
         │
    ┌────▼─────────────────────────┐
    │   test.yml Trigger           │
    └────┬────────┬────────┬───────┘
         │        │        │
    ┌────▼──┐  ┌──▼────┐ ┌▼──────────┐
    │Backend│  │Frontend│ │Build      │
    │Tests  │  │Tests   │ │Verify     │
    └────┬──┘  └──┬────┘ └┬──────────┘
         │        │       │
         └────┬───┴───┬───┘
              │       │
         ┌────▼───┬──▼──────────┐
         │Code    │Test Summary │
         │Quality │(Fails if ❌)│
         └────┬───┴──┬──────────┘
              │      │
              └──┬───┘
                 │
    ┌────────────▼──────────┐
    │  regression-tests.yml │
    │  (Optional, on-demand)│
    └────────────┬──────────┘
                 │
         ┌───────▼──────┬──────────┐
         │Regression    │Critical  │
         │Matrix (≈)    │Path (✓)  │
         └───────┬──────┴──────────┘
                 │
         ┌───────▼──────────┐
         │Regression Report │
         └──────────────────┘
```

---

## Test Results & Artifacts

### Uploaded Artifacts

**Backend Tests:**
- Location: `backend-test-results/`
- Files: `*.trx` (TRX format), `TestResults/`
- Coverage: Cobertura XML format

**Frontend Tests:**
- Location: `frontend-test-results/`
- Files: `coverage/`, `test-results/`
- Coverage: LCOV format

**Regression Tests:**
- Location: `regression-results-{Area}/`
- One artifact per test area
- TRX format compatible with Azure DevOps

### Coverage Reports

Codecov integration:
- **Backend coverage**: `.net` flag
- **Frontend coverage**: `javascript` flag
- Reports sent to: `https://codecov.io`
- Comments on PR with coverage changes

---

## Required GitHub Secrets

For deployment jobs to work, configure these secrets:

```
DEV_API_PATH       = Path to dev API folder
PROD_API_PATH      = Path to prod API folder
DEV_UI_PATH        = Path to dev UI folder
PROD_UI_PATH       = Path to prod UI folder
DB_DEV_SERVER      = Dev database server
DB_PROD_SERVER     = Prod database server
API_RESTART_TOKEN  = Token for restarting API service
```

Set secrets at: `Settings > Secrets and variables > Actions`

---

## Branch Protection Rules

Recommended settings for `main` branch:

```
✅ Require status checks to pass before merging:
   - test.yml / backend-tests
   - test.yml / frontend-tests
   - test.yml / build-verify
   - regression-tests.yml / critical-path

✅ Require branches to be up to date

✅ Require approval from code owners

✅ Restrict who can push to main
```

Configure at: `Settings > Branches > main > Branch protection rules`

---

## Running Tests Locally

### Backend
```bash
cd api
dotnet test --configuration Release
```

### Frontend
```bash
cd stopnshop-ui
npm test
```

### Both
```bash
./run_tests.sh all      # Linux/Mac
.\run_tests.ps1 -TestType all  # Windows
```

---

## Monitoring & Alerts

### GitHub Actions Dashboard
- View: `Actions` tab in repository
- Status: Green (✅) or Red (❌) badges
- Logs: Click job name for detailed output

### Workflow Status Badge
Add to README.md:
```markdown
![Tests](https://github.com/YOUR_ORG/Stop-N-Shop/workflows/Test%20Suite/badge.svg)
![Regression Tests](https://github.com/YOUR_ORG/Stop-N-Shop/workflows/Regression%20Tests/badge.svg)
```

### Email Notifications
- Enabled by default for failed workflows
- Configure at: `Settings > Notifications`

### Slack Integration (Optional)
Create webhook and add to workflow:
```yaml
- name: Slack notification
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Performance & Costs

### Execution Times
| Workflow | Duration | Frequency |
|----------|----------|-----------|
| test.yml | ~5-10 min | Per push |
| regression-tests.yml | ~10-15 min | On-demand |
| Deployments | ~5 min | Push to main |

### GitHub Actions Costs
- **Public repo**: FREE ✅
- **Private repo**: 2,000 minutes/month free
- **Windows runner**: 10x minutes count
- Current setup: ~50 minutes/push = ~1,500 min/month ✅

---

## Troubleshooting

### Tests fail in CI but pass locally

**Solution:**
- Windows line endings: `git config core.autocrlf true`
- .NET version mismatch: Verify `dotnet --version`
- Database connection: CI uses SQL Server in container
- Check workflow logs: Click failed job for details

### Deployment secrets not working

**Solution:**
- Verify secret names match exactly
- Secrets are case-sensitive
- Check permissions: Ensure `GITHUB_TOKEN` has write access

### Coverage reports not appearing

**Solution:**
- Ensure test produces coverage files
- Check codecov config: `.codecov.yml` in root
- Verify coverage path matches workflow

### Slow workflow execution

**Solution:**
- Use cache for dependencies: `actions/setup-node@v4` with cache
- Parallel matrix jobs for regression tests
- Consider workflow file optimizations

---

## Best Practices

### 1. Keep Tests Fast
- Target: <10 minutes for main test suite
- Mock external dependencies
- Run only affected tests on PR

### 2. Meaningful Test Names
- Should read like documentation
- Include scenario + expected result
- Example: `CancelOrder_WithShippedOrder_ReturnsBadRequest`

### 3. Fail Fast
- Tests should exit on first critical failure
- Regression matrix uses `fail-fast: false` for coverage
- Critical path uses default `fail-fast: true`

### 4. Artifact Cleanup
- Auto-cleanup after 30 days
- Manual download from Actions tab
- Archive important test results

### 5. Monitor Trends
- Track test execution time over time
- Monitor coverage trends
- Watch for flaky tests (retry spikes)

---

## Next Steps

### Phase 1: Enable Tests (Done ✅)
- ✅ test.yml created
- ✅ regression-tests.yml created
- ✅ Documentation written

### Phase 2: Run & Validate
- [ ] Commit workflows to git
- [ ] Wait for tests to run on next push
- [ ] Review results in Actions tab
- [ ] Fix any failures

### Phase 3: Configure Protection
- [ ] Set branch protection rules
- [ ] Add required status checks
- [ ] Configure Slack notifications
- [ ] Enable codecov comments

### Phase 4: Optimize
- [ ] Monitor execution times
- [ ] Add more targeted tests
- [ ] Implement test report publishing
- [ ] Set up trend analysis

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Setup Actions](https://github.com/actions/setup-dotnet)
- [Codecov Integration](https://about.codecov.io)
- [Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)

---

## Support

For issues with CI/CD:
1. Check workflow logs: `Actions` → `{Workflow}` → `{Run}` → `{Job}`
2. Review error message in step output
3. Compare with local test execution
4. Check `.github/workflows/*.yml` for syntax errors
5. Post issue with workflow logs attached

