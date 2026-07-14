---
name: whatsapp-search
description: Read the latest message from WhatsApp Web and use it as a search term for Chrome search. The user writes a message on web.whatsapp.com (which must be open in Chrome with remote debugging enabled), the AI reads that message via Chrome DevTools Protocol, extracts the content, and performs a Google search using the chrome-search skill.
---

# WhatsApp Search Skill

## What This Skill Does

1. User opens Chrome at **web.whatsapp.com** (with remote debugging port `9222`)
2. User writes a message on WhatsApp (e.g., "kubernetes tutorial")
3. AI runs `read_whatsapp.ps1` to extract the latest message
4. AI uses the message text as the search term for the chrome-search skill

## Prerequisites

- Chrome must be started with remote debugging enabled:

```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
```

- web.whatsapp.com must be open and logged in in that Chrome window
- The latest message in WhatsApp will be read as the search term

## Execution Workflow

### Step 1 — Start Chrome with remote debugging (one-time setup)

Close all Chrome windows, then run:

```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
```

Then navigate to https://web.whatsapp.com and scan the QR code to log in.

### Step 2 — Read WhatsApp message

When the user asks to search based on their WhatsApp message:

```powershell
& "D:\claude\windowsautomation\.claude\skills\whatsapp-search\scripts\read_whatsapp.ps1"
```

### Step 3 — Search Chrome with the message text

Extract the message text from Step 2 and pass it to chrome-search:

```powershell
& "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "<MESSAGE_TEXT>"
```

## Full Example

1. User writes `"docker networking"` on WhatsApp
2. User says: *"read whatsapp and search"*
3. AI runs `read_whatsapp.ps1` → returns `"docker networking"`
4. AI runs `search_chrome.ps1 -SearchTerm "docker networking"`
5. Chrome opens with Google search results for "docker networking" ✅

## Notes

- The script reads the **last visible message** in the active WhatsApp chat
- If multiple chats are open, it reads from the currently focused chat
- The WhatsApp tab must be open and not in a loading/connecting state
