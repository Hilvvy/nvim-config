# Editor data stays portable; project languages and environments belong to the PC.
$ErrorActionPreference = 'Stop'
$check = $args.Count -eq 1 -and $args[0] -eq '--hilvim-check'
$bundle = Split-Path $PSScriptRoot -Parent
$env:HILVIM_PORTABLE = '1'
$env:HILVIM_ROOT = $bundle
$env:HILVIM_HOST_TOOLS = '1'
$env:NVIM_APPNAME = 'nvim'
foreach ($entry in @{
    XDG_CONFIG_HOME = 'config'; XDG_DATA_HOME = 'data'
    XDG_STATE_HOME = 'state'; XDG_CACHE_HOME = 'cache'
}.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($entry.Key, (Join-Path $bundle $entry.Value), 'Process')
}
$env:XDG_CONFIG_DIRS = $env:XDG_CONFIG_HOME
$env:XDG_DATA_DIRS = $env:XDG_DATA_HOME
# Do not replace LOCALAPPDATA, APPDATA, JAVA_HOME, DOTNET_ROOT, VIRTUAL_ENV,
# NuGet locations or Git configuration: use the developer's installed tools.
$env:TEMP = Join-Path $bundle 'temp'
$env:TMP = $env:TEMP
foreach ($path in @($env:XDG_STATE_HOME, $env:XDG_CACHE_HOME, $env:TEMP)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}
foreach ($name in @('VIM', 'VIMRUNTIME', 'LUA_PATH', 'LUA_CPATH', 'NVIM', 'NVIM_LISTEN_ADDRESS')) {
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}
$bins = @('tools/nvim/bin', 'tools/bin', 'data/nvim-data/mason/bin')
$env:Path = (($bins | ForEach-Object { Join-Path $bundle $_ }) -join ';') + ';' + $env:Path
# Git, Node, Python and project toolchains all come from the host PATH.
$nvim = Join-Path $bundle 'tools/nvim/bin/nvim.exe'
if ($check) {
    & $nvim --headless -i NONE -c 'lua dofile(vim.env.HILVIM_ROOT .. [[/scripts/check-editor.lua]])'
} else {
    & $nvim @args
}
exit $LASTEXITCODE
