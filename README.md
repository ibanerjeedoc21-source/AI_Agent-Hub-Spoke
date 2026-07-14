<div align="center">

# AI-Agent-Hub_sopke  : The capabilities 1. Chromesearch 2. Whatsappsearch  3. Windowssysadmin not mapped with AI agent -Hubspoke

### Autonomous AI Bot for Windows Automation

![Platform](https://img.shields.io/badge/Platform-Windows%2011-blue?style=flat-square)
![Powered_by](https://img.shields.io/badge/Powered%20by-OpenCode-black?style=flat-square)
![Architecture](https://img.shields.io/badge/Architecture-Hub--Spoke-green?style=flat-square)
![Shell](https://img.shields.io/badge/Shell-PowerShell-purple?style=flat-square)

---

An autonomous AI agent built on the **Hub-Spoke agentic architecture**. It routes tasks to specialized subagents — never executing scripts directly, but orchestrating them intelligently.

[Quick Start](#quick-start) • [Features](#features) • [Architecture](#architecture) • [Skills](#skills) • [Setup](#setup)

---

</div>

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Skills](#skills)
  - [Chrome Search](#chrome-search)
  - [WhatsApp Search](#whatsapp-search)
  - [Windows SysAdmins](#windows-sysadmins)
  - [Hub-Spoke Agents](#hub-spoke-agents)
- [Quick Start](#quick-start)
- [Setup & Prerequisites](#setup--prerequisites)
- [Project Structure](#project-structure)
- [Examples](#examples)

---

## Features

| Feature | Description |
|---------|-------------|
| **Chrome Search** | Open Chrome and perform Google searches via PowerShell automation |
| **WhatsApp Search** | Read WhatsApp Web messages through Chrome DevTools Protocol (CDP) |
| **Windows SysAdmins** | Silent/unattended installation of `.exe` and `.msi` binaries |
| **Hub-Spoke Agents** | Delegated file creation & printing via specialized subagents |
| **Auto-Watch Mode** | Monitor WhatsApp for commands and auto-execute searches |

---

## Architecture

KRISHTI uses a **Hub-Spoke model** where an orchestrator routes all requests to the appropriate subagent:

```
                         ┌─────────────────────────┐
                         │         USER            │
                         └───────────┬─────────────┘
                                     │
                                     ▼
                         ┌─────────────────────────┐
                         │     ORCHESTRATOR (Hub)  │
                         │   Routes & Delegates    │
                         └─────┬──────────┬────────┘
                               │          │
              ┌────────────────┘          └────────────────┐
              ▼                                            ▼
┌──────────────────────┐                  ┌──────────────────────┐
│  subag1print-executor│                  │  subag2print-executor│
│      (Spoke 1)       │                  │      (Spoke 2)       │
└──────────┬───────────┘                  └──────────┬───────────┘
           │                                          │
           ▼                                          ▼
┌──────────────────────┐                  ┌──────────────────────┐
│  create-and-print.ps1│                  │  create-and-print.ps1│
│   → Output + Print   │                  │   → Output + Print   │
└──────────────────────┘                  └──────────────────────┘
```

### Agent Details

| Agent | Mode | Model | Permissions |
|-------|------|-------|-------------|
| **Orchestrator** | primary | `opencode/big-pickle` | `task: "*" allow` |
| **subag1print-executor** | subagent | `opencode/big-pickle` | `bash=allow, edit=deny, write=allow` |
| **subag2print-executor** | subagent | `opencode/big-pickle` | `bash=allow, edit=deny, write=allow` |

---

## Skills

### Chrome Search

Open Chrome and perform a Google search on any topic.

**Usage:**
```
"Search for kubernetes documentation"
"Look up Python tutorials"
"Execute the chrome search script for docker"
```

**How it works:**
1. Prompts for approval
2. Executes the PowerShell script
3. Opens Chrome with search results

---

### WhatsApp Search

Read the latest message from WhatsApp Web (via Chrome DevTools Protocol) and use it as a search query.

**Prerequisites:**
```powershell
# Launch Chrome with remote debugging
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
# Then open https://web.whatsapp.com and log in
```

**Usage:**
```
"Read my WhatsApp message and search for it"
```

**Auto-Watch from Bubul2:**
```powershell
# Watch for "search" commands from Bubul2
& "D:\claude\windowsautomation\.claude\skills\whatsapp-search\scripts\bubul2_watch.ps1"

# Just peek at Bubul2's last message
& "D:\claude\windowsautomation\.claude\skills\whatsapp-search\scripts\check_bubul2.ps1"
```

---

### Windows SysAdmins

Silently install Windows binaries (`.exe` / `.msi`) from the `bin/` directory.

**Usage:**
```
"Install 7-Zip using windows sysadmins"
"Install Node.js using windows sysadmins"
```

**Direct execution:**
```powershell
& "D:\claude\windowsautomation\.claude\skills\windowns-sysadmins\scripts\install_binary.ps1" -BinaryName "FILE.exe" -Silent
```

**How it works:**
1. Finds the installer in `bin/`
2. Runs silently (`/S` for EXE, `/quiet` for MSI)
3. Reports success or failure

---

### Hub-Spoke Agents

Create files and print their contents via delegated subagents.

**Direct testing:**
```powershell
# Test subag1print
powershell -ExecutionPolicy Bypass -File .claude\skills\subag1print\scripts\create-and-print-ps.ps1

# Test subag2print
powershell -ExecutionPolicy Bypass -File .claude\skills\subag2print\scripts\create-and-print-ps.ps1
```

**Via OpenCode:**
```bash
opencode
# Then: "Run the subag1print skill" or "Run the subag2print skill"
```

---

## Quick Start

### 1. Clone & Navigate
```powershell
cd D:\claude\windowsautomation
```

### 2. Run OpenCode
```bash
opencode
```

### 3. Start Using KRISHTI
```
"Search for Docker documentation"
"Install 7-Zip using windows sysadmins"
"Run the subag1print skill"
```

---

## Setup & Prerequisites

| Requirement | Details |
|-------------|---------|
| **OS** | Windows 11 |
| **Shell** | PowerShell 5.1+ |
| **Runtime** | OpenCode with `big-pickle` model |
| **Chrome** | For WhatsApp search, enable `--remote-debugging-port=9222` |

---

## Project Structure

```
D:\claude\windowsautomation\
├── CLAUDE.md                          # Agent instructions & skill reference
├── README.md                          # This file
├── .opencode/
│   └── agent/
│       ├── orchestrator.md            # Hub agent config
│       ├── subag1print-executor.md    # Spoke 1 config
│       └── subag2print-executor.md    # Spoke 2 config
└── .claude/
    └── skills/
        ├── chrome-search/             # Chrome search automation
        │   └── scripts/
        │       └── search_chrome.ps1
        ├── whatsapp-search/           # WhatsApp Web CDP integration
        │   └── scripts/
        │       ├── read_whatsapp.ps1
        │       ├── bubul2_watch.ps1
        │       └── check_bubul2.ps1
        ├── windowns-sysadmins/        # Silent installer
        │   ├── bin/
        │   └── scripts/
        │       └── install_binary.ps1
        ├── subag1print/               # SubAgent 1 skill
        │   └── scripts/
        │       └── create-and-print-ps.ps1
        └── subag2print/               # SubAgent 2 skill
            └── scripts/
                └── create-and-print-ps.ps1
```

---

## Examples

| Command | What Happens |
|---------|--------------|
| *"Search for Python tutorials"* | Chrome opens with Google search results |
| *"Install 7-Zip"* | 7-Zip silently installed from `bin/` |
| *"Run subag1print"* | File created + printed via SubAgent 1 |
| *"Run both subagents"* | Both spokes execute in parallel |
| *"Read my WhatsApp"* | Last WhatsApp message read via CDP |

---
---
### Git Command
 git add .
 git commit -m "AI Agent Upload "
 git push 

 To clearn Prev Creadential 

echo "protocol=https
host=github.com" | git credential-manager erase

####
---
<div align="center">

**Built with OpenCode** • **Powered by `big-pickle`** • **Hub-Spoke Architecture**

</div>
