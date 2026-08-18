# Quick CI/CD Testing Script
# Run this to test all components locally before pushing to GitHub

param(
    [string]$Component = "all",
    [switch]$SkipTests,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath

function Write-Status {
    param([string]$Message, [string]$Status = "Info")
    $colors = @{
        "Success" = "Green"
        "Error" = "Red"
        "Warning" = "Yellow"
        "Info" = "Cyan"
    }
    $color = $colors[$Status]
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Test-Component {
    param([string]$Name, [scriptblock]$TestBlock)
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Testing: $Name"
    Write-Host "=========================================="
    
    try {
        & $TestBlock
        Write-Status "$Name test passed" "Success"
        return $true
    }
    catch {
        Write-Status "$Name test failed: $_" "Error"
        return $false
    }
}

# Test Database
$testDatabase = {
    Write-Status "Checking SQL Server connection..." "Info"
    
    $connectionString = "Server=localhost\SQLEXPRESS01;Database=ShopNShop_db;Trusted_Connection=True;TrustServerCertificate=True;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    $connection.Close()
    
    Write-Status "SQL Server connection successful" "Success"
    
    Write-Status "Validating database schema..." "Info"
    
    & "$rootPath\scripts\deploy-local.ps1" -Component database
}

# Test API
$testAPI = {
    Write-Status "Checking .NET installation..." "Info"
    $dotnetVersion = dotnet --version
    Write-Status "Found .NET: $dotnetVersion" "Success"
    
    Write-Status "Building API..." "Info"
    Push-Location "$rootPath\api"
    
    dotnet clean --nologo -q
    dotnet restore --nologo -q
    dotnet build --configuration Release --nologo -q
    
    if (-not $SkipTests) {
        Write-Status "Running API tests..." "Info"
        dotnet test --configuration Release --no-build --nologo -q
    }
    
    Write-Status "Publishing API..." "Info"
    dotnet publish --configuration Release --output "$rootPath\publish\api" --nologo -q
    
    Pop-Location
    Write-Status "API build successful" "Success"
}

# Test UI
$testUI = {
    Write-Status "Checking Node.js installation..." "Info"
    $nodeVersion = node --version
    $npmVersion = npm --version
    Write-Status "Found Node.js: $nodeVersion, npm: $npmVersion" "Success"
    
    Write-Status "Installing dependencies..." "Info"
    Push-Location "$rootPath\stopnshop-ui"
    npm ci --silent
    
    Write-Status "Running linter..." "Info"
    npm run lint
    
    if (-not $SkipTests) {
        Write-Status "Running UI tests..." "Info"
        npm run test -- --run --silent
    }
    
    Write-Status "Building UI..." "Info"
    npm run build --silent
    
    Pop-Location
    Write-Status "UI build successful" "Success"
}

# Main execution
Write-Host ""
Write-Host "=========================================="
Write-Host "StopNShop CI/CD Local Testing Script"
Write-Host "=========================================="
Write-Host ""
Write-Status "Starting CI/CD tests..." "Info"
Write-Status "Component: $Component" "Info"
Write-Status "Skip Tests: $SkipTests" "Info"
Write-Host ""

$results = @{}

try {
    if ($Component -eq "all" -or $Component -eq "database") {
        $results["Database"] = Test-Component "Database" $testDatabase
    }
    
    if ($Component -eq "all" -or $Component -eq "api") {
        $results["API"] = Test-Component "API" $testAPI
    }
    
    if ($Component -eq "all" -or $Component -eq "ui") {
        $results["UI"] = Test-Component "UI" $testUI
    }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Test Summary"
    Write-Host "=========================================="
    
    $allPassed = $true
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "[PASSED]" } else { "[FAILED]" }
        $color = if ($results[$key]) { "Green" } else { "Red" }
        Write-Host "$key : $status" -ForegroundColor $color
        if (-not $results[$key]) { $allPassed = $false }
    }
    
    Write-Host ""
    if ($allPassed) {
        Write-Status "All tests passed! Ready to push to GitHub." "Success"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "  1. git add ."
        Write-Host "  2. git commit -m 'Your message'"
        Write-Host "  3. git push origin develop"
        Write-Host ""
        exit 0
    }
    else {
        Write-Status "Some tests failed. Please fix issues before pushing." "Error"
        exit 1
    }
}
catch {
    Write-Status "Unexpected error: $_" "Error"
    exit 1
}
