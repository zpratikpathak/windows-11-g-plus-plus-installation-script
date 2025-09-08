# Windows G++ Installation Script

A PowerShell script to automatically install g++ (GCC) compiler on Windows using winget. This script handles administrator privileges, provides visual progress feedback, and sets up a complete C++ development environment.

## 🚀 Features

- ✅ **Automatic Admin Elevation**: Automatically requests administrator privileges if needed
- ✅ **Progress Indicators**: Visual progress bar during downloads
- ✅ **MinGW-w64 Installation**: Installs the latest GCC compiler
- ✅ **CMake Support**: Optional CMake installation for build systems
- ✅ **Environment Setup**: Automatically configures PATH variables
- ✅ **Verification Testing**: Tests the installation with a sample compilation
- ✅ **Multiple Installation Options**: Choose from different MinGW variants
- ✅ **Robust Cleanup**: Automatically cleans up temporary files, even if interrupted
- ✅ **Interruption Safe**: Handles Ctrl+C, window closing, and unexpected exits gracefully

## 📋 Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Internet connection
- Windows Package Manager (winget) - comes pre-installed on Windows 11 and newer Windows 10 versions

## 🔧 Execution Policy Setup

If you encounter execution policy errors, you may need to allow script execution:

### Temporary Solution (Recommended)
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Permanent Solution (Use with caution)
```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
```

**Note**: The temporary solution only affects the current PowerShell session and is safer.

## ⚡ Quick Installation

### Method 1: One-Line Install (Recommended)

Open PowerShell (normal mode) and run:

```powershell
irm https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1 | iex
```


### Method 2: Download and Run

1. Download the script:
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zpratikpathak/windows-11-g-plus-plus-installation-script/home/install.ps1" -OutFile "install.ps1"
   ```

2. Run the script:
   ```powershell
   .\install.ps1
   ```

### Method 3: Manual Download

1. Download `install.ps1` from: https://github.com/zpratikpathak/windows-11-g-plus-plus-installation-script/blob/home/install.ps1
2. Save it to your desired location
3. Open PowerShell in that directory
4. Run: `.\install.ps1`



## 📝 Usage Options

### Basic Installation
```powershell
.\install.ps1
```

### Skip CMake Installation
```powershell
.\install.ps1 -SkipCMake
```

### Verbose Mode (Show available packages)
```powershell
.\install.ps1 -Verbose
```

### Custom MinGW Variant
```powershell
.\install.ps1 -MinGWVariant "BrechtSanders.WinLibs.MCF.UCRT"
```

### Combined Options
```powershell
.\install.ps1 -SkipCMake -Verbose
```

## 🎯 Available MinGW Variants

| Variant | Description | Recommended For |
|---------|-------------|-----------------|
| `BrechtSanders.WinLibs.POSIX.UCRT` | **Default** - POSIX threads, UCRT runtime | General development |
| `BrechtSanders.WinLibs.MCF.UCRT` | MCF threads, UCRT runtime | Advanced threading |
| `MartinStorsjo.LLVM-MinGW.UCRT` | LLVM/Clang based | LLVM ecosystem |

## 📖 Command Line Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `-SkipCMake` | Switch | Skip CMake installation | `false` |
| `-Verbose` | Switch | Show available MinGW packages | `false` |
| `-MinGWVariant` | String | Specify MinGW package ID | `BrechtSanders.WinLibs.POSIX.UCRT` |

## 🔍 What Gets Installed

1. **MinGW-w64**: Complete GCC compiler suite including:
   - `gcc` - C compiler
   - `g++` - C++ compiler
   - `gdb` - GNU debugger
   - Standard libraries and headers

2. **CMake** (optional): Cross-platform build system

3. **Environment Configuration**: Automatic PATH setup

## ✅ Verification

After installation, verify everything works:

```powershell
# Check compiler version
g++ --version

# Check CMake (if installed)
cmake --version

# Compile a test program
echo '#include <iostream>' > test.cpp
echo 'int main() { std::cout << "Hello World!" << std::endl; return 0; }' >> test.cpp
g++ -std=c++17 test.cpp -o test.exe
.\test.exe
```

## 🛠️ Example Usage

### Compile a Simple C++ Program
```powershell
g++ -std=c++17 myprogram.cpp -o myprogram.exe
```

### Compile with Debug Information
```powershell
g++ -std=c++17 -g myprogram.cpp -o myprogram.exe
```

### Using CMake
```powershell
mkdir build
cd build
cmake ..
cmake --build .
```

## 🐛 Troubleshooting

### UAC Prompt Appears and Disappears
- **Issue**: UAC prompt shows briefly then disappears when using `irm | iex`
- **Cause**: Script is automatically handling elevation (this is normal behavior)
- **Solution**: Wait for the UAC prompt and click "Yes" - the script will continue in an elevated session

### Script Won't Run
- **Issue**: "Execution policy" error
- **Solution**: Run `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

### g++ Not Found After Installation
- **Issue**: `g++` command not recognized
- **Solution**: Restart your PowerShell/Command Prompt or reboot your computer

### Download Fails
- **Issue**: Network or firewall blocking download
- **Solution**: Try manual download method or check your internet connection

### Installation Hangs
- **Issue**: Download appears stuck
- **Solution**: Wait up to 15 minutes (large download ~250MB) or restart the script

## 🔒 Security Notes

- This script automatically elevates to administrator privileges (required for software installation)
- Only downloads software from official Microsoft winget repositories
- All packages are verified and signed

## 📜 License

This project is open source. Feel free to modify and distribute.

## 🤝 Contributing

Found a bug or want to improve the script? 
1. Fork the repository
2. Create your feature branch
3. Submit a pull request

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Ensure you have the latest version of Windows
3. Verify winget is installed: `winget --version`
4. Open an issue on GitHub with error details

---

**Happy Coding! 🎉**
