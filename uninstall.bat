@echo off
REM Batch script to uninstall MinGW-w64 (g++) Compiler
REM This is a simplified version of the PowerShell uninstall script
REM Usage: Run as Administrator for complete removal

echo === MinGW-w64 (g++) Uninstall Script ===
echo.

REM Check current installation
if not exist "C:\msys64" (
    echo [OK] MSYS2 is not installed or already removed.
) else (
    echo [FOUND] MSYS2 installation detected at C:\msys64
)

if not exist "C:\msys64\ucrt64\bin\g++.exe" (
    echo [OK] GCC compiler not found.
) else (
    echo [FOUND] GCC compiler detected
)

echo.
echo This will remove:
echo - MinGW-w64 GCC compiler from PATH
echo - MSYS2 and all its components
echo - C:\msys64 directory and all contents
echo.
set /p response="Continue with uninstallation? (y/N): "
if /i not "%response%"=="y" (
    echo Uninstallation cancelled by user.
    pause
    exit /b 0
)

echo.
echo Starting uninstallation process...
echo.

echo Step 1: Removing from PATH...
REM Get current user PATH
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "userpath=%%b"
if not defined userpath set "userpath="

REM Remove MinGW path
set "newpath=%userpath:C:\msys64\ucrt64\bin;=%"
set "newpath=%newpath:;C:\msys64\ucrt64\bin=%"
set "newpath=%newpath:C:\msys64\ucrt64\bin=%"

REM Update registry
reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%newpath%" /f >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Successfully removed from user PATH
) else (
    echo [WARN] Could not update user PATH
)

REM Update current session
set "PATH=%PATH:C:\msys64\ucrt64\bin;=%"
set "PATH=%PATH:;C:\msys64\ucrt64\bin=%"
set "PATH=%PATH:C:\msys64\ucrt64\bin=%"
echo [OK] Updated current session PATH
echo.

echo Step 2: Uninstalling MSYS2...
REM Check if winget is available
where winget >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] winget is not available. Manual uninstallation required.
    echo Please uninstall MSYS2 via Windows Settings ^> Apps
    goto :cleanup
)

REM Uninstall via winget
winget uninstall --id=MSYS2.MSYS2 -e --accept-source-agreements >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] MSYS2 uninstalled successfully!
) else (
    echo [WARN] winget uninstall completed with warnings
)

:cleanup
echo.
echo Step 3: Cleaning up files...
if exist "C:\msys64" (
    echo Removing C:\msys64 directory...
    rmdir /s /q "C:\msys64" 2>nul
    if not exist "C:\msys64" (
        echo [OK] Removed C:\msys64 directory
    ) else (
        echo [WARN] Could not remove C:\msys64 directory completely
        echo You may need to restart and delete it manually
    )
) else (
    echo [OK] No cleanup needed
)

echo.
echo Step 4: Verifying removal...
g++ --version >nul 2>nul
if %errorlevel% neq 0 (
    echo [OK] g++ is no longer accessible from PATH
) else (
    echo [WARN] g++ is still accessible. You may need to restart your terminal.
)

echo.
echo === Uninstallation Complete! ===
echo.
echo What was removed:
echo - MinGW-w64 GCC compiler from PATH
echo - MSYS2 development environment
echo - All related files and directories
echo.
echo Next Steps:
echo 1. Restart your terminal/IDE to pick up PATH changes
echo 2. g++ command should no longer be available
echo 3. Your system is back to its original state
echo.
pause
