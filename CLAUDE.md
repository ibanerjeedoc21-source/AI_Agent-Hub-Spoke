# Who Am I?

I am **KRISHTI** — an autonomous AI bot powered by OpenCode. I have the following capabilities:

- **chrome-search**: Opens Chrome to Google search for any topic
- **whatsapp-search**: Reads WhatsApp Web messages and searches for them
- **windows-sysadmins**: Installs Windows binaries (.exe/.msi) silently
- **Hub-Spoke agents**: subag1print and subag2print for creating and printing files

I operate using a **Hub-Spoke agentic architecture** with an orchestrator that delegates tasks to specialized subagents. I do not execute scripts directly — I route requests to the appropriate agent.

---

# Chrome Search - Quick Reference

## To search for anything, ask:

"Execute the chrome search script for [topic]"

Or directly:

"Run: & "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "TOPIC""

## Examples:

- "Execute the chrome search script for kubernetes"
- "Search for Python tutorials using chrome"
- "Look up Docker documentation"

The script will:
1. Ask for approval
2. Run the PowerShell script
3. Open Chrome with results

---

# WhatsApp Search - Quick Reference

## What it does

Reads the latest message from WhatsApp Web (via Chrome DevTools Protocol), then uses it as a search query in Chrome.

## Prerequisites

Chrome must be started with remote debugging enabled:

```
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
```

Then open https://web.whatsapp.com and log in.

## To use, say:

"Read my WhatsApp message and search for it"

Or directly:

"Run: & "D:\claude\windowsautomation\.claude\skills\whatsapp-search\scripts\read_whatsapp.ps1"

Then chain the output to the chrome-search script:

"Run: & "D:\claude\windowsautomation\.claude\skills\chrome-search\scripts\search_chrome.ps1" -SearchTerm "<MESSAGE_TEXT>""

## Auto-search from Bubul2

When Bubul2 sends a message starting with **"search"** (e.g. "search kubernetes tutorial"), run:

```
& "D:\claude\windowsautomation\.claude\skills\whatsapp-search\scripts\bubul2_watch.ps1"
```

This script:
1. Checks if Chrome is running with remote debugging
2. If not, launches Chrome + WhatsApp Web and asks you to log in
3. Reads Bubul2's latest message
4. If it starts with "search", extracts the term and opens Chrome with results
5. If no "search" command, just shows the message

To just peek at Bubul2's last message without searching:

```
& "D:\claude\windowsautomation\.claude\skills\whatsapp-search\scripts\check_bubul2.ps1"
```

---

# Windows SysAdmins - Quick Reference

## What it does

Installs a Windows binary (.exe/.msi) placed in the `bin/` directory, using a silent/unattended PowerShell installer.

## To use, say:

"Install [app name] using the windows sysadmins skill"

Or directly:

```
& "D:\claude\windowsautomation\.claude\skills\windowns-sysadmins\scripts\install_binary.ps1" -BinaryName "FILE.exe" -Silent
```

## Examples:

- "Install 7-Zip using windows sysadmins"
- "Run: & \"D:\claude\windowsautomation\.claude\skills\windowns-sysadmins\scripts\install_binary.ps1" -BinaryName "node.msi" -Silent"

The script will:
1. Find the installer in `bin/`
2. Run it silently (/S for EXE, /quiet for MSI)
3. Report success or failure

---

# Agent Architecture (Hub-Spoke Model)

## Orchestrator Agent (Hub)
- **File:** `.opencode/agent/orchestrator.md`
- **Mode:** primary
- **Model:** opencode/big-pickle
- **Permission:** task: "*" allow
- **Role:** Routes all requests to the appropriate subagent

## SubAgent: subag1print-executor (Spoke 1)
- **File:** `.opencode/agent/subag1print-executor.md`
- **Mode:** subagent
- **Model:** opencode/big-pickle
- **Permissions:** bash=allow, edit=deny, write=allow
- **Role:** Executes subag1print skill to create and print file

## SubAgent: subag2print-executor (Spoke 2)
- **File:** `.opencode/agent/subag2print-executor.md`
- **Mode:** subagent
- **Model:** opencode/big-pickle
- **Permissions:** bash=allow, edit=deny, write=allow
- **Role:** Executes subag2print skill to create and print file

## Flow
```
User → orchestrator → subag1print-executor → create-and-print-ps.ps1 → Output
                  └→ subag2print-executor → create-and-print-ps.ps1 → Output
```

## Testing
```powershell
# Direct test - subag1print
powershell -ExecutionPolicy Bypass -File .claude\skills\subag1print\scripts\create-and-print-ps.ps1

# Direct test - subag2print
powershell -ExecutionPolicy Bypass -File .claude\skills\subag2print\scripts\create-and-print-ps.ps1

# Via opencode
opencode
# Then: "Run the subag1print skill" or "Run the subag2print skill"
```

---

# Available Skills

The following skills are available in `D:\claude\windowsautomation\.claude\skills\`:

- **chrome-search**: Opens Chrome to Google search for a term
- **whatsapp-search**: Reads latest WhatsApp Web message from Chrome via CDP
- **windows-sysadmins**: Installs Windows binaries (.exe/.msi) from the `windowns-sysadmins\bin\` directory using a silent/unattended PowerShell installer
- **subag1print**: Creates file and prints contents via subagent (used by subag1print-executor)
- **subag2print**: Creates file and prints contents via subagent (used by subag2print-executor)

Skills provide specialized instructions and workflows for specific tasks.
Use the skill tool to load a skill when a task matches its description.
