# PowerShell Script to Install MinGW-w64 (g++) Compiler
# This script automates the installation of MSYS2 and MinGW-w64 toolchain
# Author: AI Assistant
# Usage: Run as Administrator for best results, or as regular user for user-only installation

param(
    [switch]$SystemWide = $false,  # Install for all users (requires admin)
    [switch]$UserOnly = $true,     # Install for current user only (default)
    [switch]$SkipInstall = $false, # Skip installation if already installed
    [switch]$Verbose = $false      # Show detailed output
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "Cyan"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Install-MSYS2 {
    Write-ColorOutput "=== Installing MSYS2 (MinGW-w64 Base) ===" $ColorInfo
    
    if (-not (Test-WingetAvailable)) {
        Write-ColorOutput "ERROR: winget is not available. Please install App Installer from Microsoft Store." $ColorError
        throw "winget not found"
    }
    
    try {
        Write-ColorOutput "Installing MSYS2 via winget..." $ColorInfo
        $result = winget install --id=MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[OK] MSYS2 installed successfully!" $ColorSuccess
        } else {
            throw "winget install failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-ColorOutput "ERROR: Failed to install MSYS2: $($_.Exception.Message)" $ColorError
        throw
    }
}

function Install-MinGWToolchain {
    Write-ColorOutput "=== Installing MinGW-w64 GCC Toolchain ===" $ColorInfo
    
    $msys2PacmanPath = "C:\msys64\usr\bin\pacman.exe"
    
    if (-not (Test-Path $msys2PacmanPath)) {
        Write-ColorOutput "ERROR: MSYS2 pacman not found at $msys2PacmanPath" $ColorError
        throw "MSYS2 not properly installed"
    }
    
    try {
        Write-ColorOutput "Installing GCC compiler via pacman..." $ColorInfo
        $result = & $msys2PacmanPath -S --noconfirm mingw-w64-ucrt-x86_64-gcc
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[OK] MinGW-w64 GCC toolchain installed successfully!" $ColorSuccess
        } else {
            throw "pacman install failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-ColorOutput "ERROR: Failed to install MinGW-w64 toolchain: $($_.Exception.Message)" $ColorError
        throw
    }
}

function Add-ToPath {
    param(
        [string]$PathToAdd,
        [bool]$SystemWide = $false
    )
    
    $target = if ($SystemWide) { [EnvironmentVariableTarget]::Machine } else { [EnvironmentVariableTarget]::User }
    $targetName = if ($SystemWide) { "System" } else { "User" }
    
    Write-ColorOutput "=== Updating $targetName PATH Environment Variable ===" $ColorInfo
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $target)
        
        if ($currentPath -like "*$PathToAdd*") {
            Write-ColorOutput "[OK] Path already contains $PathToAdd" $ColorWarning
            return
        }
        
        $newPath = if ($currentPath.EndsWith(";")) { 
            $currentPath + $PathToAdd 
        } else { 
            $currentPath + ";" + $PathToAdd 
        }
        
        [Environment]::SetEnvironmentVariable("Path", $newPath, $target)
        Write-ColorOutput "[OK] Successfully added $PathToAdd to $targetName PATH" $ColorSuccess
        
        # Also update current session
        $env:PATH = $env:PATH + ";" + $PathToAdd
        Write-ColorOutput "[OK] Updated current session PATH" $ColorSuccess
        
    }
    catch {
        Write-ColorOutput "ERROR: Failed to update PATH: $($_.Exception.Message)" $ColorError
        if ($_.Exception.Message -like "*registry access*") {
            Write-ColorOutput "HINT: Run as Administrator to modify System PATH, or use -UserOnly flag" $ColorWarning
        }
        throw
    }
}

function Test-GccInstallation {
    Write-ColorOutput "=== Verifying Installation ===" $ColorInfo
    
    $gccPath = "C:\msys64\ucrt64\bin\g++.exe"
    
    if (-not (Test-Path $gccPath)) {
        Write-ColorOutput "ERROR: g++.exe not found at $gccPath" $ColorError
        return $false
    }
    
    try {
        # Test g++ in current session
        $version = & "C:\msys64\ucrt64\bin\g++.exe" --version 2>&1 | Select-Object -First 1
        Write-ColorOutput "[OK] g++ is working: $version" $ColorSuccess
        
        # Test if g++ is in PATH
        try {
            $pathVersion = & g++ --version 2>&1 | Select-Object -First 1
            Write-ColorOutput "[OK] g++ is accessible via PATH: $pathVersion" $ColorSuccess
        }
        catch {
            Write-ColorOutput "[WARN] g++ installed but not in PATH. You may need to restart your terminal." $ColorWarning
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "ERROR: g++ is installed but not working properly: $($_.Exception.Message)" $ColorError
        return $false
    }
}

function Show-CompletionMessage {
    Write-ColorOutput "" 
    Write-ColorOutput "=== Installation Complete! ===" $ColorSuccess
    Write-ColorOutput ""
    Write-ColorOutput "Next Steps:" $ColorInfo
    Write-ColorOutput "1. Restart your terminal/IDE to pick up PATH changes" $ColorInfo
    Write-ColorOutput "2. Test installation by running: g++ --version" $ColorInfo
    Write-ColorOutput "3. Your Python test case generator should now work!" $ColorInfo
    Write-ColorOutput ""
    Write-ColorOutput "If g++ is still not recognized after restarting:" $ColorWarning
    Write-ColorOutput "- Run this script with -SystemWide flag as Administrator" $ColorWarning
    Write-ColorOutput "- Or manually add C:\msys64\ucrt64\bin to your PATH" $ColorWarning
    Write-ColorOutput ""
}

# Main execution
try {
    Write-ColorOutput "=== MinGW-w64 (g++) Installation Script ===" $ColorInfo
    Write-ColorOutput "PowerShell version: $($PSVersionTable.PSVersion)" $ColorInfo
    
    # Check if running as administrator
    $isAdmin = Test-Administrator
    if ($isAdmin) {
        Write-ColorOutput "[OK] Running as Administrator" $ColorSuccess
    } else {
        Write-ColorOutput "[WARN] Running as regular user" $ColorWarning
        if ($SystemWide) {
            Write-ColorOutput "ERROR: -SystemWide requires Administrator privileges" $ColorError
            exit 1
        }
    }
    
    # Check if already installed
    if (-not $SkipInstall) {
        $gccExists = Test-Path "C:\msys64\ucrt64\bin\g++.exe"
        if ($gccExists) {
            Write-ColorOutput "[WARN] MinGW-w64 appears to already be installed." $ColorWarning
            $response = Read-Host "Continue anyway? (y/N)"
            if ($response -notmatch "^[yY]") {
                Write-ColorOutput "Installation cancelled by user." $ColorInfo
                exit 0
            }
        }
    }
    
    # Installation steps
    Write-ColorOutput ""
    Write-ColorOutput "Starting installation process..." $ColorInfo
    Write-ColorOutput ""
    
    # Step 1: Install MSYS2
    if (-not $SkipInstall) {
        Install-MSYS2
        Write-ColorOutput ""
    }
    
    # Step 2: Install MinGW-w64 toolchain
    if (-not $SkipInstall) {
        Install-MinGWToolchain
        Write-ColorOutput ""
    }
    
    # Step 3: Update PATH
    $mingwBinPath = "C:\msys64\ucrt64\bin"
    Add-ToPath -PathToAdd $mingwBinPath -SystemWide $SystemWide
    Write-ColorOutput ""
    
    # Step 4: Verify installation
    $installSuccess = Test-GccInstallation
    Write-ColorOutput ""
    
    if ($installSuccess) {
        Show-CompletionMessage
    } else {
        Write-ColorOutput "Installation completed but verification failed. Please check manually." $ColorWarning
    }
    
}
catch {
    Write-ColorOutput "" 
    Write-ColorOutput "=== Installation Failed ===" $ColorError
    Write-ColorOutput "Error: $($_.Exception.Message)" $ColorError
    Write-ColorOutput ""
    Write-ColorOutput "Troubleshooting:" $ColorInfo
    Write-ColorOutput "1. Make sure you have internet connection" $ColorInfo
    Write-ColorOutput "2. Try running as Administrator" $ColorInfo
    Write-ColorOutput "3. Check if winget is available (Windows 10 1809+ required)" $ColorInfo
    Write-ColorOutput "4. Manual installation: https://www.mingw-w64.org/" $ColorInfo
    
    exit 1
}
