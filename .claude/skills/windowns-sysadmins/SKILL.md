---
name: windows-sysadmins
description: Install Windows binaries (.exe/.msi) using a PowerShell automation script. Place the installer file in the bin/ subdirectory, then run the script to detect and silently install it. Use this skill whenever the user asks to install a Windows application, tool, or binary — e.g., "install 7-Zip", "install Node.js", "install Python".
---

# Windows SysAdmins - Binary Installer Skill

## What This Skill Does

Installs a Windows binary (.exe or .msi) from the skill's `bin/` directory using a local PowerShell script. Supports silent/unattended installation.

## Usage

Place the installer file (e.g., `7zsetup.exe` or `node.msi`) inside:

```
D:\claude\windowsautomation\.claude\skills\windowns-sysadmins\bin\
```

Then run:

```powershell
& "D:\claude\windowsautomation\.claude\skills\windowns-sysadmins\scripts\install_binary.ps1" -BinaryName "filename.exe"
```

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-BinaryName` | No | Name of the installer file in `bin/`. If omitted, auto-detects the first .exe or .msi found. |
| `-Silent` | No | Switch. Perform silent/unattended installation. |
| `-LogPath` | No | Path to installation log file. |

## Examples

Install a specific binary silently:
```powershell
& "D:\claude\windowsautomation\.claude\skills\windowns-sysadmins\scripts\install_binary.ps1" -BinaryName "7zsetup.exe" -Silent
```

Auto-detect and install:
```powershell
& "D:\claude\windowsautomation\.claude\skills\windowns-sysadmins\scripts\install_binary.ps1"
```

Install with logging:
```powershell
& "D:\claude\windowsautomation\.claude\skills\windowns-sysadmins\scripts\install_binary.ps1" -BinaryName "node.msi" -Silent -LogPath "C:\Logs\node-install.log"
```

## Requirements

- Windows 10/11
- PowerShell execution policy: RemoteSigned or Bypass
- Installer file placed in the `bin/` subdirectory
