#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'dist/Hilvim-Portable'),
    [switch]$Zip,
    [switch]$Resume,
    [string]$JdkPath
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$source = Split-Path $PSScriptRoot -Parent
$OutputPath = [IO.Path]::GetFullPath($OutputPath).TrimEnd('\', '/')
if ($OutputPath -eq $source -or $source.StartsWith($OutputPath + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Output must not be the source checkout or one of its parents.' }
if (Test-Path -LiteralPath $OutputPath) {
    $existing = Get-Item -LiteralPath $OutputPath -Force
    if (-not $existing.PSIsContainer -or ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Output must be a normal directory.' }
    if ($Resume -and -not (Test-Path -LiteralPath (Join-Path $OutputPath 'LEEME.txt'))) { throw 'Resume requires an existing Hilvim build.' }
}
if ((Test-Path -LiteralPath $OutputPath) -and -not $Resume) { throw "Output already exists: $OutputPath. Choose a new directory or use -Resume for your unfinished build." }
if ($env:OS -ne 'Windows_NT' -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'Build on Windows x64.' }
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
    [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path
$data = Join-Path $env:LOCALAPPDATA 'nvim-data'
$downloads = Join-Path (Split-Path $OutputPath -Parent) 'downloads'
New-Item -ItemType Directory -Force -Path $downloads | Out-Null
function Tool([string]$Name) {
    $command = Get-Command $Name -ErrorAction Stop
    return $command.Source
}
function Copy-Tree([string]$From, [string]$To, [string[]]$Exclude = @()) {
    if (-not (Test-Path -LiteralPath $From)) { throw "Missing build input: $From" }
    New-Item -ItemType Directory -Force -Path $To | Out-Null
    $options = @($From, $To, '/E', '/XJ', '/MT:8', '/R:1', '/W:1', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/XD', '.git', '__pycache__') + $Exclude
    & robocopy.exe @options | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Copy failed: $From -> $To (robocopy $LASTEXITCODE)" }
}
function Copy-ToolDirectory([string]$Name, [string]$Folder) {
    Copy-Tree (Split-Path (Tool $Name) -Parent) (Join-Path $OutputPath "tools/$Folder")
}
foreach ($name in @('nvim', 'git', 'rg', 'fd', 'lazygit', 'tree-sitter', 'gcc', 'node', 'python', 'dotnet', 'curl.exe')) {
    $null = Tool $name
}
Write-Host 'Building portable Hilvim from installed, verified tools...'
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
$config = Join-Path $OutputPath 'config/nvim'
New-Item -ItemType Directory -Path $config -Force | Out-Null
foreach ($name in @('init.lua', 'lua', 'asciiart.txt', 'lazy-lock.json', 'lazyvim.json', '.neoconf.json', 'README.md', 'LICENSE')) {
    if ($name -eq 'lua') { Copy-Tree (Join-Path $source $name) (Join-Path $config $name) }
    else { Copy-Item -LiteralPath (Join-Path $source $name) -Destination $config -Force }
}
$scripts = Join-Path $OutputPath 'scripts'
New-Item -ItemType Directory -Force -Path $scripts | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'portable/launch.ps1') -Destination $scripts
Copy-Item -LiteralPath (Join-Path $source 'portable/check-portable.lua') -Destination $scripts
Copy-Item -LiteralPath (Join-Path $source 'portable/install-local.ps1') -Destination $scripts
foreach ($name in @('Hilvim.cmd', 'Comprobar.cmd', 'Instalar-en-esta-PC.cmd')) {
    Copy-Item -LiteralPath (Join-Path $source "portable/$name") -Destination $OutputPath
}
Copy-Item -LiteralPath (Join-Path $source 'portable/LEEME.txt') -Destination $OutputPath
Write-Host 'Copying editor, Git and native tools...'
Copy-Tree (Split-Path (Split-Path (Tool 'nvim') -Parent) -Parent) (Join-Path $OutputPath 'tools/nvim')
$gitRoot = Split-Path (Split-Path (Tool 'git') -Parent) -Parent
Copy-Tree $gitRoot (Join-Path $OutputPath 'tools/git')
# GCC needs its complete relocatable toolchain, not just gcc.exe.
$gccRoot = Split-Path (Split-Path (Tool 'gcc') -Parent) -Parent
Copy-Tree $gccRoot (Join-Path $OutputPath 'tools/gcc')
Copy-ToolDirectory 'node' 'node'
$nodeVersion = (& (Tool 'node') --version).Trim()
$nodeLicense = Join-Path $OutputPath 'tools/node/LICENSE'
if (-not (Test-Path -LiteralPath $nodeLicense)) {
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/nodejs/node/$nodeVersion/LICENSE" -OutFile $nodeLicense -TimeoutSec 30
}
$bin = Join-Path $OutputPath 'tools/bin'
New-Item -ItemType Directory -Path $bin -Force | Out-Null
foreach ($name in @('rg', 'fd', 'lazygit', 'tree-sitter')) {
    $exe = Tool $name
    Copy-Item -LiteralPath $exe -Destination (Join-Path $bin "$name.exe")
    # Preserve distributed license notices alongside standalone binaries.
    $notices = Join-Path $OutputPath "licenses/$name"
    New-Item -ItemType Directory -Force -Path $notices | Out-Null
    Get-ChildItem -LiteralPath (Split-Path $exe -Parent) -File |
        Where-Object { $_.Name -match 'LICENSE|COPYING|NOTICE' } |
        Copy-Item -Destination $notices
}

Write-Host 'Preparing relocatable Python...'
$pythonRoot = Split-Path (Tool 'python') -Parent
$pythonDest = Join-Path $OutputPath 'tools/python'
New-Item -ItemType Directory -Force -Path $pythonDest | Out-Null
Get-ChildItem -LiteralPath $pythonRoot -File | Copy-Item -Destination $pythonDest
Copy-Tree (Join-Path $pythonRoot 'Lib') (Join-Path $pythonDest 'Lib') @('site-packages')
Copy-Tree (Join-Path $pythonRoot 'DLLs') (Join-Path $pythonDest 'DLLs')
$pythonPackages = Join-Path $pythonDest 'Lib/site-packages'
$debugpyReceipt = Get-Content -Raw -LiteralPath (Join-Path $data 'mason/packages/debugpy/mason-receipt.json') | ConvertFrom-Json
$debugpyVersion = ($debugpyReceipt.source.id -split '@')[-1]
Copy-Tree (Join-Path $data 'mason/packages/debugpy/venv/Lib/site-packages/debugpy') (Join-Path $pythonPackages 'debugpy')
Copy-Tree (Join-Path $data "mason/packages/debugpy/venv/Lib/site-packages/debugpy-$debugpyVersion.dist-info") (Join-Path $pythonPackages "debugpy-$debugpyVersion.dist-info")
$ruffArchive = Join-Path $downloads 'ruff-native.zip'
$ruffHash = 'd77fb4ed36392337d334bf9bcef1c5d91ec221e96c53ae8aa147e922c71ddb64'
if (-not (Test-Path -LiteralPath $ruffArchive) -or (Get-FileHash -LiteralPath $ruffArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ruffHash) {
    & curl.exe --fail --location --silent --show-error --continue-at - --retry 2 --connect-timeout 15 --max-time 600 --output $ruffArchive 'https://github.com/astral-sh/ruff/releases/download/0.11.13/ruff-x86_64-pc-windows-msvc.zip'
    if ($LASTEXITCODE) { throw 'Ruff download failed.' }
}
if ((Get-FileHash -LiteralPath $ruffArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ruffHash) { throw 'Ruff checksum mismatch.' }
$ruffExtract = Join-Path $downloads ('ruff-' + [guid]::NewGuid().ToString('N'))
Expand-Archive -LiteralPath $ruffArchive -DestinationPath $ruffExtract
$ruffExe = Get-ChildItem -LiteralPath $ruffExtract -Recurse -File -Filter 'ruff.exe' | Select-Object -First 1
if (-not $ruffExe) { throw 'Ruff wheel has no executable.' }
Copy-Item -LiteralPath $ruffExe.FullName -Destination (Join-Path $bin 'ruff.exe')
Copy-Tree (Split-Path $ruffExe.FullName -Parent) (Join-Path $OutputPath 'licenses/ruff')
# Neovim uses the same MSVC runtime; bundle it rather than require vcredist setup.
Get-ChildItem -LiteralPath $pythonRoot -Filter 'vcruntime*.dll' |
    Copy-Item -Destination (Join-Path $OutputPath 'tools/nvim/bin')

Write-Host 'Copying .NET SDKs and runtimes...'
$dotnetRoot = Split-Path (Tool 'dotnet') -Parent
$dotnetDest = Join-Path $OutputPath 'tools/dotnet'
New-Item -ItemType Directory -Force -Path $dotnetDest | Out-Null
Get-ChildItem -LiteralPath $dotnetRoot -File | Copy-Item -Destination $dotnetDest
foreach ($folder in @('host', 'sdk', 'sdk-manifests', 'templates', 'template-packs', 'library-packs')) {
    if (Test-Path -LiteralPath (Join-Path $dotnetRoot $folder)) { Copy-Tree (Join-Path $dotnetRoot $folder) (Join-Path $dotnetDest $folder) }
}
foreach ($pack in @('Microsoft.NETCore.App.Ref', 'Microsoft.NETCore.App.Host.win-x64', 'Microsoft.AspNetCore.App.Ref', 'Microsoft.WindowsDesktop.App.Ref', 'NETStandard.Library.Ref')) {
    Copy-Tree (Join-Path $dotnetRoot "packs/$pack") (Join-Path $dotnetDest "packs/$pack")
}
foreach ($framework in Get-ChildItem -LiteralPath (Join-Path $dotnetRoot 'shared') -Directory) {
    foreach ($major in @(8, 9, 10)) {
        $version = Get-ChildItem -LiteralPath $framework.FullName -Directory |
            Where-Object { $_.Name -match "^$major\.\d+\.\d+$" } |
            Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
        if ($version) { Copy-Tree $version.FullName (Join-Path $dotnetDest "shared/$($framework.Name)/$($version.Name)") }
    }
}
if (-not (Test-Path -Path (Join-Path $dotnetDest 'shared/Microsoft.NETCore.App/10.*'))) { throw 'Install .NET 10 runtime on the build PC for Roslyn.' }

$downloads = Join-Path (Split-Path $OutputPath -Parent) 'downloads'
New-Item -ItemType Directory -Force -Path $downloads | Out-Null
if ($JdkPath) {
    $JdkPath = [IO.Path]::GetFullPath($JdkPath)
    if (-not (Test-Path -LiteralPath (Join-Path $JdkPath 'bin/javac.exe'))) { throw 'JdkPath must contain a full Windows x64 JDK.' }
    $jdk = @{ name = (Get-Content -LiteralPath (Join-Path $JdkPath 'release') | Where-Object { $_ -match '^JAVA_VERSION=' }); checksum = ''; link = 'Local JDK; original legal notices and sources retained.' }
    Copy-Tree $JdkPath (Join-Path $OutputPath 'tools/java')
} else {
$jdk = (Invoke-RestMethod 'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse')[0].binary.package
$jdkArchive = Join-Path $downloads $jdk.name
if (-not (Test-Path -LiteralPath $jdkArchive)) {
    & curl.exe --fail --location --silent --show-error --retry 2 --connect-timeout 15 --max-time 300 --output $jdkArchive $jdk.link
    if ($LASTEXITCODE) { throw 'Temurin JDK download failed.' }
}
if ((Get-FileHash -LiteralPath $jdkArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $jdk.checksum) { throw 'Temurin checksum mismatch.' }
$jdkExtract = Join-Path $downloads ('jdk-' + [guid]::NewGuid().ToString('N'))
Expand-Archive -LiteralPath $jdkArchive -DestinationPath $jdkExtract
$jdkRoot = Get-ChildItem -LiteralPath $jdkExtract -Directory | Select-Object -First 1
Copy-Tree $jdkRoot.FullName (Join-Path $OutputPath 'tools/java')
}

Write-Host 'Copying plugins, parsers and language servers...'
$portableData = Join-Path $OutputPath 'data/nvim-data'
Copy-Tree (Join-Path $data 'mason/registries') (Join-Path $portableData 'mason/registries')
Copy-Tree (Join-Path $data 'mason/share') (Join-Path $portableData 'mason/share')
Copy-Tree (Join-Path $data 'lazy') (Join-Path $portableData 'lazy')
# Blink verifies its native library against the Git tag. Preserve public objects
# and refs only: no remotes, credentials, reflogs, hooks or local Git configuration.
$blinkSourceGit = Join-Path $data 'lazy/blink.cmp/.git'
$blinkDest = Join-Path $portableData 'lazy/blink.cmp'
& (Tool 'git') -c init.templateDir= -C $blinkDest init -q
if ($LASTEXITCODE) { throw 'Cannot initialize Blink version metadata.' }
foreach ($folder in @('objects', 'refs')) {
    Copy-Tree (Join-Path $blinkSourceGit $folder) (Join-Path $blinkDest ".git/$folder")
}
foreach ($file in @('HEAD', 'packed-refs', 'shallow')) {
    if (Test-Path -LiteralPath (Join-Path $blinkSourceGit $file)) {
        Copy-Item -LiteralPath (Join-Path $blinkSourceGit $file) -Destination (Join-Path $blinkDest '.git') -Force
    }
}
Copy-Tree (Join-Path $data 'site') (Join-Path $portableData 'site')
$roslyn = 'roslyn-language-server-5.12.0-1.26426.8'
Copy-Tree (Join-Path $data "tools/$roslyn") (Join-Path $portableData "tools/$roslyn")
$masonBin = Join-Path $portableData 'mason/bin'
New-Item -ItemType Directory -Force -Path $masonBin | Out-Null
foreach ($name in @('netcoredbg', 'jdtls', 'java-debug-adapter', 'java-test', 'pyright', 'lua-language-server', 'stylua', 'vtsls', 'json-lsp', 'tailwindcss-language-server', 'marksman', 'markdownlint-cli2', 'markdown-toc')) {
    $package = Join-Path $data "mason/packages/$name"
    $receipt = Get-Content -Raw -LiteralPath (Join-Path $package 'mason-receipt.json') | ConvertFrom-Json
    Copy-Tree $package (Join-Path $portableData "mason/packages/$name")
    foreach ($link in $receipt.links.bin.PSObject.Properties.Name) {
        Copy-Item -LiteralPath (Join-Path $data "mason/bin/$link") -Destination $masonBin
    }
}
Copy-Item -LiteralPath (Join-Path $source 'portable/jdtls.cmd') -Destination (Join-Path $portableData 'mason/packages/jdtls/jdtls.cmd') -Force
Copy-Item -LiteralPath (Join-Path $source 'portable/debugpy-adapter.cmd') -Destination $masonBin
foreach ($name in @('debugpy', 'ruff')) {
    $packageDest = Join-Path $portableData "mason/packages/$name"
    New-Item -ItemType Directory -Force -Path $packageDest | Out-Null
    if ($name -eq 'debugpy') {
        Copy-Item -LiteralPath (Join-Path $data 'mason/packages/debugpy/mason-receipt.json') -Destination $packageDest
        Copy-Item -LiteralPath (Join-Path $source 'portable/debugpy-adapter.cmd') -Destination $packageDest
    } else {
        Copy-Item -LiteralPath (Join-Path $bin 'ruff.exe') -Destination $packageDest
        Copy-Item -LiteralPath (Join-Path $bin 'ruff.exe') -Destination $masonBin
        @{ schema_version = '2.0'; name = 'ruff'; source = @{ type = 'registry+v1'; id = 'pkg:pypi/ruff@0.11.13'; raw = @{ id = 'pkg:pypi/ruff@0.11.13' } }; links = @{ bin = @{ 'ruff.exe' = 'ruff.exe' }; share = @{}; opt = @{} } } |
            ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $packageDest 'mason-receipt.json') -Encoding UTF8
    }
}
$manifest = [ordered]@{
    name = 'Hilvim Portable'; platform = 'windows-x64'; built = (Get-Date -Format o)
    neovim = (& (Tool 'nvim') --version | Select-Object -First 1)
    java = $jdk.name; javaSHA256 = $jdk.checksum; javaSource = $jdk.link
    debugpy = $debugpyVersion; ruff = '0.11.13'
    note = 'No credentials, sessions, user caches or Python user packages are included.'
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputPath 'bundle.json') -Encoding UTF8
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $OutputPath 'scripts/launch.ps1') --hilvim-check
if ($LASTEXITCODE) { throw 'Portable check failed.' }
if ($Zip) {
    & (Join-Path $PSScriptRoot 'package-portable.ps1') -BundlePath $OutputPath
}
Write-Host "HILVIM_PORTABLE_BUILD_OK: $OutputPath"
