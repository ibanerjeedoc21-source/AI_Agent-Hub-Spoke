---
name: subag1print
description: Creates a test file & prints its contents in PowerShell + opens CMD window to display file content.
---
Run scripts/create-and-print-ps.ps1 using:
powershell -ExecutionPolicy Bypass -File .claude/skills/subag1print/scripts/create-and-print-ps.ps1

This writes ps-output.txt into the scripts folder, prints its content
inline via Get-Content, and opens a CMD window showing the file content.
