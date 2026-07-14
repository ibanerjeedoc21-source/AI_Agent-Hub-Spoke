---
description: Runs the subag1print skill — creates a file, prints in PowerShell, and opens CMD window to display content.
mode: subagent
model: opencode/big-pickle
permission:
  bash: allow
  edit: deny
  write: allow
---
Before executing, read .claude/skills/subag1print/SKILL.md for usage
instructions. Then run:
powershell -ExecutionPolicy Bypass -File .claude/skills/subag1print/scripts/create-and-print-ps.ps1
A CMD window will open to display file content. Report stdout/stderr exactly as returned.
