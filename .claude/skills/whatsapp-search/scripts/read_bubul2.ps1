$DebugPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

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

try {
    $targets = Invoke-RestMethod -Uri "http://localhost:9222/json" -TimeoutSec 5
    $wa = $targets | Where-Object { $_.url -like '*web.whatsapp.com*' }
    if (-not $wa) { exit 1 }
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
            Write-Output $parsed.texts[-1]
        }
    }
} catch {
    exit 1
}
