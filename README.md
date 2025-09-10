# MinGW-w64 (g++) Compiler Installation Scripts

This repository contains automated scripts to install MinGW-w64 (g++) compiler on Windows systems.

## 🚀 Quick Start (One-Liner Installation)

### Option 1: Direct Installation from GitHub (Recommended)

**Copy and paste this command into PowerShell:**

```powershell
irm https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1 | iex
```

This command will:
- Download the installation script directly from GitHub
- Execute it immediately 
- Install g++ for the current user (no admin required)
- No need to clone the repository

**Requirements for one-liner:**
- Windows PowerShell 5.1+ or PowerShell Core 7+
- Internet connection
- Execution policy that allows remote scripts

**If you get execution policy errors:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**For system-wide installation (requires admin):**
```powershell
irm https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1 | iex -Args "-SystemWide"
```

**Alternative one-liner with parameter:**
```powershell
# User-only installation (default)
iwr -useb https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1 | iex

# System-wide installation
iwr -useb https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1 | iex -Args "-SystemWide"
```

> **🔒 Security Note:** The one-liner downloads and executes a script from the internet. While convenient, always verify the source and content before running. You can inspect the script first by visiting the GitHub URL in your browser.

### Option 2: Download and Run Locally

```powershell
# Download the repository first, then run:

# Run as regular user (installs for current user only)
.\install-gcc.ps1

# Run as Administrator (installs system-wide)
.\install-gcc.ps1 -SystemWide

# Skip installation if already installed, just fix PATH
.\install-gcc.ps1 -SkipInstall
```

### Option 3: Batch Script (Simple)

```cmd
# Double-click or run from command prompt
install-gcc.bat
```

## What These Scripts Do

1. **Install MSYS2** via winget (Microsoft package manager)
2. **Install MinGW-w64 GCC toolchain** via MSYS2's pacman package manager
3. **Add compiler to PATH** environment variable
4. **Verify installation** by testing g++ command

## Requirements

- Windows 10 version 1809 or later (for winget)
- Internet connection
- Administrator privileges (recommended, but not required for user-only installation)

## Script Options

### PowerShell Script Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-SystemWide` | Install for all users (requires admin) | `false` |
| `-UserOnly` | Install for current user only | `true` |
| `-SkipInstall` | Skip installation, just fix PATH | `false` |
| `-Verbose` | Show detailed output | `false` |

### Examples

**One-liner installations:**
```powershell
# Quick install (user-only)
irm https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1 | iex

# System-wide install (as admin)
irm https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1 | iex -Args "-SystemWide"
```

**Local script executions:**
```powershell
# Install for current user only (no admin required)
.\install-gcc.ps1 -UserOnly

# Install system-wide (requires admin)
.\install-gcc.ps1 -SystemWide

# Just fix PATH if already installed
.\install-gcc.ps1 -SkipInstall

# Verbose output
.\install-gcc.ps1 -Verbose
```

## After Installation

1. **Restart your terminal/IDE** to pick up PATH changes
2. **Test the installation**:
   ```bash
   g++ --version
   ```
3. **Run your Python test case generator** - it should now work!

## Troubleshooting

### "g++ is not recognized"
- Restart your terminal/IDE completely
- Try running the script as Administrator
- Check if `C:\msys64\ucrt64\bin` is in your PATH

### "winget is not available"
- Install "App Installer" from Microsoft Store
- Update Windows to the latest version

### "Access denied" errors
- Run PowerShell as Administrator
- Or use `-UserOnly` flag for user-only installation

### Execution Policy Issues (PowerShell)
- Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Or use the batch script instead

## Manual Installation

If the scripts don't work, you can install manually:

1. Download MSYS2 from: https://www.mingw-w64.org/
2. Install MinGW-w64 toolchain
3. Add `C:\msys64\ucrt64\bin` to your PATH

## What Gets Installed

- **MSYS2**: Development environment for Windows
- **MinGW-w64**: Minimalist GNU for Windows (64-bit)
- **GCC**: GNU Compiler Collection
- **g++**: C++ compiler
- **Supporting libraries**: All necessary dependencies

## File Locations

After installation:
- MSYS2: `C:\msys64\`
- Compiler: `C:\msys64\ucrt64\bin\g++.exe`
- Libraries: `C:\msys64\ucrt64\lib\`
- Headers: `C:\msys64\ucrt64\include\`

## Uninstallation

### Automated Uninstall (Recommended)

**One-liner uninstall:**
```powershell
irm https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/uninstall.ps1 | iex
```

**Local uninstall scripts:**
```powershell
# PowerShell script (recommended)
# Complete removal (removes MSYS2 and cleans PATH)
.\uninstall.ps1

# Remove from PATH only, keep MSYS2
.\uninstall.ps1 -KeepMSYS2

# System-wide removal (requires admin)
.\uninstall.ps1 -SystemWide

# Force removal without prompts
.\uninstall.ps1 -Force
```

```cmd
# Batch script (simple alternative)
uninstall.bat
```

### Manual Uninstall

If the script doesn't work:
1. Uninstall MSYS2 via Windows Settings → Apps
2. Remove `C:\msys64\ucrt64\bin` from your PATH
3. Delete `C:\msys64` directory if it remains

## 🎯 TL;DR - Just Want g++ Working?

**Copy this into PowerShell and press Enter:**
```powershell
irm https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1 | iex
```

**Then restart your terminal and test:**
```bash
g++ --version
```

That's it! 🎉

## License

These scripts are provided as-is for educational purposes. MinGW-w64 and GCC are licensed under their respective open-source licenses.
