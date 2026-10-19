# Environment changes apply only to this process and its children.
$Check = $args.Count -eq 1 -and $args[0] -eq '--hilvim-check'
$NvimArguments = $args
$ErrorActionPreference = 'Stop'
$bundle = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path -LiteralPath (Join-Path $bundle 'bundle.json'))) { throw 'Incomplete Hilvim bundle.' }
$env:HILVIM_PORTABLE = '1'
$env:HILVIM_ROOT = $bundle
$env:NVIM_APPNAME = 'nvim'
$env:XDG_CONFIG_HOME = Join-Path $bundle 'config'
$env:XDG_DATA_HOME = Join-Path $bundle 'data'
$env:XDG_STATE_HOME = Join-Path $bundle 'state'
$env:XDG_CACHE_HOME = Join-Path $bundle 'cache'
$env:XDG_CONFIG_DIRS = $env:XDG_CONFIG_HOME
$env:XDG_DATA_DIRS = $env:XDG_DATA_HOME
$env:LOCALAPPDATA = Join-Path $bundle 'user/local'
$env:APPDATA = Join-Path $bundle 'user/roaming'
$env:TEMP = Join-Path $bundle 'temp'
$env:TMP = $env:TEMP
$env:JAVA_HOME = Join-Path $bundle 'tools/java'
$env:DOTNET_ROOT = Join-Path $bundle 'tools/dotnet'
$env:DOTNET_ROOT_X64 = $env:DOTNET_ROOT
$env:DOTNET_MULTILEVEL_LOOKUP = '0'
$env:DOTNET_CLI_HOME = Join-Path $bundle 'user/dotnet'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_NOLOGO = '1'
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE = 'false'
$env:DOTNET_CLI_WORKLOAD_UPDATE_NOTIFY_DISABLE = 'true'
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'
$env:DOTNET_ADD_GLOBAL_TOOLS_TO_PATH = '0'
$env:MSBuildSDKsPath = ''
$env:DOTNET_HOST_PATH = ''
$env:DOTNET_MSBUILD_SDK_RESOLVER_CLI_DIR = ''
$env:NUGET_PACKAGES = Join-Path $bundle 'user/nuget/packages'
$env:PYTHONHOME = ''
$env:PYTHONNOUSERSITE = '1'
$env:PYTHONPATH = ''
$env:VIRTUAL_ENV = ''
$env:PYTHONSTARTUP = ''
$env:NODE_PATH = ''
$env:GIT_CONFIG_GLOBAL = Join-Path $bundle 'user/gitconfig'
$env:GIT_CONFIG_NOSYSTEM = '1'
$env:GIT_EXEC_PATH = Join-Path $bundle 'tools/git/mingw64/libexec/git-core'
$env:GIT_TEMPLATE_DIR = Join-Path $bundle 'tools/git/mingw64/share/git-core/templates'
$env:npm_config_cache = Join-Path $bundle 'user/npm-cache'
$env:npm_config_prefix = Join-Path $bundle 'user/npm'
$env:NODE_REPL_HISTORY = Join-Path $bundle 'user/node_repl_history'
$env:VIM = ''
$env:VIMRUNTIME = ''
$env:LUA_PATH = ''
$env:LUA_CPATH = ''
$env:NVIM = ''
$env:NVIM_LISTEN_ADDRESS = ''
$bins = @('tools/nvim/bin', 'tools/bin', 'tools/git/cmd', 'tools/git/mingw64/bin', 'tools/git/usr/bin',
    'tools/node', 'tools/python', 'tools/python/Scripts', 'tools/java/bin',
    'tools/dotnet', 'tools/gcc/bin', 'data/nvim-data/mason/bin')
$env:Path = (($bins | ForEach-Object { Join-Path $bundle $_ }) -join ';') +
    ";$env:SystemRoot\System32;$env:SystemRoot;$env:SystemRoot\System32\WindowsPowerShell\v1.0"
foreach ($path in @($env:XDG_STATE_HOME, $env:XDG_CACHE_HOME, $env:LOCALAPPDATA,
    $env:APPDATA, $env:TEMP, $env:DOTNET_CLI_HOME)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}
$nvim = Join-Path $bundle 'tools/nvim/bin/nvim.exe'
if ($Check) {
    & $nvim --headless -i NONE -c 'lua dofile(vim.env.HILVIM_ROOT .. [[/scripts/check-portable.lua]])'
} else {
    & $nvim @NvimArguments
}
exit $LASTEXITCODE
