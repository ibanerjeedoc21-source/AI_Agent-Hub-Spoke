#!/usr/bin/env powershell
<#
.SYNOPSIS
    Open Chrome and search Google for a term
.DESCRIPTION
    Automatically opens Chrome with a Google search for the provided term
    URL-encodes special characters automatically
.PARAMETER SearchTerm
    The term to search for (required)
.PARAMETER Site
    Optional: Restrict search to a specific domain (e.g., github.com, stackoverflow.com)
.PARAMETER InPrivate
    Optional: Open in incognito/private mode
.EXAMPLE
    .\search-chrome.ps1 -SearchTerm "Kubernetes documentation"
    .\search-chrome.ps1 -SearchTerm "Python tutorials" -Site "github.com"
    .\search-chrome.ps1 -SearchTerm "Docker" -InPrivate
.NOTES
    Requires: Google Chrome installed
    Platform: Windows 11
#>

param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$SearchTerm,
    
    [string]$Site = "",
    
    [switch]$InPrivate,
    
    [switch]$LogSearch
)

# ============================================
# CONFIG
# ============================================

$ChromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

$LogPath = "C:\Logs\chrome-searches-$(Get-Date -Format 'yyyy-MM-dd').log"

# ============================================
# FUNCTIONS
# ============================================

function Find-Chrome {
    foreach ($Path in $ChromePaths) {
        if (Test-Path $Path) {
            return $Path
        }
    }
    return $null
}

function Encode-SearchTerm {
    param([string]$Term)
    return [System.Uri]::EscapeDataString($Term)
}

function Log-Search {
    param(
        [string]$SearchTerm,
        [string]$GoogleURL
    )
    
    if (-not (Test-Path "C:\Logs")) {
        New-Item -ItemType Directory -Path "C:\Logs" -Force | Out-Null
    }
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp | Search: $SearchTerm | URL: $GoogleURL"
    Add-Content -Path $LogPath -Value $LogEntry
}

function Build-GoogleURL {
    param(
        [string]$Term,
        [string]$Site
    )
    
    $EncodedTerm = Encode-SearchTerm $Term
    
    if ($Site) {
        $EncodedSite = $Site -replace '\s', ''
        return "https://www.google.com/search?q=site:$EncodedSite+$EncodedTerm"
    } else {
        return "https://www.google.com/search?q=$EncodedTerm"
    }
}

# ============================================
# MAIN
# ============================================

# Validate Chrome installation
$ChromePath = Find-Chrome
if (-not $ChromePath) {
    Write-Host "ERROR: Chrome is not installed" -ForegroundColor Red
    Write-Host "Please install Google Chrome from: https://www.google.com/chrome/" -ForegroundColor Yellow
    exit 1
}

# Build Google URL
$GoogleURL = Build-GoogleURL -Term $SearchTerm -Site $Site

# Log if requested
if ($LogSearch) {
    Log-Search -SearchTerm $SearchTerm -GoogleURL $GoogleURL
}

# Build Chrome arguments
$ChromeArgs = @($GoogleURL)

if ($InPrivate) {
    $ChromeArgs = @("-inprivate", $GoogleURL)
}

# Open Chrome
try {
    Write-Host "Searching for: '$SearchTerm'" -ForegroundColor Cyan
    if ($Site) {
        Write-Host "  (restricted to: $Site)" -ForegroundColor Gray
    }
    
    Start-Process -FilePath $ChromePath -ArgumentList $ChromeArgs -ErrorAction Stop
    Write-Host "Checkmark Chrome opened successfully" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Failed to open Chrome" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

exit 0