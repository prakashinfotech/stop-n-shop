# Local Deployment Script
# Builds and deploys all components locally using CI/CD-equivalent steps.
# Usage:
#   .\scripts\deploy-local.ps1                    # deploy all
#   .\scripts\deploy-local.ps1 -Component database
#   .\scripts\deploy-local.ps1 -Component api
#   .\scripts\deploy-local.ps1 -Component ui

param(
    [string]$Component   = "all",
    [string]$Environment = "dev",
    [string]$Server      = "localhost\SQLEXPRESS01",
    [string]$Database    = "ShopNShop_db"
)

$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath   = Split-Path -Parent $scriptPath

Write-Host "=========================================="
Write-Host "StopNShop Local Deployment Script"
Write-Host "=========================================="
Write-Host "Component  : $Component"
Write-Host "Environment: $Environment"
Write-Host "Server     : $Server"
Write-Host "Database   : $Database"
Write-Host ""

# ── Database ───────────────────────────────────────────────────────────────────
function Deploy-Database {
    Write-Host "--- Deploying Database (SSDT DACPAC) ---"

    $sqlprojDir  = Join-Path $rootPath "ShopNStopDB"
    $sqlprojFile = Join-Path $sqlprojDir "ShopNStopDB.sqlproj"
    $dacpacPath  = Join-Path $sqlprojDir "bin\Release\ShopNStopDB.dacpac"

    Write-Host "Building SSDT project..."
    dotnet build $sqlprojFile --configuration Release --nologo -v q
    if ($LASTEXITCODE -ne 0) { throw "SSDT build failed." }

    if (-not (Test-Path $dacpacPath)) {
        throw "DACPAC not found at: $dacpacPath"
    }

    # Ensure SqlPackage is available as a .NET global tool
    $sqlPkgCmd = Get-Command sqlpackage -ErrorAction SilentlyContinue
    if (-not $sqlPkgCmd) {
        Write-Host "SqlPackage not found. Installing via dotnet tool..."
        dotnet tool install -g microsoft.sqlpackage --ignore-failed-sources
        # Reload PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $sqlPkgCmd = Get-Command sqlpackage -ErrorAction SilentlyContinue
        if (-not $sqlPkgCmd) { throw "SqlPackage install failed. Run: dotnet tool install -g microsoft.sqlpackage" }
    }

    $connectionString = "Server=$Server;Database=$Database;Trusted_Connection=True;TrustServerCertificate=True;"

    Write-Host "Publishing DACPAC to $Server/$Database ..."
    sqlpackage /Action:Publish `
               /SourceFile:"$dacpacPath" `
               /TargetConnectionString:"$connectionString" `
               /p:BlockOnPossibleDataLoss=False `
               /p:DropObjectsNotInSource=False

    if ($LASTEXITCODE -ne 0) { throw "SqlPackage publish failed." }
    Write-Host "Database deployment completed successfully."
}

# ── API ────────────────────────────────────────────────────────────────────────
function Deploy-API {
    Write-Host "--- Deploying API ---"

    Push-Location "$rootPath\api"
    try {
        dotnet clean  --nologo -v q
        dotnet restore --nologo -v q
        dotnet build  --configuration Release --nologo -v q
        if ($LASTEXITCODE -ne 0) { throw "API build failed." }

        $outDir = Join-Path $rootPath "publish\api"
        dotnet publish --configuration Release --output $outDir --nologo -v q
        if ($LASTEXITCODE -ne 0) { throw "API publish failed." }
    }
    finally { Pop-Location }

    Write-Host "API deployment completed successfully."
}

# ── UI ─────────────────────────────────────────────────────────────────────────
function Deploy-UI {
    Write-Host "--- Deploying UI ---"

    Push-Location "$rootPath\stopnshop-ui"
    try {
        npm ci --silent
        npm run lint
        npm run build --silent
        if ($LASTEXITCODE -ne 0) { throw "UI build failed." }

        $outDir = Join-Path $rootPath "publish\ui"
        if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
        Copy-Item -Path "dist\*" -Destination $outDir -Recurse -Force
    }
    finally { Pop-Location }

    Write-Host "UI deployment completed successfully."
}

# ── Main ───────────────────────────────────────────────────────────────────────
try {
    if ($Component -eq "all" -or $Component -eq "database") { Deploy-Database; Write-Host "" }
    if ($Component -eq "all" -or $Component -eq "api")      { Deploy-API;      Write-Host "" }
    if ($Component -eq "all" -or $Component -eq "ui")       { Deploy-UI;       Write-Host "" }

    Write-Host "=========================================="
    Write-Host "Deployment completed successfully!"
    Write-Host "=========================================="
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
