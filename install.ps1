# PowerShell Script to Install g++ (GCC) on Windows using winget

param(
    [switch]$SkipCMake,
    [switch]$Verbose,
    [string]$MinGWVariant = "BrechtSanders.WinLibs.POSIX.UCRT",
    [string]$TempFile = ""
)

# Register cleanup on script exit (handles Ctrl+C, window closing, etc.)
if (-not [string]::IsNullOrEmpty($TempFile)) {
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        if (Test-Path $using:TempFile) {
            try {
                Remove-Item $using:TempFile -Force -ErrorAction SilentlyContinue
            }
            catch {
                # Silently ignore cleanup errors
            }
        }
    } | Out-Null
    
    # Also register for Ctrl+C interruption
    [Console]::TreatControlCAsInput = $false
    $null = Register-ObjectEvent -InputObject ([Console]) -EventName CancelKeyPress -Action {
        if (Test-Path $using:TempFile) {
            try {
                Remove-Item $using:TempFile -Force -ErrorAction SilentlyContinue
            }
            catch {
                # Silently ignore cleanup errors
            }
        }
    }
}

# Function to check if running as administrator
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to restart script as administrator
function Start-AsAdmin {
    if (-not (Test-IsAdmin)) {
        Write-ColorOutput "This script requires administrator privileges to install software." "Yellow"
        
        # Check if script was run via irm | iex (no file path available)
        if ([string]::IsNullOrEmpty($PSCommandPath)) {
            Write-ColorOutput "Detected script was run via irm | iex method." "Yellow"
            Write-ColorOutput "Downloading script temporarily and restarting as administrator..." "Yellow"
            
            try {
                # Create a temporary file for the script
                $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
                $scriptUrl = "https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1"
                
                # Download the script to temp location
                Invoke-WebRequest -Uri $scriptUrl -OutFile $tempScript -UseBasicParsing
                
                # Mark file for deletion on reboot as a safety measure
                try {
                    # Use Windows API to mark file for deletion on next reboot (safety net)
                    Add-Type -TypeDefinition @"
                        using System;
                        using System.Runtime.InteropServices;
                        public class FileOperations {
                            [DllImport("kernel32.dll", SetLastError=true)]
                            public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
                            public const int MOVEFILE_DELAY_UNTIL_REBOOT = 0x4;
                        }
"@
                    [FileOperations]::MoveFileEx($tempScript, $null, [FileOperations]::MOVEFILE_DELAY_UNTIL_REBOOT)
                }
                catch {
                    # Ignore if this fails - it's just a safety net
                }
                
                # Build the command line arguments to pass to the elevated process
                $argList = @("-ExecutionPolicy", "Bypass", "-File", "`"$tempScript`"")
                if ($SkipCMake) { $argList += "-SkipCMake" }
                if ($Verbose) { $argList += "-Verbose" }
                if ($MinGWVariant -ne "BrechtSanders.WinLibs.POSIX.UCRT") { 
                    $argList += "-MinGWVariant", "`"$MinGWVariant`"" 
                }
                
                # Add cleanup parameter to remove temp file after execution
                $argList += "-TempFile", "`"$tempScript`""
                
                # Start elevated process
                Start-Process PowerShell -ArgumentList $argList -Verb RunAs -Wait
                
                # Clean up temp file if still exists
                if (Test-Path $tempScript) {
                    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
                }
                
                exit 0
            }
            catch {
                Write-ColorOutput "Failed to download and restart script: $($_.Exception.Message)" "Red"
                Write-ColorOutput "Please try one of the manual methods from the README." "Red"
                Write-ColorOutput "Press any key to exit..." "Yellow"
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                exit 1
            }
        }
        
        Write-ColorOutput "Restarting script as administrator..." "Yellow"
        
        # Build the command line arguments to pass to the elevated process
        $argList = @()
        if ($SkipCMake) { $argList += "-SkipCMake" }
        if ($Verbose) { $argList += "-Verbose" }
        if ($MinGWVariant -ne "BrechtSanders.WinLibs.POSIX.UCRT") { 
            $argList += "-MinGWVariant", "`"$MinGWVariant`"" 
        }
        
        $argumentString = $argList -join " "
        
        try {
            Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $argumentString" -Verb RunAs
            exit 0
        }
        catch {
            Write-ColorOutput "Failed to restart as administrator: $($_.Exception.Message)" "Red"
            Write-ColorOutput "Please run this script manually as administrator." "Red"
            exit 1
        }
    }
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to show progress animation
function Show-ProgressAnimation {
    param(
        [string]$Message,
        [scriptblock]$ScriptBlock,
        [int]$TimeoutMinutes = 10
    )
    
    $job = Start-Job -ScriptBlock $ScriptBlock
    $spinner = @('|', '/', '-', '\')
    $spinnerIndex = 0
    $startTime = Get-Date
    
    Write-Host "$Message " -NoNewline
    
    while ($job.State -eq 'Running') {
        $elapsed = (Get-Date) - $startTime
        $minutes = [math]::Floor($elapsed.TotalMinutes)
        $seconds = [math]::Floor($elapsed.TotalSeconds % 60)
        
        Write-Host "`r$Message $($spinner[$spinnerIndex]) ($($minutes)m $($seconds)s)" -NoNewline -ForegroundColor Yellow
        $spinnerIndex = ($spinnerIndex + 1) % $spinner.Length
        Start-Sleep -Milliseconds 250
        
        # Timeout check
        if ($elapsed.TotalMinutes -gt $TimeoutMinutes) {
            Stop-Job $job
            Remove-Job $job
            Write-Host "`r$Message [TIMEOUT]" -ForegroundColor Red
            throw "Operation timed out after $TimeoutMinutes minutes"
        }
    }
    
    $result = Receive-Job $job
    Remove-Job $job
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`r$Message [COMPLETED]" -ForegroundColor Green
    } else {
        Write-Host "`r$Message [FAILED]" -ForegroundColor Red
    }
    
    return $result
}

# Function to refresh environment variables
function Update-SessionEnvironment {
    Write-ColorOutput "Refreshing environment variables..." "Yellow"
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-ColorOutput "Environment variables refreshed successfully!" "Green"
}

# Main installation function
function Install-GppToolchain {
    # Check for administrator privileges first
    Start-AsAdmin
    
    Write-ColorOutput "=== g++ Installation Script for Windows ===" "Cyan"
    Write-ColorOutput "This script will install g++ (GCC) compiler using winget" "White"
    Write-ColorOutput "Running with administrator privileges." "Green"
    Write-ColorOutput ""

    # Check if winget is available
    if (-not (Test-Command "winget")) {
        Write-ColorOutput "ERROR: winget is not available on this system!" "Red"
        Write-ColorOutput "Please install App Installer from Microsoft Store or update Windows." "Red"
        exit 1
    }

    # Check if g++ is already installed
    if (Test-Command "g++") {
        Write-ColorOutput "g++ is already installed:" "Green"
        try {
            $version = g++ --version 2>$null | Select-Object -First 1
            Write-ColorOutput $version "Green"
            $response = Read-Host "Do you want to reinstall? (y/N)"
            if ($response -ne "y" -and $response -ne "Y") {
                Write-ColorOutput "Installation cancelled." "Yellow"
                exit 0
            }
        }
        catch {
            Write-ColorOutput "g++ found but version check failed. Proceeding with installation..." "Yellow"
        }
    }

    try {
        # Step 1: Install CMake (optional)
        if (-not $SkipCMake) {
            Write-ColorOutput "Step 1: Installing CMake..." "Yellow"
            winget install -e --id=Kitware.CMake --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "[SUCCESS] CMake installed successfully!" "Green"
            } else {
                Write-ColorOutput "[WARNING] CMake installation failed or was skipped (may already be installed)" "Yellow"
            }
        } else {
            Write-ColorOutput "Step 1: Skipping CMake installation (-SkipCMake specified)" "Yellow"
        }

        # Step 2: Show available MinGW options
        if ($Verbose) {
            Write-ColorOutput "Step 2: Available MinGW packages:" "Yellow"
            winget search mingw
            Write-ColorOutput ""
        }

        # Step 3: Install MinGW-w64
        Write-ColorOutput "Step 3: Installing MinGW-w64 ($MinGWVariant)..." "Yellow"
        Write-ColorOutput "===============================================" "Magenta"
        Write-ColorOutput "⚠️  PLEASE WAIT: This may take a few minutes as it downloads ~250MB" "Magenta"
        Write-ColorOutput "===============================================" "Magenta"
        Write-ColorOutput ""
        
        try {
            Show-ProgressAnimation -Message "Downloading and installing MinGW-w64" -ScriptBlock {
                winget install -e --id=$using:MinGWVariant --accept-package-agreements --accept-source-agreements --silent
            } -TimeoutMinutes 15
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "`n[SUCCESS] MinGW-w64 installed successfully!" "Green"
            } else {
                Write-ColorOutput "`n[ERROR] MinGW-w64 installation failed!" "Red"
                exit 1
            }
        }
        catch {
            Write-ColorOutput "`n[ERROR] MinGW-w64 installation failed with error: $($_.Exception.Message)" "Red"
            exit 1
        }

        # Step 4: Refresh environment variables
        Write-ColorOutput "Step 4: Refreshing environment variables..." "Yellow"
        Update-SessionEnvironment
        
        # Step 5: Verify installation
        Write-ColorOutput "Step 5: Verifying g++ installation..." "Yellow"
        
        # Try to get g++ version
        try {
            $gppVersion = g++ --version 2>$null | Select-Object -First 1
            Write-ColorOutput "[SUCCESS] g++ installed successfully!" "Green"
            Write-ColorOutput "Version: $gppVersion" "Green"
        }
        catch {
            Write-ColorOutput "[WARNING] g++ command not found in current session." "Yellow"
            Write-ColorOutput "Please restart your PowerShell session or open a new terminal." "Yellow"
            Write-ColorOutput "Then run: g++ --version" "White"
        }

        # Step 6: Test compilation
        Write-ColorOutput "Step 6: Testing compilation..." "Yellow"
        
        $testCode = '#include <iostream>' + "`n" + 'int main() {' + "`n" + '    std::cout << "Hello, g++!" << std::endl;' + "`n" + '    return 0;' + "`n" + '}'
        $testFile = "test_gpp.cpp"
        $testExe = "test_gpp.exe"
        
        try {
            # Create test file
            $testCode | Out-File -FilePath $testFile -Encoding UTF8
            
            # Compile test file
            g++ -std=c++17 $testFile -o $testExe 2>$null
            
            if (Test-Path $testExe) {
                Write-ColorOutput "[SUCCESS] Test compilation successful!" "Green"
                
                # Run test executable
                $output = & ".\$testExe" 2>$null
                if ($output -eq "Hello, g++!") {
                    Write-ColorOutput "[SUCCESS] Test execution successful: $output" "Green"
                }
                
                # Clean up test files
                Remove-Item $testFile, $testExe -ErrorAction SilentlyContinue
            } else {
                Write-ColorOutput "[WARNING] Test compilation failed - g++ may not be in PATH yet" "Yellow"
                Write-ColorOutput "Please restart your terminal and try: g++ --version" "White"
            }
        }
        catch {
            Write-ColorOutput "[WARNING] Test compilation encountered an error" "Yellow"
            Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        }

        Write-ColorOutput ""
        Write-ColorOutput "=== Installation Summary ===" "Cyan"
        Write-ColorOutput "[SUCCESS] MinGW-w64 installed" "Green"
        if (-not $SkipCMake) { Write-ColorOutput "[SUCCESS] CMake installed" "Green" }
        Write-ColorOutput "[SUCCESS] Environment variables updated" "Green"
        Write-ColorOutput ""
        Write-ColorOutput "You can now use these commands:" "White"
        Write-ColorOutput "  g++ -std=c++17 myfile.cpp -o myprogram.exe" "Cyan"
        Write-ColorOutput "  gcc -std=c11 myfile.c -o myprogram.exe" "Cyan"
        Write-ColorOutput "  gdb myprogram.exe  (for debugging)" "Cyan"
        Write-ColorOutput ""
        Write-ColorOutput "If g++ is not recognized, please restart your terminal!" "Yellow"

    }
    catch {
        Write-ColorOutput "[ERROR] Installation failed with error:" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
        exit 1
    }
}

# Main execution with cleanup handling
try {
    # Show usage if help is requested
    if ($args -contains "-h" -or $args -contains "--help" -or $args -contains "/?") {
        Write-ColorOutput "Usage: .\install-gpp.ps1 [OPTIONS]" "Cyan"
        Write-ColorOutput ""
        Write-ColorOutput "Options:" "White"
        Write-ColorOutput "  -SkipCMake          Skip CMake installation" "White"
        Write-ColorOutput "  -Verbose            Show available MinGW packages before installation" "White"
        Write-ColorOutput "  -MinGWVariant <id>  Specify MinGW package ID (default: BrechtSanders.WinLibs.POSIX.UCRT)" "White"
        Write-ColorOutput ""
        Write-ColorOutput "Examples:" "White"
        Write-ColorOutput "  .\install-gpp.ps1                    # Standard installation" "Cyan"
        Write-ColorOutput "  .\install-gpp.ps1 -SkipCMake        # Skip CMake" "Cyan"
        Write-ColorOutput "  .\install-gpp.ps1 -Verbose          # Show available packages" "Cyan"
        Write-ColorOutput ""
        Write-ColorOutput "Alternative MinGW variants:" "White"
        Write-ColorOutput "  BrechtSanders.WinLibs.POSIX.UCRT    # Default - POSIX threads, UCRT runtime" "White"
        Write-ColorOutput "  BrechtSanders.WinLibs.MCF.UCRT      # MCF threads, UCRT runtime" "White"
        Write-ColorOutput "  MartinStorsjo.LLVM-MinGW.UCRT       # LLVM/Clang based" "White"
        exit 0
    }

    # Run the installation
    Install-GppToolchain
}
finally {
    # Clean up temporary file if it was created during auto-elevation
    if (-not [string]::IsNullOrEmpty($TempFile) -and (Test-Path $TempFile)) {
        try {
            Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "Cleaned up temporary file." "Green"
        }
        catch {
            # Silently ignore cleanup errors
        }
    }
}
