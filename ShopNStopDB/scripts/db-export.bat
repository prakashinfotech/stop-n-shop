@ECHO OFF
SETLOCAL
:: Exports the live ShopNShop_db into a single .bacpac file (schema + data).
:: Usage:   db-export.bat
:: Output:  db-export\ShopNShop_db.bacpac

SET "SERVER=%1"
IF "%SERVER%"=="" SET "SERVER=localhost\SQLEXPRESS01"
SET "DB=%2"
IF "%DB%"=="" SET "DB=ShopNShop_db"

SET "OUT=%~dp0..\db-export\ShopNShop_db.bacpac"
IF NOT EXIST "%~dp0..\db-export" MKDIR "%~dp0..\db-export"

ECHO Exporting [%SERVER%].[%DB%] -> %OUT%
sqlpackage /Action:Export ^
    /SourceServerName:"%SERVER%" ^
    /SourceDatabaseName:"%DB%" ^
    /SourceTrustServerCertificate:true ^
    /TargetFile:"%OUT%"

IF ERRORLEVEL 1 (
    ECHO ERROR: Export failed.
    EXIT /B 1
)
ECHO Done. Copy db-export\ShopNShop_db.bacpac to the target machine and run db-restore.bat there.
ENDLOCAL
