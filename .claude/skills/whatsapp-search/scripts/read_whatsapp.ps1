#!/usr/bin/env powershell
<#
.SYNOPSIS
    Read the latest message from WhatsApp Web via Chrome DevTools Protocol
.DESCRIPTION
    Connects to a Chrome instance with remote debugging enabled,
    finds the web.whatsapp.com tab, and reads the latest message
    using JavaScript injection via CDP.
.PARAMETER LaunchChrome
    If set, launch a new Chrome instance with remote debugging if not already running
.PARAMETER DebugPort
    CDP port (default: 9222)
.EXAMPLE
    .\read_whatsapp.ps1
    .\read_whatsapp.ps1 -LaunchChrome
    .\read_whatsapp.ps1 -DebugPort 9223
.NOTES
    Requires: Chrome running with --remote-debugging-port=9222
    Requires: web.whatsapp.com open and logged in
    Platform: Windows 11
#>

param(
    [switch]$LaunchChrome,
    [int]$DebugPort = 9222
)

$ChromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

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

function Is-CDPAvailable {
    param([int]$Port)
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:$Port/json" -UseBasicParsing -TimeoutSec 3
        return $resp.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Launch-ChromeWithCDP {
    param([int]$Port)
    $ChromePath = Find-Chrome
    if (-not $ChromePath) {
        Write-Host "ERROR: Chrome not found" -ForegroundColor Red
        exit 1
    }
    $UserDataDir = Join-Path $env:TEMP "chrome-whatsapp-profile"
    $Args = @(
        "--remote-debugging-port=$Port",
        "--user-data-dir=`"$UserDataDir`"",
        "https://web.whatsapp.com"
    )
    Write-Host "Starting Chrome with CDP on port $Port..." -ForegroundColor Yellow
    Start-Process -FilePath $ChromePath -ArgumentList $Args
    Write-Host "Please log in to WhatsApp Web by scanning the QR code." -ForegroundColor Yellow
    Write-Host "Then the script can read messages." -ForegroundColor Yellow
    exit 0
}

function Get-CDPResponse {
    param(
        [System.Net.WebSockets.ClientWebSocket]$WebSocket,
        [int]$CommandId,
        [int]$BufferSize = 65536
    )
    $Buffer = New-Object byte[] $BufferSize
    while ($true) {
        $ResponseText = ""
        $Result = $null
        do {
            $Segment = [System.ArraySegment[byte]]::new($Buffer)
            $Result = $WebSocket.ReceiveAsync($Segment, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
            $ResponseText += [System.Text.Encoding]::UTF8.GetString($Buffer, 0, $Result.Count)
        } while (-not $Result.EndOfMessage)
        $Parsed = $ResponseText | ConvertFrom-Json
        if ($Parsed.id -eq $CommandId) {
            return $Parsed
        }
    }
}

# ============================================
# MAIN
# ============================================

# Step 1: Check/launch Chrome CDP
if (-not (Is-CDPAvailable -Port $DebugPort)) {
    if ($LaunchChrome) {
        Launch-ChromeWithCDP -Port $DebugPort
    } else {
        Write-Host "ERROR: Chrome not available on port $DebugPort" -ForegroundColor Red
        Write-Host "Start Chrome with: chrome.exe --remote-debugging-port=$DebugPort" -ForegroundColor Yellow
        Write-Host "Or re-run with -LaunchChrome flag" -ForegroundColor Yellow
        exit 1
    }
}

# Step 2: Get targets
try {
    $Targets = Invoke-RestMethod -Uri "http://localhost:$DebugPort/json" -TimeoutSec 5
} catch {
    Write-Host "ERROR: Failed to connect to Chrome DevTools" -ForegroundColor Red
    exit 1
}

# Step 3: Find WhatsApp tab
$WhatsAppTarget = $Targets | Where-Object { $_.url -like "*web.whatsapp.com*" -and $_.url -notlike "*#*" }
if (-not $WhatsAppTarget) {
    Write-Host "ERROR: No WhatsApp Web tab found" -ForegroundColor Red
    Write-Host "Open https://web.whatsapp.com in Chrome and log in" -ForegroundColor Yellow
    exit 1
}

if ($WhatsAppTarget -is [array]) {
    $WhatsAppTarget = $WhatsAppTarget[0]
}

$WSURL = $WhatsAppTarget.webSocketDebuggerUrl
Write-Host "Found WhatsApp tab: $($WhatsAppTarget.title)" -ForegroundColor Cyan

# Step 4: Connect via WebSocket
$WS = [System.Net.WebSockets.ClientWebSocket]::new()
try {
    $WS.ConnectAsync([System.Uri]$WSURL, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
} catch {
    Write-Host "ERROR: WebSocket connection failed: $_" -ForegroundColor Red
    exit 1
}

# Step 5: JavaScript to get latest WhatsApp message
$JSCode = @"
(function() {
    try {
        var panel = document.querySelector('[data-testid="conversation-panel-messages"]');
        if (!panel) return JSON.stringify({error: 'Conversation panel not found. Open a chat.'});

        var bubbles = panel.querySelectorAll('[data-testid="conversation-message"]');
        if (!bubbles.length) return JSON.stringify({error: 'No messages found in this chat.'});

        var last = bubbles[bubbles.length - 1];
        var textEl = last.querySelector('.selectable-text.copyable-text, .selectable-text, span[dir="ltr"]');
        if (!textEl) return JSON.stringify({error: 'Could not extract text from the last message.'});

        return JSON.stringify({message: textEl.textContent.trim()});
    } catch(e) {
        return JSON.stringify({error: e.toString()});
    }
})();
"@

# Step 6: Send Runtime.evaluate command
$Command = @{
    id     = 1
    method = "Runtime.evaluate"
    params = @{
        expression    = $JSCode
        returnByValue = $false
    }
} | ConvertTo-Json -Compress

$CommandBytes = [System.Text.Encoding]::UTF8.GetBytes($Command)
$CommandSegment = [System.ArraySegment[byte]]::new($CommandBytes)
$WS.SendAsync($CommandSegment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()

# Step 7: Receive response
$ResponseObj = Get-CDPResponse -WebSocket $WS -CommandId 1

# Step 8: Close WebSocket
$WS.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
$WS.Dispose()

# Step 9: Parse response
if ($ResponseObj.error) {
    Write-Host "ERROR: CDP error: $($ResponseObj.error.message)" -ForegroundColor Red
    exit 1
}

$ResultValue = $ResponseObj.result.result.value
if (-not $ResultValue) {
    Write-Host "ERROR: Empty response from CDP" -ForegroundColor Red
    exit 1
}

$Parsed = $ResultValue | ConvertFrom-Json

if ($Parsed.error) {
    Write-Host "ERROR: $($Parsed.error)" -ForegroundColor Red
    exit 1
}

$Message = $Parsed.message
if ([string]::IsNullOrWhiteSpace($Message)) {
    Write-Host "ERROR: Empty message text" -ForegroundColor Red
    exit 1
}

Write-Host "Latest WhatsApp message: $Message" -ForegroundColor Green
Write-Output $Message
exit 0
