# Fix all stored procedures to use CREATE PROCEDURE instead of CREATE OR ALTER PROCEDURE
# This is required for SSDT (SQL Server Data Tools) database projects

$spDirectory = "C:\Users\dolly\StopNShop\ShopNStopDB\dbo\Stored Procedures"
$files = Get-ChildItem -Path $spDirectory -Filter "*.sql"

$count = 0
foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    
    if ($content -match "CREATE OR ALTER PROCEDURE") {
        $newContent = $content -replace "CREATE OR ALTER PROCEDURE", "CREATE PROCEDURE"
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Fixed: $($file.Name)"
        $count++
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Fixed $count stored procedure files"
Write-Host "=========================================="
