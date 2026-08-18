@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

SET "PROJECT_NAME=StopNShopDB"
SET "SQLPROJ=ShopNStopDB.sqlproj"
SET "CONFIG=Release"
SET "OUTPUT_DIR=%~dp0bin\%CONFIG%"
SET "DACPAC=%OUTPUT_DIR%\%PROJECT_NAME%.dacpac"

ECHO ============================================================
ECHO  StopNShopDB Build Script
ECHO ============================================================

:: ── Build ───────────────────────────────────────────────────
ECHO [1/3] Building DACPAC...

dotnet build "%SQLPROJ%" --configuration %CONFIG% --nologo 2>NUL
IF NOT ERRORLEVEL 1 GOTO :BUILD_OK

ECHO dotnet build not available, trying MSBuild...
WHERE msbuild >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO ERROR: Neither dotnet nor MSBuild found in PATH.
    ECHO        Install the .NET SDK or Visual Studio Build Tools.
    EXIT /B 1
)
msbuild "%SQLPROJ%" /t:Build /p:Configuration=%CONFIG% /nologo /v:m
IF ERRORLEVEL 1 (
    ECHO ERROR: Build failed.
    EXIT /B 1
)

:BUILD_OK
ECHO [2/3] Build succeeded. DACPAC: %DACPAC%

IF NOT "%1"=="--deploy" (
    ECHO [3/3] Deploy skipped. Run with --deploy ^<server^> [^<database^>] to publish.
    GOTO :EOF
)

:: ── Deploy ──────────────────────────────────────────────────
IF "%2"=="" (
    ECHO ERROR: Server name required.  Usage: BuildProject.bat --deploy ^<server^> [^<database^>]
    EXIT /B 1
)
SET "TARGET_SERVER=%2"
SET "TARGET_DB=%PROJECT_NAME%"
IF NOT "%3"=="" SET "TARGET_DB=%3"

ECHO [3/3] Deploying to [%TARGET_SERVER%].[%TARGET_DB%]...

WHERE sqlpackage >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO ERROR: sqlpackage not found in PATH.
    ECHO        Install via: dotnet tool install -g microsoft.sqlpackage
    EXIT /B 1
)

sqlpackage ^
    /Action:Publish ^
    /SourceFile:"%DACPAC%" ^
    /TargetServerName:"%TARGET_SERVER%" ^
    /TargetDatabaseName:"%TARGET_DB%" ^
    /p:BlockOnPossibleDataLoss=false ^
    /p:DropObjectsNotInSource=false ^
    /p:CreateNewDatabase=false ^
    /p:AllowIncompatiblePlatform=true ^
    /p:IncludeCompositeObjects=true

IF ERRORLEVEL 1 (
    ECHO ERROR: Deployment failed.
    EXIT /B 1
)

ECHO Deployment complete.
ENDLOCAL
