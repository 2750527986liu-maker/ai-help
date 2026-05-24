# Claude Desktop + DeepSeek Portable (No VPN Needed)

One-click portable installer for Claude Desktop + DeepSeek on Windows. Runs from USB, no installation, no VPN required.

## What it does

- Downloads and installs **CCSwitch** (API gateway) and **Claude Desktop CN** (Chinese-localized)
- Routes DeepSeek API through CCSwitch to Claude Desktop
- Fully portable — copy the folder to USB and run anywhere

## Quick Start

1. Double-click `一键安装.bat`
2. Wait ~5 minutes for download and setup
3. Get a free API Key at [platform.deepseek.com](https://platform.deepseek.com)
4. Double-click `launch.bat` and configure:
   - CCSwitch: Add Provider → DeepSeek → paste API Key
   - Claude Desktop: Developer → Third-Party Inference → Gateway → `http://127.0.0.1:15721`

## Requirements

- Windows 10/11
- Internet connection (uses ghproxy mirrors, works in China)
- Free DeepSeek API Key

## Uninstall

Double-click `uninstall.bat`, type `YES` to confirm.

## Files

| File | Purpose |
|------|---------|
| `一键安装.bat` | One-click installer entry |
| `install.ps1` | PowerShell install script |
| `使用说明.md` | Chinese user guide |

Installed apps (`CCSwitch/`, `ClaudeDesktop/`) and generated scripts (`launch.bat`, `uninstall.bat`) are not tracked by git.
