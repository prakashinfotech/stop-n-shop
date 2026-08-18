# install-hooks.ps1 — run once per clone to wire up local git hooks.
# Usage: .\scripts\install-hooks.ps1

$ErrorActionPreference = "Stop"

$repoRoot  = git rev-parse --show-toplevel
$hooksDir  = Join-Path $repoRoot ".git\hooks"
$sourceDir = Join-Path $PSScriptRoot "hooks"

if (-not (Test-Path $hooksDir)) {
    Write-Error ".git/hooks not found. Are you inside a git repository?"
    exit 1
}

foreach ($hookFile in Get-ChildItem -Path $sourceDir) {
    $dest = Join-Path $hooksDir $hookFile.Name
    Copy-Item -Path $hookFile.FullName -Destination $dest -Force
    Write-Host "Installed: $($hookFile.Name) -> .git/hooks/$($hookFile.Name)"
}

Write-Host ""
Write-Host "Git hooks installed. From now on, pushing ShopNStopDB changes"
Write-Host "will automatically deploy the DACPAC to localhost\SQLEXPRESS01."
