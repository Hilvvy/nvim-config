#requires -Version 5.1
[CmdletBinding()]
param([string]$BundlePath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'dist/Hilvim-Portable'))
$ErrorActionPreference = 'Stop'
$BundlePath = [IO.Path]::GetFullPath($BundlePath).TrimEnd('\', '/')
if (-not (Test-Path -LiteralPath (Join-Path $BundlePath 'bundle.json'))) { throw 'Missing bundle.json.' }
foreach ($name in @('Hilvim.cmd', 'Comprobar.cmd', 'Instalar-en-esta-PC.cmd', 'scripts/launch.ps1')) {
    if (-not (Test-Path -LiteralPath (Join-Path $BundlePath $name))) { throw "Incomplete package: $name" }
}
$zipPath = $BundlePath + '.zip'
if (Test-Path -LiteralPath $zipPath) { throw "Archive already exists: $zipPath" }
$leaf = Split-Path $BundlePath -Leaf
Write-Host 'Creating clean portable ZIP (excluding state, credentials, caches and temp)...'
& tar.exe -a -cf $zipPath --options zip:compression-level=1 --exclude "$leaf/cache" --exclude "$leaf/state" --exclude "$leaf/user" --exclude "$leaf/temp" --exclude "$leaf/config/github-copilot" --exclude "$leaf/config/gh" -C (Split-Path $BundlePath -Parent) $leaf
if ($LASTEXITCODE) { throw 'ZIP creation failed.' }
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText($zipPath + '.sha256', $hash + '  ' + [IO.Path]::GetFileName($zipPath) + [Environment]::NewLine)
Write-Host "ZIP_READY: $zipPath"
Write-Host "SHA256: $hash"
