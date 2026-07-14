#!/usr/bin/env powershell
<#
.SYNOPSIS
    Install a Windows binary (.exe or .msi)
.DESCRIPTION
    Detects and silently installs an installer file from the bin/ subdirectory.
    Supports both .exe and .msi installers.
.PARAMETER BinaryName
    Name of the installer file in bin/. If omitted, auto-detects the first .exe or .msi.
.PARAMETER Silent
    Switch. Perform silent/unattended installation.
.PARAMETER LogPath
    Optional path to log file.
.EXAMPLE
    .\install_binary.ps1 -BinaryName "7zsetup.exe" -Silent
.EXAMPLE
    .\install_binary.ps1
.NOTES
    Requires: Windows 10/11, PowerShell
    Place installer files in the bin/ subdirectory.
#>

param(
    [string]$BinaryName = "",
    [switch]$Silent,
    [string]$LogPath = ""
)

# ============================================
# CONFIG
# ============================================

$SkillDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BinDir = Join-Path -Path $SkillDir -ChildPath "bin"

# ============================================
# FUNCTIONS
# ============================================

function Write-Log {
    param([string]$Message, [string]$ForegroundColor = "White")
    Write-Host $Message -ForegroundColor $ForegroundColor
    if ($LogPath) {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogPath -Value "$Timestamp | $Message"
    }
}

function Find-Installer {
    $Installers = @()
    if ($BinaryName) {
        $Path = Join-Path -Path $BinDir -ChildPath $BinaryName
        if (Test-Path $Path) {
            $Installers = @($Path)
        }
    } else {
        $Installers = @(Get-ChildItem -Path $BinDir -Include *.exe, *.msi -Recurse | Sort-Object LastWriteTime -Descending)
    }
    return $Installers
}

function Get-InstallerType {
    param([string]$Path)
    $Ext = [System.IO.Path]::GetExtension($Path).ToLower()
    return $Ext
}

function Install-Exe {
    param([string]$Path)
    Write-Log "Installing EXE: $Path" -ForegroundColor Cyan
    $ArgsList = @()
    if ($Silent) {
        $ArgsList = @("/S", "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART")
    }
    try {
        $Proc = Start-Process -FilePath $Path -ArgumentList $ArgsList -Wait -PassThru -NoNewWindow:$(-not $Silent)
        if ($Proc.ExitCode -eq 0) {
            Write-Log "Installation completed successfully (exit code: $($Proc.ExitCode))" -ForegroundColor Green
        } else {
            Write-Log "Installation finished with exit code: $($Proc.ExitCode)" -ForegroundColor Yellow
        }
        return $Proc.ExitCode
    } catch {
        Write-Log "ERROR: Failed to run installer: $_" -ForegroundColor Red
        return 1
    }
}

function Install-Msi {
    param([string]$Path)
    Write-Log "Installing MSI: $Path" -ForegroundColor Cyan
    $MsiArgs = @("/i", "`"$Path`"")
    if ($Silent) {
        $MsiArgs += "/quiet", "/norestart"
    }
    try {
        $Proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiArgs -Wait -PassThru -NoNewWindow
        if ($Proc.ExitCode -eq 0) {
            Write-Log "Installation completed successfully (exit code: $($Proc.ExitCode))" -ForegroundColor Green
        } else {
            Write-Log "Installation finished with exit code: $($Proc.ExitCode)" -ForegroundColor Yellow
        }
        return $Proc.ExitCode
    } catch {
        Write-Log "ERROR: Failed to run installer: $_" -ForegroundColor Red
        return 1
    }
}

# ============================================
# MAIN
# ============================================

# Validate bin directory
if (-not (Test-Path $BinDir)) {
    Write-Log "ERROR: bin directory not found at: $BinDir" -ForegroundColor Red
    Write-Log "Create the bin/ directory and place your installer files there." -ForegroundColor Yellow
    exit 1
}

# Find installer
$Installer = Find-Installer
if (-not $Installer) {
    Write-Log "ERROR: No installer found in: $BinDir" -ForegroundColor Red
    if ($BinaryName) {
        Write-Log "  (looked for: $BinaryName)" -ForegroundColor Yellow
    } else {
        Write-Log "  Place a .exe or .msi file in the bin/ directory." -ForegroundColor Yellow
    }
    exit 1
}

$InstallerPath = $Installer | Select-Object -First 1
Write-Log "Found installer: $InstallerPath" -ForegroundColor Cyan

# Check if running as admin
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Log "WARNING: Not running as Administrator. Some installers may fail." -ForegroundColor Yellow
}

# Detect type and install
$Type = Get-InstallerType -Path $InstallerPath
switch ($Type) {
    ".exe" { $ExitCode = Install-Exe -Path $InstallerPath }
    ".msi" { $ExitCode = Install-Msi -Path $InstallerPath }
    default {
        Write-Log "ERROR: Unsupported installer type: $Type" -ForegroundColor Red
        exit 1
    }
}

exit $ExitCode
