# Claude Desktop + DeepSeek One-Click Installer
$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Claude + DeepSeek Setup"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ====== Choose install location ======
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    Claude Desktop + DeepSeek  One-Click Setup" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Default install dir: $ScriptDir"
Write-Host "  (Press Enter for default, or type a custom path)"
Write-Host ""
$choice = Read-Host "  Install path"
if ($choice -and $choice.Trim() -ne "") {
    $InstallDir = $choice.Trim()
    if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
} else {
    $InstallDir = $ScriptDir
}

$DlDir = Join-Path ([System.IO.Path]::GetTempPath()) "ClaudeUSB_dl"
if (-not (Test-Path $DlDir)) { New-Item -ItemType Directory -Path $DlDir -Force | Out-Null }

$Mirrors = @("https://ghproxy.net/", "https://gh-proxy.com/", "https://ghproxy.com/", "https://ghfast.top/")

Write-Host ""
Write-Host "  Install Dir: $InstallDir"
Write-Host ""

# ====== Step 1: Find mirror ======
Write-Host "  >>> Step 1/5: Finding mirror..." -ForegroundColor Yellow
$Mirror = ""
foreach ($m in $Mirrors) {
    try { $null = Invoke-WebRequest $m -TimeoutSec 5 -UseBasicParsing; $Mirror = $m; Write-Host "  [OK] $Mirror" -ForegroundColor Green; break }
    catch { Write-Host "  [..] $m failed" -ForegroundColor Cyan }
}
if (-not $Mirror) { Write-Host "  [FAIL] All mirrors unreachable." -ForegroundColor Red; exit 1 }

# ====== Step 2: URLs ======
Write-Host "  >>> Step 2/5: Preparing URLs..." -ForegroundColor Yellow
$CCUrl = "https://github.com/farion1231/cc-switch/releases/download/v3.15.0/CC-Switch-v3.15.0-Windows-Portable.zip"
$CDUrl = "https://github.com/Qiao-920/claude-desktop-cn/releases/download/v1.6.30/Claude-Desktop-CN-Setup-1.6.30.exe"
Write-Host "  [OK] CCSwitch v3.15.0" -ForegroundColor Green
Write-Host "  [OK] Claude Desktop CN v1.6.30" -ForegroundColor Green

# ====== Step 3: Pre-check ======
$CCDir = Join-Path $InstallDir "CCSwitch"
$CDDir = Join-Path $InstallDir "ClaudeDesktop"
$ccInstalled = Get-ChildItem $CCDir -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
$cdInstalled = Test-Path (Join-Path $CDDir "Claude Desktop CN.exe")
$needCC = -not $ccInstalled
$needCD = -not $cdInstalled

# ====== Step 4: Download ======
if ($needCC -or $needCD) {
    $msg = "Downloading"
    if ($needCC -and $needCD) { $msg += " (~280MB)" }
    elseif ($needCC) { $msg += " CCSwitch (12MB)" }
    else { $msg += " Claude Desktop (200MB)" }
    Write-Host "  >>> Step 3/5: $msg..." -ForegroundColor Yellow
} else {
    Write-Host "  >>> Step 3/5: Both installed, skipping" -ForegroundColor Yellow
}

function Download-File($Url, $Path, $Label, [int]$MinMB = 1) {
    if ((Test-Path $Path) -and (Get-Item $Path).Length -gt ($MinMB * 1MB)) {
        Write-Host "  [SKIP] $Label cached" -ForegroundColor Cyan; return $true
    }
    if (Test-Path $Path) { Remove-Item $Path -Force }
    foreach ($m in $Mirrors) {
        Write-Host "  [..] $Label ($m) ..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri ($m + $Url) -OutFile $Path -TimeoutSec 1200 -UseBasicParsing
            $mb = [math]::Round((Get-Item $Path).Length / 1MB, 1)
            if ($mb -lt $MinMB) { Write-Host "  [WARN] $mb MB, retry..." -ForegroundColor Yellow; Remove-Item $Path -Force; continue }
            Write-Host "  [OK] $Label ($mb MB)" -ForegroundColor Green; return $true
        } catch { Write-Host "  [WARN] $($_.Exception.Message.Split(':')[0])" -ForegroundColor Yellow }
    }
    return $false
}

$CCZip   = Join-Path $DlDir "CCSwitch.zip"
$CDSetup = Join-Path $DlDir "ClaudeDesktop_Setup.exe"

$ok1 = $true; $ok2 = $true
if ($needCC) { $ok1 = Download-File -Url $CCUrl -Path $CCZip -Label "CCSwitch" -MinMB 10 }
if ($needCD) {
    if (Test-Path $CDSetup) { Remove-Item $CDSetup -Force }  # Nuke corrupt
    $ok2 = Download-File -Url $CDUrl -Path $CDSetup -Label "Claude Desktop CN" -MinMB 50
}
if (-not $ok1 -or -not $ok2) { Write-Host "  [FAIL] Download failed." -ForegroundColor Red; exit 1 }

# ====== Step 5: Install ======
Write-Host "  >>> Step 4/5: Installing..." -ForegroundColor Yellow

# --- CCSwitch ---
if ($ccInstalled) {
    Write-Host "  [SKIP] CCSwitch already installed" -ForegroundColor Cyan
} else {
    Write-Host "  [..] Extracting CCSwitch ..." -ForegroundColor Cyan
    # Nuke old
    cmd /c "rd /s /q `"$CCDir`" 2>NUL & del /f `"$CCDir`" 2>NUL"
    Start-Sleep 1
    $7za = Join-Path $DlDir "7za.exe"
    if (-not (Test-Path $7za)) {
        $7za = Join-Path $ScriptDir "7za.exe"
    }
    if (Test-Path $7za) {
        cmd /c "`"$7za`" x `"$CCZip`" -o`"$CCDir`" -y -mmt=on"
    } else {
        Expand-Archive -Path $CCZip -DestinationPath $CCDir -Force
    }
    Write-Host "  [OK] CCSwitch installed" -ForegroundColor Green
}

# --- Claude Desktop ---
if ($cdInstalled) {
    Write-Host "  [SKIP] Claude Desktop already installed" -ForegroundColor Cyan
} else {
    Write-Host "  [..] Extracting Claude Desktop CN (1-2 min)..." -ForegroundColor Cyan
    $7za = Join-Path $DlDir "7za.exe"
    if (-not (Test-Path $7za)) {
        $7za = Join-Path $ScriptDir "7za.exe"
    }
    if (-not (Test-Path $7za)) {
        Write-Host "  [..] Downloading 7-Zip..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest "https://www.7-zip.org/a/7za920.zip" -OutFile (Join-Path $DlDir "7za.zip") -TimeoutSec 120 -UseBasicParsing
            Expand-Archive (Join-Path $DlDir "7za.zip") -DestinationPath $DlDir -Force
            Remove-Item (Join-Path $DlDir "7za.zip") -Force
            $7za = Join-Path $DlDir "7za.exe"
        } catch { Write-Host "  [WARN] 7-Zip failed" -ForegroundColor Yellow }
    }
    if (Test-Path $7za) {
        Start-Process -FilePath $7za -ArgumentList "x", $CDSetup, "-o$CDDir", "-y", "-mmt=on" -Wait -NoNewWindow
    } else {
        Write-Host "  [..] Installer fallback..." -ForegroundColor Cyan
        Start-Process -FilePath $CDSetup -ArgumentList "/S" -Wait
        $def = "$env:LOCALAPPDATA\Programs\claude-desktop"
        if (Test-Path $def) { Copy-Item "$def\*" $CDDir -Recurse -Force }
    }
    if (-not (Test-Path (Join-Path $CDDir "Claude Desktop CN.exe"))) {
        $defs = @("$env:LOCALAPPDATA\Programs\claude-desktop", "$env:LOCALAPPDATA\claude-desktop")
        foreach ($d in $defs) {
            if (Test-Path $d) { Copy-Item "$d\*" $CDDir -Recurse -Force; break }
        }
    }
    if (-not (Test-Path (Join-Path $CDDir "Claude Desktop CN.exe"))) {
        Write-Host "  [FAIL] Claude.exe not found." -ForegroundColor Red; exit 1
    }
    Write-Host "  [OK] Claude Desktop CN installed" -ForegroundColor Green
}

# Save 7za locally for future runs
$local7za = Join-Path $InstallDir "7za.exe"
$src7za = Join-Path $DlDir "7za.exe"
if ((Test-Path $src7za) -and -not (Test-Path $local7za)) {
    Copy-Item $src7za $local7za -Force -ErrorAction SilentlyContinue
}

# Clean up downloads
Remove-Item $CCZip, $CDSetup -Force -ErrorAction SilentlyContinue

# ====== Step 6: Create scripts ======
Write-Host "  >>> Step 5/5: Creating launcher..." -ForegroundColor Yellow

# Launch script
@"
@echo off
title Claude + DeepSeek
for %%f in ("%~dp0CCSwitch\*.exe") do start "" "%%f"
timeout /t 5 /nobreak >nul
start "" "%~dp0ClaudeDesktop\Claude Desktop CN.exe"
exit
"@ | Out-File (Join-Path $InstallDir "launch.bat") -Encoding Default
Write-Host "  [OK] launch.bat" -ForegroundColor Green

# Uninstall script
@"
@echo off
chcp 65001 >nul
title Uninstall Claude + DeepSeek
echo.
echo   ============================================
echo     Uninstall Claude Desktop + DeepSeek
echo   ============================================
echo.
echo   This will permanently delete:
echo     - CCSwitch and all config
echo     - Claude Desktop and all config
echo     - Launch scripts
echo     - Desktop shortcut
echo     - Cached tools (7za.exe)
echo     - Temp download files
echo.
set /p X="  Type YES to confirm: "
if not "%X%"=="YES" (echo   Cancelled. & pause & exit /b)
echo.
echo   Stopping processes...
taskkill /f /im "CC Switch.exe" >nul 2>&1
taskkill /f /im "Claude.exe" >nul 2>&1
taskkill /f /im "Claude Desktop CN.exe" >nul 2>&1
timeout /t 2 /nobreak >nul

echo   Removing CCSwitch...
rd /s /q "%~dp0CCSwitch" 2>nul
if exist "%~dp0CCSwitch" ( del /f /q "%~dp0CCSwitch" 2>nul )

echo   Removing Claude Desktop...
rd /s /q "%~dp0ClaudeDesktop" 2>nul
if exist "%~dp0ClaudeDesktop" ( del /f /q "%~dp0ClaudeDesktop" 2>nul )

echo   Removing scripts...
del /q "%~dp0launch.bat" 2>nul & del /q "%~dp0uninstall.bat" 2>nul

echo   Removing cached tools...
del /q "%~dp07za.exe" 2>nul

echo   Removing desktop shortcut...
del /q "%USERPROFILE%\Desktop\Claude+DeepSeek.lnk" 2>nul

echo   Removing temp downloads...
rd /s /q "%TEMP%\ClaudeUSB_dl" 2>nul

echo.
echo   ============================================
echo     Uninstall complete!
echo   ============================================
echo.
echo   You may now delete this folder if desired.
echo   Remaining: 一键安装.bat / install.ps1 / 使用说明.md
echo.
pause
"@ | Out-File (Join-Path $InstallDir "uninstall.bat") -Encoding Default
Write-Host "  [OK] uninstall.bat" -ForegroundColor Green

# Desktop shortcut
try {
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut([Environment]::GetFolderPath("Desktop") + "\Claude+DeepSeek.lnk")
    $sc.TargetPath = Join-Path $InstallDir "launch.bat"
    $sc.WorkingDirectory = $InstallDir
    $sc.Save()
    Write-Host "  [OK] Desktop shortcut" -ForegroundColor Green
} catch {}

# Done
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "    Setup Complete!" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Next:"
Write-Host "  1. Get free API Key: platform.deepseek.com"
Write-Host "  2. Double-click launch.bat, then configure:"
Write-Host "     CCSwitch -> Add Provider -> DeepSeek -> paste key"
Write-Host "     Claude -> Developer -> Third-Party -> Gateway"
Write-Host "     URL: http://127.0.0.1:15721"
Write-Host ""

Start-Process "https://platform.deepseek.com"
