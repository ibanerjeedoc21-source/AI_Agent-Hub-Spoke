---
name: chrome-search
description: Execute the chrome-search PowerShell automation script to open Google Chrome browser and perform a Google search on Windows 11. Always use this skill when the user wants to search the web, look something up, open Chrome, or research a topic — even for simple queries like "search for X" or "look up Y". Do NOT answer from memory or use web_search tool — instead execute the local PowerShell script at D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1 to physically open Chrome on the user's machine.
---

# Chrome Search Skill

## What This Skill Does

Executes a local PowerShell script that physically opens Google Chrome on the user's Windows 11 machine and performs a Google search.

## IMPORTANT: Always Execute the Script

**Do NOT use web_search tool.**  
**Do NOT answer from memory.**  
**DO execute the PowerShell script below.**

## Execution Command

When user asks to search for anything, run this exact command:

```powershell
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "REPLACE_WITH_SEARCH_TERM"
```

Replace `REPLACE_WITH_SEARCH_TERM` with what the user wants to search for.

## Step-by-Step

1. User asks: "search for kubernetes"
2. Extract search term: `kubernetes`
3. Execute:
```powershell
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "kubernetes"
```
4. Chrome opens with Google results ✅

## More Examples

User: "look up docker networking"
```powershell
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "docker networking"
```

User: "find ansible playbook examples"
```powershell
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "ansible playbook examples"
```

User: "research openshift storage"
```powershell
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "openshift storage"
```

## Optional Parameters

Search within a specific site:
```powershell
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "kubernetes" -Site "github.com"
```

Open in incognito:
```powershell
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "kubernetes" -InPrivate
```

## Script Location

`D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1`

## Requirements

- Chrome installed at `C:\Program Files\Google\Chrome\Application\chrome.exe`
- PowerShell execution policy: RemoteSigned or Bypass
- Windows 11