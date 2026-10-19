#requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$BackupExisting,
    [switch]$SkipDependencies,
    [switch]$SkipRoslyn,
    [switch]$SkipBootstrap,
    [string]$ConfigPath = (Join-Path $env:LOCALAPPDATA 'nvim'),
    [string]$DataPath = (Join-Path $env:LOCALAPPDATA 'nvim-data')
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$sourcePath = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\', '/')
$ConfigPath = [IO.Path]::GetFullPath($ConfigPath).TrimEnd('\', '/')
$DataPath = [IO.Path]::GetFullPath($DataPath).TrimEnd('\', '/')
$roslynVersion = '5.12.0-1.26426.8'
$roslynRoot = Join-Path $DataPath "tools/roslyn-language-server-$roslynVersion"
$roslynExe = Join-Path $roslynRoot 'tools/net10.0/win-x64/Microsoft.CodeAnalysis.LanguageServer.exe'
$requirements = @(
    @{ Command = 'git'; Id = 'Git.Git' },
    @{ Command = 'nvim'; Id = 'Neovim.Neovim' },
    @{ Command = 'rg'; Id = 'BurntSushi.ripgrep.MSVC' },
    @{ Command = 'fd'; Id = 'sharkdp.fd' },
    @{ Command = 'tree-sitter'; Id = 'tree-sitter.tree-sitter-cli' },
    @{ Command = 'gcc'; Id = 'BrechtSanders.WinLibs.POSIX.UCRT' },
    @{ Command = 'lazygit'; Id = 'JesseDuffield.lazygit' },
    @{ Command = 'node'; Id = 'OpenJS.NodeJS.LTS' },
    @{ Command = 'python'; Id = 'Python.Python.3.12' },
    @{ Command = 'java'; Id = 'EclipseAdoptium.Temurin.21.JDK' },
    @{ Command = 'dotnet'; Id = 'Microsoft.DotNet.SDK.10' }
)

function Refresh-ToolPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path
}

function Assert-ExitCode([string]$Action) {
    if ($LASTEXITCODE -ne 0) { throw "$Action failed (exit $LASTEXITCODE)." }
}

function Assert-SafeDirectory([string]$Path) {
    $forbidden = @([IO.Path]::GetPathRoot($Path).TrimEnd('\'),
        $env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA, $sourcePath)
    if ($forbidden -contains $Path -or $Path.Length -lt 8) {
        throw "Refusing broad destination: $Path"
    }
    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -Force -LiteralPath $Path
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Destination must be a normal directory: $Path"
        }
    }
}

if ($env:OS -ne 'Windows_NT') { throw 'This installer supports Windows x64.' }
if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'Roslyn bundle requires an x64 PowerShell process.' }
if ($env:NVIM_APPNAME -and $env:NVIM_APPNAME -ne 'nvim') { throw 'Unset NVIM_APPNAME before installing Hilvim.' }
Refresh-ToolPath

if ($Check) {
    $missing = @()
    foreach ($tool in $requirements) {
        $found = Get-Command $tool.Command -ErrorAction SilentlyContinue
        if ($found) { Write-Output ("OK      {0}: {1}" -f $tool.Command, $found.Source) }
        else { Write-Output ("MISSING {0} ({1})" -f $tool.Command, $tool.Id); $missing += $tool.Command }
    }
    Write-Output "Config: $ConfigPath"
    Write-Output "Roslyn present: $(Test-Path -LiteralPath $roslynExe)"
    if ($missing.Count) { throw ('Missing tools: ' + ($missing -join ', ')) }
    & nvim --version | Select-Object -First 1
    exit 0
}

# Check destinations before downloading or installing anything.
if ($ConfigPath -ne $sourcePath) {
    Assert-SafeDirectory $ConfigPath
    if ($ConfigPath.StartsWith($sourcePath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'ConfigPath must be outside the source checkout.'
    }
    if ($sourcePath.StartsWith($ConfigPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'ConfigPath must not contain the source checkout.'
    }
    if ((Test-Path -LiteralPath $ConfigPath) -and -not $BackupExisting) {
        throw "Config exists: $ConfigPath. Use -BackupExisting to preserve it before installing."
    }
}
Assert-SafeDirectory $DataPath
if (-not $SkipBootstrap -and ($ConfigPath -ne (Join-Path $env:LOCALAPPDATA 'nvim') -or $DataPath -ne (Join-Path $env:LOCALAPPDATA 'nvim-data'))) {
    throw 'Custom paths support deployment only; use -SkipBootstrap. Neovim uses its standard paths.'
}

if (-not $SkipDependencies) {
    foreach ($tool in $requirements) {
        if (-not (Get-Command $tool.Command -ErrorAction SilentlyContinue)) {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'Install Windows App Installer (winget) first.' }
            Write-Host "Installing $($tool.Id)..."
            & winget install --id $tool.Id --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
            Assert-ExitCode "Install $($tool.Id)"
            Refresh-ToolPath
        }
    }
}

if (-not $SkipBootstrap) {
    foreach ($command in @('nvim', 'git', 'gcc', 'tree-sitter')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Missing $command; open a new terminal or install prerequisites." }
    }
    $nvimVersion = (& nvim --version | Select-Object -First 1)
    if ($nvimVersion -notmatch 'NVIM v(\d+)\.(\d+)') { throw "Cannot parse Neovim version: $nvimVersion" }
    if ([int]$Matches[1] -eq 0 -and [int]$Matches[2] -lt 12) { throw 'Hilvim requires Neovim >= 0.12.' }
}

if (-not $SkipRoslyn -and -not (Test-Path -LiteralPath $roslynExe)) {
    $downloadDir = Join-Path ([IO.Path]::GetTempPath()) ('hilvim-roslyn-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $downloadDir | Out-Null
    $archive = Join-Path $downloadDir 'roslyn.zip'
    $package = "roslyn-language-server.win-x64.$roslynVersion.nupkg"
    $url = "https://api.nuget.org/v3-flatcontainer/roslyn-language-server.win-x64/$roslynVersion/$package"
    Write-Host "Downloading official Roslyn $roslynVersion..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe --fail --location --silent --show-error --retry 2 --connect-timeout 15 --max-time 180 --output $archive $url
        Assert-ExitCode 'Roslyn download'
    } else {
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $archive -TimeoutSec 180
    }
    $expectedHash = 'J9xYa91ZTVj3LSHvApK+4Pg2ufHI6we3OhbyAS36FBnoHC51ugVPc7PD4aPL53rPKVbhQ9bIxpiEKm2ML7PV5A=='
    $sha512 = [Security.Cryptography.SHA512]::Create()
    $stream = [IO.File]::OpenRead($archive)
    try { $actualHash = [Convert]::ToBase64String($sha512.ComputeHash($stream)) }
    finally { $stream.Dispose(); $sha512.Dispose() }
    if ($actualHash -ne $expectedHash) { throw 'Roslyn package SHA512 mismatch.' }
    $extract = Join-Path $downloadDir 'package'
    Expand-Archive -LiteralPath $archive -DestinationPath $extract
    if (-not (Test-Path -LiteralPath (Join-Path $extract 'tools/net10.0/win-x64/Microsoft.CodeAnalysis.LanguageServer.exe'))) {
        throw 'Roslyn package did not contain the expected executable.'
    }
    New-Item -ItemType Directory -Force -Path $roslynRoot | Out-Null
    Copy-Item -Path (Join-Path $extract '*') -Destination $roslynRoot -Recurse -Force
}

if ($ConfigPath -ne $sourcePath) {
    if (Test-Path -LiteralPath $ConfigPath) {
        $backupPath = $ConfigPath + '.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        # Both absolute targets were checked; move only this exact config directory.
        Move-Item -LiteralPath $ConfigPath -Destination $backupPath
        Write-Host "Previous configuration preserved at $backupPath"
    }
    New-Item -ItemType Directory -Path $ConfigPath | Out-Null
    foreach ($name in @('init.lua', 'lua', 'asciiart.txt', 'lazy-lock.json', 'lazyvim.json',
        '.neoconf.json', 'stylua.toml', 'README.md', 'LICENSE', 'install.ps1', 'scripts', 'portable')) {
        Copy-Item -LiteralPath (Join-Path $sourcePath $name) -Destination $ConfigPath -Recurse
    }
}

if (-not $SkipBootstrap) {
    & nvim --headless -i NONE '+Lazy! restore' +qa
    Assert-ExitCode 'Plugin restore'
    Push-Location -LiteralPath $ConfigPath
    try { & nvim --headless -i NONE -c 'luafile scripts/bootstrap.lua' }
    finally { Pop-Location }
    Assert-ExitCode 'Language tooling bootstrap'
}

Write-Host "Hilvim ready at $ConfigPath"
Write-Host 'Open a new terminal, select a Nerd Font, then run nvim. See README.md for validation and shortcuts.'
