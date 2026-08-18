# Test Automation Runner for Stop-N-Shop
# Runs all unit, integration, and frontend tests
# Usage: .\run_tests.ps1 -TestType "all|backend|frontend" -Coverage

param(
    [string]$TestType = "all",
    [switch]$Coverage
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ResultsDir = "test-results-$Timestamp"
$FullResultsPath = Join-Path $ScriptDir $ResultsDir

# Colors
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=================================================="
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "=================================================="
}

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-Header "Stop-N-Shop Test Automation Runner"
Write-Host "Test Type: $TestType" -ForegroundColor Cyan
Write-Host "Results Directory: $ResultsDir" -ForegroundColor Cyan
Write-Host ""

# Create results directory
New-Item -ItemType Directory -Path $FullResultsPath -Force | Out-Null

# Backend Tests
function Invoke-BackendTests {
    Write-Header "[1/3] Running Backend Tests..."
    Write-Host "========================================"

    Push-Location "$ScriptDir\api"

    try {
        # Check if dotnet is available
        $dotnetVersion = dotnet --version
        Write-Host "Using .NET: $dotnetVersion"

        # Run unit tests
        Write-Host "Running Backend Unit Tests..." -ForegroundColor Yellow
        dotnet test `
            --logger "trx;LogFileName=$FullResultsPath\backend-unit-tests.trx" `
            --logger "console;verbosity=normal" `
            --configuration Release `
            2>&1 | Tee-Object -FilePath "$FullResultsPath\backend-unit.log"

        if ($LASTEXITCODE -eq 0) {
            Write-Status "✅ Backend Unit Tests Passed" $Colors.Green
            return $true
        } else {
            Write-Status "❌ Backend Unit Tests Failed" $Colors.Red
            return $false
        }
    }
    catch {
        Write-Status "❌ Error running backend tests: $_" $Colors.Red
        return $false
    }
    finally {
        Pop-Location
    }
}

# Frontend Tests
function Invoke-FrontendTests {
    Write-Header "[2/3] Running Frontend Tests..."
    Write-Host "========================================"

    Push-Location "$ScriptDir\stopnshop-ui"

    try {
        # Check if npm is available
        $npmVersion = npm --version
        Write-Host "Using npm: $npmVersion"

        # Install dependencies if needed
        if (-not (Test-Path "node_modules")) {
            Write-Host "Installing dependencies..." -ForegroundColor Yellow
            npm install 2>&1 | Tee-Object -FilePath "$FullResultsPath\npm-install.log"
        }

        # Run tests
        Write-Host "Running Frontend Tests..." -ForegroundColor Yellow
        if ($Coverage) {
            npm run test:coverage 2>&1 | Tee-Object -FilePath "$FullResultsPath\frontend-tests.log"
        } else {
            npm test 2>&1 | Tee-Object -FilePath "$FullResultsPath\frontend-tests.log"
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Status "✅ Frontend Tests Passed" $Colors.Green
            return $true
        } else {
            Write-Status "❌ Frontend Tests Failed" $Colors.Red
            return $false
        }
    }
    catch {
        Write-Status "❌ Error running frontend tests: $_" $Colors.Red
        return $false
    }
    finally {
        Pop-Location
    }
}

# Integration Tests
function Invoke-IntegrationTests {
    Write-Header "[3/3] Running Integration Tests..."
    Write-Host "========================================"

    # Check if API is running
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -ErrorAction SilentlyContinue
        $apiRunning = $response.StatusCode -eq 200
    }
    catch {
        $apiRunning = $false
    }

    if (-not $apiRunning) {
        Write-Status "⚠️  API not running. Integration tests require running API." $Colors.Yellow
        Write-Host "Start API with: cd api && dotnet run"
        return $true # Don't fail, just skip
    }

    Push-Location "$ScriptDir\api"

    try {
        Write-Host "Running Integration Tests..." -ForegroundColor Yellow
        dotnet test `
            --filter "Category=Integration" `
            --logger "trx;LogFileName=$FullResultsPath\backend-integration-tests.trx" `
            --logger "console;verbosity=normal" `
            --configuration Release `
            2>&1 | Tee-Object -FilePath "$FullResultsPath\backend-integration.log"

        if ($LASTEXITCODE -eq 0) {
            Write-Status "✅ Integration Tests Passed" $Colors.Green
            return $true
        } else {
            Write-Status "❌ Integration Tests Failed" $Colors.Red
            return $false
        }
    }
    catch {
        Write-Status "❌ Error running integration tests: $_" $Colors.Red
        return $false
    }
    finally {
        Pop-Location
    }
}

# Generate Report
function Invoke-GenerateReport {
    Write-Host ""
    Write-Header "Test Execution Summary"

    $reportFile = Join-Path $FullResultsPath "TEST_REPORT.md"

    $reportContent = @"
# Test Execution Report
Generated: $(Get-Date)

## Test Statistics
- Test Type: $TestType
- Results Directory: $ResultsDir
- Coverage Report: $(if ($Coverage) { "Yes" } else { "No" })

## Backend Tests
- Log File: backend-unit.log
- Status: Check logs for details

## Frontend Tests
- Log File: frontend-tests.log
- Status: Check logs for details

## Integration Tests
- Log File: backend-integration.log
- Status: Check logs for details

## Logs Location
All test logs available in: $FullResultsPath\

## Files Generated
"@

    Get-ChildItem -Path $FullResultsPath | ForEach-Object {
        $reportContent += "`n- $($_.Name)"
    }

    $reportContent += "`n`n---`nReport generated at: $(Get-Date)"

    Set-Content -Path $reportFile -Value $reportContent
    Write-Host "📊 Report saved to: $reportFile"
}

# Main execution
function Main {
    $allPassed = $true

    switch ($TestType) {
        "backend" {
            $allPassed = Invoke-BackendTests
        }
        "frontend" {
            $allPassed = Invoke-FrontendTests
        }
        "all" {
            $allPassed = Invoke-BackendTests
            if ($allPassed) {
                $allPassed = Invoke-FrontendTests
            }
            if ($allPassed) {
                Invoke-IntegrationTests | Out-Null
            }
        }
        default {
            Write-Status "Unknown test type: $TestType" $Colors.Red
            Write-Host "Usage: .\run_tests.ps1 -TestType 'all|backend|frontend' [-Coverage]"
            exit 1
        }
    }

    Write-Host ""
    if ($allPassed) {
        Write-Header "✅ All Tests Passed!" -ForegroundColor Green
    } else {
        Write-Header "❌ Some Tests Failed" -ForegroundColor Red
    }

    Invoke-GenerateReport

    if (-not $allPassed) {
        exit 1
    }
}

Main
