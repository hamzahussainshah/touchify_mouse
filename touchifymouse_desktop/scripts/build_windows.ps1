# ─────────────────────────────────────────────────────────────
#  TouchifyMouse — Windows Installer Builder
#  Usage:  powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1
#  Output: dist\TouchifyMouse-Setup.exe  (requires Inno Setup)
# ─────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$AppName    = "TouchifyMouse"
$PubspecRaw = Get-Content "pubspec.yaml" | Where-Object { $_ -match "^version:" }
$Version    = ($PubspecRaw -split ":")[1].Trim().Trim("'")
$BuildDir   = "build\windows\x64\runner\Release"
$DistDir    = "dist"

Write-Host "─────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  Building $AppName v$Version (Windows)"
Write-Host "─────────────────────────────────────" -ForegroundColor Cyan

# 1. Flutter release build
Write-Host "→ flutter build windows --release"
flutter build windows --release

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

# 2. Check for Inno Setup
$InnoPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (Test-Path $InnoPath) {
    Write-Host "→ Building installer with Inno Setup…"
    & $InnoPath "scripts\windows_installer.iss"
    Write-Host ""
    Write-Host "✅  Installer: dist\${AppName}-${Version}-setup.exe"
} else {
    # Fallback: just zip the build output
    Write-Host "Inno Setup not found — creating zip instead."
    Write-Host "Install from: https://jrsoftware.org/isdl.php"
    $ZipPath = "$DistDir\${AppName}-${Version}-windows.zip"
    Compress-Archive -Path "$BuildDir\*" -DestinationPath $ZipPath -Force
    Write-Host "✅  Zip: $ZipPath"
}
