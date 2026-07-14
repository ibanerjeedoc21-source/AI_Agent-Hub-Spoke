$DebugPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

$ChromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

function Find-Chrome {
    foreach ($p in $ChromePaths) { if (Test-Path $p) { return $p } }
    return $null
}

function Is-CDPAvailable {
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:9222/json" -UseBasicParsing -TimeoutSec 3
        return $r.StatusCode -eq 200
    } catch { return $false }
}

function Launch-ChromeWhatsApp {
    $chrome = Find-Chrome
    if (-not $chrome) { Write-Host "Chrome not found"; exit 1 }
    $dir = Join-Path $env:TEMP "chrome-whatsapp-profile"
    Start-Process -FilePath $chrome -ArgumentList "--remote-debugging-port=9222", "--user-data-dir=`"$dir`"", "https://web.whatsapp.com"
}

function Get-CDPResponse {
    param($WS, $CmdId)
    $buf = New-Object byte[] 65536
    while ($true) {
        $txt = ''
        do {
            $seg = [System.ArraySegment[byte]]::new($buf)
            $r = $WS.ReceiveAsync($seg, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
            $txt += [System.Text.Encoding]::UTF8.GetString($buf, 0, $r.Count)
        } while (-not $r.EndOfMessage)
        $p = $txt | ConvertFrom-Json
        if ($p.id -eq $CmdId) { return $p }
    }
}

# Step 1: Ensure Chrome + WhatsApp
if (-not (Is-CDPAvailable)) {
    Write-Host "Starting Chrome with remote debugging..." -ForegroundColor Yellow
    Launch-ChromeWhatsApp
    Write-Host "Please log in to WhatsApp Web by scanning the QR code." -ForegroundColor Yellow
    Write-Host "Then send a message to Bubul2 starting with 'search' (e.g. 'search python tutorial')" -ForegroundColor Yellow
    exit 0
}

# Step 2: Read Bubul2's latest message
try {
    $targets = Invoke-RestMethod -Uri "http://localhost:9222/json" -TimeoutSec 5
    $wa = $targets | Where-Object { $_.url -like '*web.whatsapp.com*' }
    if (-not $wa) {
        Write-Host "WhatsApp Web tab not found. Opening it..." -ForegroundColor Yellow
        $chrome = Find-Chrome
        Start-Process -FilePath $chrome -ArgumentList "https://web.whatsapp.com"
        exit 0
    }
    if ($wa -is [array]) { $wa = $wa[0] }

    $WS = [System.Net.WebSockets.ClientWebSocket]::new()
    $null = $WS.ConnectAsync([System.Uri]$wa.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()

    $js = @'
(function() {
    var items = document.querySelectorAll('[data-testid="cell-frame-title"]');
    for (var i = 0; i < items.length; i++) {
        var name = items[i].textContent.trim();
        if (name === 'Bubul2') {
            var cellFrame = items[i].closest('[data-testid="cell-frame-container"]');
            var secondary = cellFrame ? cellFrame.querySelector('[data-testid="cell-frame-secondary"]') : null;
            var texts = [];
            if (secondary) {
                var walker = document.createTreeWalker(secondary, NodeFilter.SHOW_TEXT, null, false);
                while (walker.nextNode()) {
                    var t = walker.currentNode.textContent.trim();
                    if (t) texts.push(t);
                }
            }
            return JSON.stringify({texts: texts});
        }
    }
    return JSON.stringify({texts: []});
})();
'@

    $cmd = @{id=1;method='Runtime.evaluate';params=@{expression=$js;returnByValue=$false}} | ConvertTo-Json -Compress
    $b = [System.Text.Encoding]::UTF8.GetBytes($cmd)
    $null = $WS.SendAsync([System.ArraySegment[byte]]::new($b), ([System.Net.WebSockets.WebSocketMessageType]::Text), $true, ([System.Threading.CancellationToken]::None)).GetAwaiter().GetResult()
    $r = Get-CDPResponse -WS $WS -CmdId 1
    $null = $WS.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, 'Done', [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $WS.Dispose()

    if ($r.result.result.value) {
        $parsed = $r.result.result.value | ConvertFrom-Json
        if ($parsed.texts.Count -gt 0) {
            $msg = $parsed.texts[-1]
            Write-Host "Bubul2 says: $msg" -ForegroundColor Cyan

            if ($msg -match '(?i)^search\s+(?:for\s+)?(.+)$') {
                $term = $matches[1].Trim()
                Write-Host "Searching for: $term" -ForegroundColor Green
                $chrome = Find-Chrome
                if ($chrome) {
                    $url = "https://www.google.com/search?q=" + [System.Uri]::EscapeDataString($term)
                    Start-Process -FilePath $chrome -ArgumentList $url
                    Write-Host "Chrome opened with results" -ForegroundColor Green
                }
            } else {
                Write-Host "Message doesn't start with 'search'. No action taken." -ForegroundColor Yellow
            }
        } else {
            Write-Host "No messages from Bubul2 found" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
