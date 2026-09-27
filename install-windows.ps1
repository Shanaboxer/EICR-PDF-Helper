# Register the DrSparX LaTeX native host with Firefox on Windows.
$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$HostName = "co.uk.drsparx.latex"
$ExtId = "forms@drsparx.co.uk"
$Script = Join-Path $Here "drsparx_latex.py"

$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) { $python = (Get-Command py -ErrorAction SilentlyContinue).Source }
if (-not $python) { throw "Python 3 not found on PATH. Install it and re-run." }

# A .bat launcher so Firefox can start the python host reliably.
$Bat = Join-Path $Here "drsparx_latex.bat"
"@echo off`r`n`"$python`" `"$Script`" %*" | Set-Content -Encoding ASCII $Bat

$Manifest = Join-Path $Here "$HostName.json"
@{
  name = $HostName
  description = "DrSparX LaTeX compiler bridge"
  path = $Bat
  type = "stdio"
  allowed_extensions = @($ExtId)
} | ConvertTo-Json | Set-Content -Encoding ASCII $Manifest

$Key = "HKCU:\Software\Mozilla\NativeMessagingHosts\$HostName"
New-Item -Path $Key -Force | Out-Null
Set-ItemProperty -Path $Key -Name "(default)" -Value $Manifest

Write-Host "Installed. Restart Firefox, then rebuild a certificate."
Write-Host "Engine label should read 'local XeLaTeX'."
