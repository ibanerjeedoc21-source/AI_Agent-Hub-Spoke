$msg = & "D:\claude\windowsautomation\.claude\skills\whatsapp-search\scripts\read_bubul2.ps1"
if ([string]::IsNullOrWhiteSpace($msg)) {
    exit 1
}
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm $msg
