@echo off
REM Batch script to install MinGW-w64 (g++) Compiler
REM This is a simplified version of the PowerShell script
REM Usage: Run as Administrator for best results

echo === MinGW-w64 (g++) Installation Script ===
echo.

REM Check if winget is available
where winget >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: winget is not available. Please install App Installer from Microsoft Store.
    pause
    exit /b 1
)

echo Step 1: Installing MSYS2 via winget...
winget install --id=MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements
if %errorlevel% neq 0 (
    echo ERROR: Failed to install MSYS2
    pause
    exit /b 1
)
echo ✓ MSYS2 installed successfully!
echo.

echo Step 2: Installing MinGW-w64 GCC toolchain...
C:\msys64\usr\bin\pacman.exe -S --noconfirm mingw-w64-ucrt-x86_64-gcc
if %errorlevel% neq 0 (
    echo ERROR: Failed to install GCC toolchain
    pause
    exit /b 1
)
echo ✓ GCC toolchain installed successfully!
echo.

echo Step 3: Adding to PATH (User environment)...
REM Add to user PATH
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "userpath=%%b"
if not defined userpath set "userpath="

REM Check if already in path
echo %userpath% | findstr /i "msys64\\ucrt64\\bin" >nul
if %errorlevel% equ 0 (
    echo ✓ Path already contains MinGW-w64
) else (
    REM Add to registry
    reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%userpath%;C:\msys64\ucrt64\bin" /f >nul
    if %errorlevel% equ 0 (
        echo ✓ Successfully added to user PATH
    ) else (
        echo ERROR: Failed to update PATH
        pause
        exit /b 1
    )
)

REM Add to current session
set "PATH=%PATH%;C:\msys64\ucrt64\bin"
echo ✓ Updated current session PATH
echo.

echo Step 4: Verifying installation...
if not exist "C:\msys64\ucrt64\bin\g++.exe" (
    echo ERROR: g++.exe not found
    pause
    exit /b 1
)

C:\msys64\ucrt64\bin\g++.exe --version >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: g++ is not working properly
    pause
    exit /b 1
)

for /f "tokens=*" %%a in ('C:\msys64\ucrt64\bin\g++.exe --version 2^>^&1 ^| findstr /r "^g"') do (
    echo ✓ g++ is working: %%a
    goto :version_found
)
:version_found

echo.
echo === Installation Complete! ===
echo.
echo Next Steps:
echo 1. Restart your terminal/IDE to pick up PATH changes
echo 2. Test installation by running: g++ --version
echo 3. Your Python test case generator should now work!
echo.
echo If g++ is still not recognized after restarting:
echo - Run this script as Administrator
echo - Or manually add C:\msys64\ucrt64\bin to your PATH
echo.
pause
