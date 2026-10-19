# Deployment regression check. Uses new temporary directories, never the live config.
$ErrorActionPreference = 'Stop'
$testRoot = Join-Path $env:TEMP ('hilvim-install-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$target = Join-Path $testRoot 'config'
$data = Join-Path $testRoot 'data'
$installer = Join-Path (Split-Path $PSScriptRoot -Parent) 'install.ps1'
& powershell -NoProfile -File $installer -ConfigPath $target -DataPath $data -SkipDependencies -SkipRoslyn -SkipBootstrap
if ($LASTEXITCODE) { throw 'Initial deploy failed' }
foreach ($file in @('init.lua', 'asciiart.txt', 'lua/plugins/appearance.lua', 'scripts/bootstrap.lua')) {
    if (-not (Test-Path -LiteralPath (Join-Path $target $file))) { throw "Missing copied file: $file" }
}
if (Test-Path -LiteralPath (Join-Path $target '.codex')) { throw 'Local notes leaked into install' }
$ErrorActionPreference = 'Continue'
& powershell -NoProfile -File $installer -ConfigPath $target -DataPath $data -SkipDependencies -SkipRoslyn -SkipBootstrap 2>&1 | Out-String | Write-Host
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -eq 0) { throw 'Existing config was overwritten without BackupExisting' }
$hash = (Get-FileHash -LiteralPath (Join-Path $target 'init.lua')).Hash
& powershell -NoProfile -File $installer -ConfigPath $target -DataPath $data -SkipDependencies -SkipRoslyn -SkipBootstrap -BackupExisting
if ($LASTEXITCODE) { throw 'Backup deploy failed' }
$backup = @(Get-ChildItem -LiteralPath $testRoot -Directory -Filter 'config.backup-*')
if ($backup.Count -ne 1) { throw 'Expected exactly one backup' }
if ((Get-FileHash -LiteralPath (Join-Path $backup[0].FullName 'init.lua')).Hash -ne $hash) { throw 'Backup content changed' }
Write-Output "INSTALLER_CHECK_OK: deployment, overwrite refusal, backup integrity; fixtures at $testRoot"
