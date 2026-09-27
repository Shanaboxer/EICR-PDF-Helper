# DrSparX LaTeX helper installer for Windows.
# Registers the native-messaging host for Firefox and Chrome/Chromium/Brave/Edge.
# Run as your normal user (no admin needed).

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$HostName = "co.uk.drsparx.latex"
$Script = Join-Path $Here "drsparx_latex.py"
$FirefoxExtId = "forms@drsparx.co.uk"

$ChromeIdDefault = ""
$idFile = Join-Path $Here "CHROME_ID.txt"
if (Test-Path $idFile) { $ChromeIdDefault = (Get-Content $idFile -Raw).Trim() }

# locate python
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) { $python = (Get-Command py -ErrorAction SilentlyContinue).Source }
if (-not $python) { throw "Python 3 not found on PATH. Install it and re-run." }

# a .bat launcher so browsers can start the python host reliably
$Bat = Join-Path $Here "drsparx_latex.bat"
"@echo off`r`n`"$python`" `"$Script`" %*" | Set-Content -Encoding ASCII $Bat

Write-Host ""
Write-Host "Chrome/Edge/Brave need the extension's ID to trust the helper."
Write-Host "This build's fixed ID is: $ChromeIdDefault"
Write-Host "If yours differs, open the browser's Extensions page, turn on"
Write-Host "Developer mode, and read the ID under DrSparX Forms."
$ChromeId = Read-Host "Chrome extension ID [$ChromeIdDefault]"
if ([string]::IsNullOrWhiteSpace($ChromeId)) { $ChromeId = $ChromeIdDefault }

# --- Firefox manifest (allowed_extensions) ---
$FfManifest = Join-Path $Here "$HostName.firefox.json"
@{
  name = $HostName
  description = "DrSparX LaTeX compiler bridge"
  path = $Bat
  type = "stdio"
  allowed_extensions = @($FirefoxExtId)
} | ConvertTo-Json | Set-Content -Encoding ASCII $FfManifest
New-Item -Path "HKCU:\Software\Mozilla\NativeMessagingHosts\$HostName" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Mozilla\NativeMessagingHosts\$HostName" -Name "(default)" -Value $FfManifest
Write-Host "  Firefox registered."

# --- Chrome-family manifest (allowed_origins) ---
if (-not [string]::IsNullOrWhiteSpace($ChromeId)) {
  $CrManifest = Join-Path $Here "$HostName.chrome.json"
  @{
    name = $HostName
    description = "DrSparX LaTeX compiler bridge"
    path = $Bat
    type = "stdio"
    allowed_origins = @("chrome-extension://$ChromeId/")
  } | ConvertTo-Json | Set-Content -Encoding ASCII $CrManifest

  $roots = @(
    "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName",
    "HKCU:\Software\Chromium\NativeMessagingHosts\$HostName",
    "HKCU:\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\$HostName",
    "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$HostName"
  )
  foreach ($r in $roots) {
    New-Item -Path $r -Force | Out-Null
    Set-ItemProperty -Path $r -Name "(default)" -Value $CrManifest
  }
  Write-Host "  Chrome / Edge / Brave / Chromium registered."
}

Write-Host ""
Write-Host "Done. Fully quit your browser (all windows) and reopen it,"
Write-Host "then open the extension -> Settings -> Test connection."
