# PowerShell Script to Uninstall MinGW-w64 (g++) Compiler
# This script removes MSYS2 and MinGW-w64 toolchain installed by install-gcc.ps1
# Author: Pratik Pathak
# Usage: Run as Administrator for complete removal, or as regular user for user PATH cleanup

param(
    [switch]$SystemWide = $false,  # Remove from system PATH (requires admin)
    [switch]$UserOnly = $true,     # Remove from user PATH only (default)
    [switch]$KeepMSYS2 = $false,   # Keep MSYS2 installed, only remove from PATH
    [switch]$Force = $false,       # Skip confirmation prompts
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

function Remove-FromPath {
    param(
        [string]$PathToRemove,
        [bool]$SystemWide = $false
    )
    
    $target = if ($SystemWide) { [EnvironmentVariableTarget]::Machine } else { [EnvironmentVariableTarget]::User }
    $targetName = if ($SystemWide) { "System" } else { "User" }
    
    Write-ColorOutput "=== Removing from $targetName PATH Environment Variable ===" $ColorInfo
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $target)
        
        if ($currentPath -notlike "*$PathToRemove*") {
            Write-ColorOutput "[OK] Path does not contain $PathToRemove" $ColorWarning
            return
        }
        
        # Remove the path and clean up any double semicolons
        $newPath = $currentPath -replace [regex]::Escape($PathToRemove), ""
        $newPath = $newPath -replace ";;+", ";"
        $newPath = $newPath.TrimStart(";").TrimEnd(";")
        
        [Environment]::SetEnvironmentVariable("Path", $newPath, $target)
        Write-ColorOutput "[OK] Successfully removed $PathToRemove from $targetName PATH" $ColorSuccess
        
        # Also update current session
        $env:PATH = $env:PATH -replace [regex]::Escape($PathToRemove), ""
        $env:PATH = $env:PATH -replace ";;+", ";"
        $env:PATH = $env:PATH.TrimStart(";").TrimEnd(";")
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

function Uninstall-MSYS2 {
    Write-ColorOutput "=== Uninstalling MSYS2 ===" $ColorInfo
    
    if (-not (Test-WingetAvailable)) {
        Write-ColorOutput "[WARN] winget is not available. Manual uninstallation required." $ColorWarning
        Write-ColorOutput "Please uninstall MSYS2 via Windows Settings > Apps" $ColorInfo
        return
    }
    
    # Check if MSYS2 is installed
    if (-not (Test-Path "C:\msys64")) {
        Write-ColorOutput "[OK] MSYS2 is not installed or already removed." $ColorSuccess
        return
    }
    
    try {
        Write-ColorOutput "Uninstalling MSYS2 via winget..." $ColorInfo
        $result = winget uninstall --id=MSYS2.MSYS2 -e --accept-source-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[OK] MSYS2 uninstalled successfully!" $ColorSuccess
        } else {
            Write-ColorOutput "[WARN] winget uninstall completed with exit code $LASTEXITCODE" $ColorWarning
            Write-ColorOutput "winget output: $result" $ColorInfo
        }
    }
    catch {
        Write-ColorOutput "[WARN] Failed to uninstall MSYS2 via winget: $($_.Exception.Message)" $ColorWarning
        Write-ColorOutput "You may need to uninstall manually via Windows Settings > Apps" $ColorInfo
    }
    
    # Clean up remaining files
    if (Test-Path "C:\msys64") {
        Write-ColorOutput "Cleaning up remaining MSYS2 files..." $ColorInfo
        try {
            Remove-Item -Path "C:\msys64" -Recurse -Force -ErrorAction Continue
            Write-ColorOutput "[OK] Removed C:\msys64 directory" $ColorSuccess
        }
        catch {
            Write-ColorOutput "[WARN] Could not remove C:\msys64 directory: $($_.Exception.Message)" $ColorWarning
            Write-ColorOutput "You may need to manually delete it or restart and try again" $ColorInfo
        }
    }
}

function Test-InstallationExists {
    $msys2Exists = Test-Path "C:\msys64"
    $gccExists = Test-Path "C:\msys64\ucrt64\bin\g++.exe"
    
    # Check PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $systemPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    $pathContainsMinGW = ($userPath -like "*msys64*") -or ($systemPath -like "*msys64*")
    
    return @{
        MSYS2Exists = $msys2Exists
        GCCExists = $gccExists
        PathContainsMinGW = $pathContainsMinGW
        HasAnyInstallation = $msys2Exists -or $pathContainsMinGW
    }
}

function Show-UninstallSummary {
    param($InstallationStatus)
    
    Write-ColorOutput "=== Installation Status ===" $ColorInfo
    Write-ColorOutput "MSYS2 Directory: $(if ($InstallationStatus.MSYS2Exists) { 'Found' } else { 'Not Found' })" $ColorInfo
    Write-ColorOutput "GCC Compiler: $(if ($InstallationStatus.GCCExists) { 'Found' } else { 'Not Found' })" $ColorInfo
    Write-ColorOutput "PATH Contains MinGW: $(if ($InstallationStatus.PathContainsMinGW) { 'Yes' } else { 'No' })" $ColorInfo
}

function Show-CompletionMessage {
    Write-ColorOutput "" 
    Write-ColorOutput "=== Uninstallation Complete! ===" $ColorSuccess
    Write-ColorOutput ""
    Write-ColorOutput "What was removed:" $ColorInfo
    Write-ColorOutput "- MinGW-w64 GCC compiler from PATH" $ColorInfo
    if (-not $KeepMSYS2) {
        Write-ColorOutput "- MSYS2 development environment" $ColorInfo
        Write-ColorOutput "- All related files and directories" $ColorInfo
    }
    Write-ColorOutput ""
    Write-ColorOutput "Next Steps:" $ColorInfo
    Write-ColorOutput "1. Restart your terminal/IDE to pick up PATH changes" $ColorInfo
    Write-ColorOutput "2. g++ command should no longer be available" $ColorInfo
    Write-ColorOutput "3. Your system is back to its original state" $ColorInfo
    Write-ColorOutput ""
    if ($KeepMSYS2) {
        Write-ColorOutput "Note: MSYS2 was kept as requested. You can use it manually if needed." $ColorWarning
    }
}

# Main execution
try {
    Write-ColorOutput "=== MinGW-w64 (g++) Uninstall Script ===" $ColorInfo
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
    
    # Check current installation status
    $installStatus = Test-InstallationExists
    Show-UninstallSummary -InstallationStatus $installStatus
    
    if (-not $installStatus.HasAnyInstallation) {
        Write-ColorOutput ""
        Write-ColorOutput "[OK] No MinGW-w64 installation found. Nothing to uninstall." $ColorSuccess
        exit 0
    }
    
    # Confirmation prompt
    if (-not $Force) {
        Write-ColorOutput ""
        Write-ColorOutput "This will remove:" $ColorWarning
        Write-ColorOutput "- MinGW-w64 GCC compiler from PATH" $ColorWarning
        if (-not $KeepMSYS2) {
            Write-ColorOutput "- MSYS2 and all its components" $ColorWarning
            Write-ColorOutput "- C:\msys64 directory and all contents" $ColorWarning
        }
        Write-ColorOutput ""
        $response = Read-Host "Continue with uninstallation? (y/N)"
        if ($response -notmatch "^[yY]") {
            Write-ColorOutput "Uninstallation cancelled by user." $ColorInfo
            exit 0
        }
    }
    
    # Uninstallation steps
    Write-ColorOutput ""
    Write-ColorOutput "Starting uninstallation process..." $ColorInfo
    Write-ColorOutput ""
    
    # Step 1: Remove from PATH
    $mingwBinPath = "C:\msys64\ucrt64\bin"
    if ($installStatus.PathContainsMinGW) {
        Remove-FromPath -PathToRemove $mingwBinPath -SystemWide $SystemWide
        Write-ColorOutput ""
    }
    
    # Step 2: Uninstall MSYS2 (if requested)
    if (-not $KeepMSYS2 -and $installStatus.MSYS2Exists) {
        Uninstall-MSYS2
        Write-ColorOutput ""
    }
    
    # Step 3: Verify removal
    Write-ColorOutput "=== Verifying Removal ===" $ColorInfo
    
    try {
        $null = & g++ --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[WARN] g++ is still accessible. You may need to restart your terminal." $ColorWarning
        }
    }
    catch {
        Write-ColorOutput "[OK] g++ is no longer accessible from PATH" $ColorSuccess
    }
    
    $finalStatus = Test-InstallationExists
    if (-not $finalStatus.PathContainsMinGW) {
        Write-ColorOutput "[OK] MinGW-w64 removed from PATH successfully" $ColorSuccess
    }
    
    if ($KeepMSYS2) {
        if ($finalStatus.MSYS2Exists) {
            Write-ColorOutput "[OK] MSYS2 kept as requested" $ColorSuccess
        }
    } else {
        if (-not $finalStatus.MSYS2Exists) {
            Write-ColorOutput "[OK] MSYS2 removed successfully" $ColorSuccess
        } else {
            Write-ColorOutput "[WARN] MSYS2 directory still exists. Manual cleanup may be needed." $ColorWarning
        }
    }
    
    Write-ColorOutput ""
    Show-CompletionMessage
    
}
catch {
    Write-ColorOutput "" 
    Write-ColorOutput "=== Uninstallation Failed ===" $ColorError
    Write-ColorOutput "Error: $($_.Exception.Message)" $ColorError
    Write-ColorOutput ""
    Write-ColorOutput "Manual Cleanup:" $ColorInfo
    Write-ColorOutput "1. Remove C:\msys64\ucrt64\bin from your PATH manually" $ColorInfo
    Write-ColorOutput "2. Uninstall MSYS2 via Windows Settings > Apps" $ColorInfo
    Write-ColorOutput "3. Delete C:\msys64 directory if it exists" $ColorInfo
    
    exit 1
}
