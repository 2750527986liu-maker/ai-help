# Claude Desktop CN + DeepSeek One-Click Installer
# Pure ASCII - no Chinese characters (PS 5.1 GBK compatibility)

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Claude + DeepSeek Setup"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  ============================================"
Write-Host "    Claude Desktop CN + DeepSeek Installer"
Write-Host "  ============================================"
Write-Host ""

# -------- Install Path --------
Write-Host "  Default install path: $ScriptDir"
$choice = Read-Host "  Enter custom path (or press Enter for default)"
if ($choice -and $choice.Trim() -ne "") {
    $InstallDir = $choice.Trim()
} else {
    $InstallDir = $ScriptDir
}
$InstallDir = $InstallDir.TrimEnd('\')

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Host "  [OK] Created directory: $InstallDir"
}
Write-Host "  Install to: $InstallDir"
Write-Host ""

$CCDir   = Join-Path $InstallDir "CCSwitch"
$CDDir   = Join-Path $InstallDir "ClaudeDesktop"
$DlDir   = Join-Path ([System.IO.Path]::GetTempPath()) "ClaudeUSB_dl"

# -------- Check Already Installed --------
$ccInstalled = Test-Path (Join-Path $CCDir "CCSwitch.exe")
$cdInstalled = Test-Path (Join-Path $CDDir "Claude Desktop CN.exe")

if ($ccInstalled -and $cdInstalled) {
    Write-Host "  [OK] Already installed."
    Write-Host "  Run launch.bat to start."
    exit 0
}

if (-not (Test-Path $DlDir)) { New-Item -ItemType Directory -Path $DlDir -Force | Out-Null }

# -------- Mirror Config --------
$ghM = @("https://ghproxy.net/", "https://gh-proxy.com/", "https://ghproxy.com/", "https://ghfast.top/", "")

$urls7z = @("https://www.7-zip.org/a/7za920.zip")

$repoCD = "Qiao-920/claude-desktop-cn"
$verCD  = "v1.6.30"
$urlsCD = @()
foreach ($m in $ghM) { $urlsCD += "${m}https://github.com/${repoCD}/releases/download/${verCD}/Claude-Desktop-CN-${verCD}-Setup.exe" }

$repoCC = "farion1231/CCSwitch"
$verCC  = "v3.15.0"
$urlsCC = @()
foreach ($m in $ghM) { $urlsCC += "${m}https://github.com/${repoCC}/releases/download/${verCC}/CCSwitch_Windows_X64.zip" }

# -------- Find Best Mirror --------
Write-Host "  Testing mirrors..."
$chosen = ""
foreach ($u in $ghM) {
    $testUrl = "${u}https://github.com/farion1231/CCSwitch/releases/download/v3.15.0/CCSwitch_Windows_X64.zip"
    try {
        $req = [System.Net.HttpWebRequest]::Create($testUrl)
        $req.Method = "HEAD"
        $req.Timeout = 5000
        $req.AllowAutoRedirect = $true
        $resp = $req.GetResponse()
        $code = [int]$resp.StatusCode
        $resp.Close()
        if ($code -eq 200) { $chosen = $u; break }
    } catch { }
}
if ($chosen -eq "") { $chosen = $ghM[$ghM.Count - 1] }
if ($chosen -ne "") { Write-Host "  [OK] Mirror: $chosen" }
else { Write-Host "  [OK] Using direct GitHub" }
Write-Host ""

# -------- Download Function --------
function Get-File($name, $urls, $outName) {
    $outPath = Join-Path $DlDir $outName
    if (Test-Path $outPath) {
        $sz = (Get-Item $outPath).Length
        if ($sz -gt 1024) { Write-Host "  [OK] ${name} cached"; return $outPath }
        Remove-Item $outPath -Force
    }
    $fullUrls = @()
    foreach ($u in $urls) {
        if ($chosen -ne "" -and $u -notmatch "^https?://github\.com") {
            $fullUrls += $u
        } elseif ($chosen -eq "" -and $u -match "^https?://github\.com") {
            $fullUrls += $u
        }
    }
    if ($fullUrls.Count -eq 0) { $fullUrls = $urls }
    foreach ($url in $fullUrls) {
        Write-Host "  [..] Downloading ${name}..."
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url, $outPath)
            $wc.Dispose()
            $sz = (Get-Item $outPath).Length
            if ($sz -gt 1024) {
                Write-Host "  [OK] ${name} ($([math]::Round($sz/1MB,1)) MB)"
                return $outPath
            }
            Remove-Item $outPath -Force
        } catch { }
    }
    Write-Host "  [FAIL] ${name} download failed"
    return $null
}

# -------- Download All --------
$z7 = Get-File "7-Zip" $urls7z "7za920.zip"
if (-not $z7) { Write-Host "FATAL: 7-Zip required"; exit 1 }

$z7exe = Join-Path $DlDir "7za.exe"
if (-not (Test-Path $z7exe)) {
    $sys7z = Join-Path $DlDir "7z.exe"
    if (Test-Path $sys7z) { $z7exe = $sys7z }
}

$cdExe = Get-File "Claude Desktop CN" $urlsCD "ClaudeDesktop-CN.exe"
if (-not $cdExe) { Write-Host "FATAL: Claude Desktop CN required"; exit 1 }

$ccZip = Get-File "CCSwitch" $urlsCC "CCSwitch.zip"
if (-not $ccZip) { Write-Host "FATAL: CCSwitch required"; exit 1 }

# -------- Extract 7za.exe --------
if (-not (Test-Path $z7exe)) {
    Write-Host "  [..] Extracting 7za.exe..."
    $z7Out = Join-Path $DlDir "7z_tmp"
    if (Test-Path $z7Out) { Remove-Item $z7Out -Recurse -Force }
    cmd /c "powershell -c `"Expand-Archive -Path '$z7' -DestinationPath '$z7Out' -Force`""
    $found = Get-ChildItem -Path $z7Out -Filter "7za.exe" -Recurse | Select-Object -First 1
    if ($found) {
        Copy-Item $found.FullName $z7exe -Force
        Remove-Item $z7Out -Recurse -Force
        Write-Host "  [OK] 7za.exe ready"
    } else {
        Write-Host "  [FAIL] Cannot find 7za.exe in archive"
        exit 1
    }
}

# -------- Extract CCSwitch --------
if (-not $ccInstalled) {
    Write-Host "  [..] Extracting CCSwitch..."
    cmd /c "rd /s /q `"$CCDir`" 2>NUL & del /f `"$CCDir`" 2>NUL"
    Start-Sleep 1
    cmd /c "`"$z7exe`" x `"$ccZip`" -o`"$CCDir`" -y -mmt=on"
    if (Test-Path (Join-Path $CCDir "CCSwitch.exe")) {
        Write-Host "  [OK] CCSwitch ready"
    } else {
        Write-Host "  [FAIL] CCSwitch extraction failed"
        exit 1
    }
} else {
    Write-Host "  [OK] CCSwitch cached"
}

# -------- Install Claude Desktop CN --------
if (-not $cdInstalled) {
    Write-Host "  [..] Installing Claude Desktop CN..."
    $cdNSIS = Join-Path $DlDir "ClaudeDesktop-CN.exe"
    if (Test-Path $cdNSIS) {
        cmd /c "rd /s /q `"$CDDir`" 2>NUL"
        cmd /c "`"$z7exe`" x `"$cdNSIS`" -o`"$CDDir`" -y -mmt=on"
        if (Test-Path (Join-Path $CDDir "Claude Desktop CN.exe")) {
            Write-Host "  [OK] Claude Desktop CN installed"
        } else {
            $exe = Get-ChildItem -Path $CDDir -Filter "*.exe" -Recurse | Where-Object { $_.Name -match "Claude" } | Select-Object -First 1
            if ($exe) {
                Write-Host "  [OK] Claude Desktop CN installed ($($exe.Name))"
            } else {
                Write-Host "  [FAIL] Claude Desktop CN extraction failed"
                exit 1
            }
        }
    } else {
        Write-Host "  [FAIL] Claude Desktop CN installer not found"
        exit 1
    }
} else {
    Write-Host "  [OK] Claude Desktop CN cached"
}
Write-Host ""

# -------- Generate Launch Script (Absolute Paths) --------
$launchContent = @"
@echo off
title Claude + DeepSeek
echo Starting CCSwitch...
start "" "$CCDir\CCSwitch.exe"
echo Waiting for CCSwitch to initialize...
timeout /t 5 /nobreak >nul
echo Starting Claude Desktop CN...
start "" "$CDDir\Claude Desktop CN.exe"
exit
"@
$launchPath = Join-Path $InstallDir "launch.bat"
Set-Content -Path $launchPath -Value $launchContent -Encoding ASCII
Write-Host "  [OK] Created launch.bat"

# -------- Generate Uninstall Script (Absolute Paths) --------
$uninstallContent = @"
@echo off
echo.
echo   Claude + DeepSeek Uninstaller
echo   ==============================
echo.
echo   Install location: $InstallDir
echo.
choice /c YN /m "   Confirm uninstall? (Y/N)"
if errorlevel 2 goto :eof
echo.
echo   Killing processes...
taskkill /f /im CCSwitch.exe >nul 2>&1
taskkill /f /im "Claude Desktop CN.exe" >nul 2>&1
taskkill /f /im "Claude.exe" >nul 2>&1
echo   Removing CCSwitch...
rd /s /q "$CCDir" 2>nul
echo   Removing Claude Desktop CN...
rd /s /q "$CDDir" 2>nul
echo   Removing downloads...
rd /s /q "$DlDir" 2>nul
echo   Removing desktop shortcut...
del /f "%USERPROFILE%\Desktop\Claude + DeepSeek.lnk" 2>nul
echo   Removing scripts...
del /f "$InstallDir\launch.bat" 2>nul
del /f "$InstallDir\uninstall.bat" 2>nul
del /f "$InstallDir\7za.exe" 2>nul
echo.
echo   Done!
pause
"@
$uninstallPath = Join-Path $InstallDir "uninstall.bat"
Set-Content -Path $uninstallPath -Value $uninstallContent -Encoding ASCII
Write-Host "  [OK] Created uninstall.bat"

# -------- Desktop Shortcut --------
$shortcutDir = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $shortcutDir "Claude + DeepSeek.lnk"
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($shortcutPath)
$sc.TargetPath = $launchPath
$sc.WorkingDirectory = $InstallDir
$sc.IconLocation = Join-Path $CDDir "Claude Desktop CN.exe,0"
$sc.Save()
Write-Host "  [OK] Desktop shortcut created"

Write-Host ""
Write-Host "  ============================================"
Write-Host "    Setup Complete!"
Write-Host "    Launch: launch.bat or desktop shortcut"
Write-Host "    Uninstall: uninstall.bat"
Write-Host "  ============================================"
Write-Host ""
