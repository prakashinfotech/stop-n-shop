@ECHO OFF
SETLOCAL
:: Restores db-export\ShopNShop_db.bacpac onto a target SQL Server.
:: Usage:   db-restore.bat [server] [database-name]
::   defaults: server=localhost\SQLEXPRESS01, database-name=ShopNShop_db
:: The target database MUST NOT already exist — import creates it fresh.

SET "SERVER=%1"
IF "%SERVER%"=="" SET "SERVER=localhost\SQLEXPRESS01"
SET "DB=%2"
IF "%DB%"=="" SET "DB=ShopNShop_db"

SET "SRC=%~dp0..\db-export\ShopNShop_db.bacpac"
IF NOT EXIST "%SRC%" (
    ECHO ERROR: %SRC% not found. Run db-export.bat on the source machine first or copy the bacpac in.
    EXIT /B 1
)

ECHO Importing %SRC% -> [%SERVER%].[%DB%]
sqlpackage /Action:Import ^
    /SourceFile:"%SRC%" ^
    /TargetServerName:"%SERVER%" ^
    /TargetDatabaseName:"%DB%" ^
    /TargetTrustServerCertificate:true

IF ERRORLEVEL 1 (
    ECHO ERROR: Import failed. If the database already exists, drop it first or pass a different name as the second arg.
    EXIT /B 1
)
ECHO Done. Database [%SERVER%].[%DB%] is now an exact clone of the source.
ENDLOCAL
