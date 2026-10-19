$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent)).TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $source 'bundle.json'))) { throw 'Incomplete Hilvim package.' }
$localData = [Environment]::GetFolderPath('LocalApplicationData')
$destination = Join-Path $localData 'HilvimPortable'
if (Test-Path -LiteralPath $destination) {
    $destination += '-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6)
}
$destination = [IO.Path]::GetFullPath($destination)
if ($destination.StartsWith($source + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Cannot install inside the source package.' }
Write-Host "Copying Hilvim to $destination ..."
& robocopy.exe $source $destination /E /XJ /MT:8 /R:1 /W:1 /NFL /NDL /NJH /NJS /NP /XD (Join-Path $source 'cache') (Join-Path $source 'state') (Join-Path $source 'user') (Join-Path $source 'temp') (Join-Path $source 'config/github-copilot') (Join-Path $source 'config/gh')
if ($LASTEXITCODE -ge 8) { throw "Copy failed (robocopy $LASTEXITCODE)." }
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'Hilvim.lnk'
if (Test-Path -LiteralPath $shortcutPath) {
    $shortcutPath = Join-Path $desktop ('Hilvim-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.lnk')
}
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $destination 'Hilvim.cmd'
$shortcut.WorkingDirectory = $env:USERPROFILE
$shortcut.IconLocation = (Join-Path $destination 'tools/nvim/bin/nvim.exe') + ',0'
$shortcut.Save()
Write-Host "Ready. Open the desktop shortcut: $shortcutPath"
Write-Host 'Uninstall: close Hilvim and remove its own folder and shortcut. Your other Neovim configuration is untouched.'
