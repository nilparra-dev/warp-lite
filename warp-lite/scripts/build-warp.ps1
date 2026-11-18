param(
    [ValidateSet('debug', 'release', 'release-lto')]
    [string]$Profile = 'release',
    [string]$Features = 'gui,skip_login',
    [string]$Bin = 'warp-lite',
    [int]$Jobs = 6,
    [switch]$NoDefaultFeatures
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$LogDir = Join-Path $PSScriptRoot '..\notes\bench'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogDir = (Resolve-Path $LogDir).Path

function Add-ToolPath {
    param([string]$Dir, [string]$Exe)
    if ($Dir -and (Test-Path (Join-Path $Dir $Exe))) {
        if (($env:PATH -split ';') -notcontains $Dir) { $env:PATH = "$Dir;$env:PATH" }
        return $true
    }
    return $false
}

function Find-ExeDir {
    param([Parameter(Mandatory = $true)][string]$Exe)
    $cmd = Get-Command $Exe -ErrorAction SilentlyContinue
    if ($cmd) { return (Split-Path $cmd.Source -Parent) }
    return $null
}

function Find-ToolDir {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Candidates = @(),
        [string[]]$SearchRoots = @()
    )
    foreach ($dir in $Candidates) {
        if ($dir -and (Test-Path (Join-Path $dir $Exe))) { return $dir }
    }
    foreach ($root in $SearchRoots) {
        if ($root -and (Test-Path $root)) {
            $hit = Get-ChildItem -Path $root -Recurse -Filter $Exe -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($hit) { return $hit.DirectoryName }
        }
    }
    $wingetPackages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path $wingetPackages) {
        $hit = Get-ChildItem -Path $wingetPackages -Recurse -Filter $Exe -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }
    return $null
}

$projectTools = Join-Path $Repo '..\tools'
$cmake = Find-ExeDir 'cmake.exe'
if (-not $cmake) {
    $cmake = Find-ToolDir -Exe 'cmake.exe' -Candidates @("$env:ProgramFiles\CMake\bin", "$env:LOCALAPPDATA\Programs\CMake\bin") -SearchRoots @($projectTools)
}
$protoc = Find-ExeDir 'protoc.exe'
if (-not $protoc) {
    $protoc = Find-ToolDir -Exe 'protoc.exe' -Candidates @("$env:ProgramFiles\Protobuf\bin", "$env:LOCALAPPDATA\Programs\Protobuf\bin") -SearchRoots @($projectTools)
}
$llvm = Find-ToolDir -Exe 'libclang.dll' -Candidates @("$env:ProgramFiles\LLVM\bin", "${env:ProgramFiles(x86)}\LLVM\bin") -SearchRoots @($projectTools)
$gitUsrBin = 'C:\Program Files\Git\usr\bin'

if (-not (Add-ToolPath $cmake 'cmake.exe')) { throw 'cmake.exe no encontrado. Instala Kitware.CMake.' }
if (-not (Add-ToolPath $protoc 'protoc.exe')) { throw 'protoc.exe no encontrado. Instala Google.Protobuf.' }
if ($llvm -and (Add-ToolPath $llvm 'libclang.dll')) {
    $env:LIBCLANG_PATH = $llvm
} else {
    Write-Warning 'libclang.dll no encontrado; en Windows no debería hacer falta salvo que algún build script use bindgen.'
}
if (Test-Path (Join-Path $gitUsrBin 'patch.exe')) {
    if (($env:PATH -split ';') -notcontains $gitUsrBin) { $env:PATH = "$gitUsrBin;$env:PATH" }
}

$env:CARGO_BUILD_JOBS = "$Jobs"
$env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'
# No se toca CARGO_TARGET_DIR: app/build.rs copia ConPTY/DXCompiler a
# <workspace>/target/<profile> y no respeta CARGO_TARGET_DIR.

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $LogDir "build-$Profile-$stamp.log"

$cargoArgs = @('build', '--bin', $Bin, '--features', $Features, '--timings')
if ($NoDefaultFeatures) { $cargoArgs += '--no-default-features' }
if ($Profile -ne 'debug') { $cargoArgs += @('--profile', $Profile) }

Write-Output "Repo:     $Repo"
Write-Output "Profile:  $Profile"
Write-Output "Features: $Features"
Write-Output "Jobs:     $Jobs"
Write-Output "Target:   $Repo\target"
Write-Output "Log:      $log"

Push-Location $Repo
try {
    Write-Output "Cargo:    $(& cargo --version)"
    # Cargo escribe el progreso por stderr. Con ErrorActionPreference=Stop,
    # PowerShell 5.1 lo convierte en excepción y mata el build. Se relaja
    # solo durante la invocación y se restaura después.
    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & cargo @cargoArgs *>&1 | Tee-Object -FilePath $log
    $cargoExit = $LASTEXITCODE
    $ErrorActionPreference = $previousEap
    if ($cargoExit -ne 0) { throw "cargo build falló con código $cargoExit. Mira $log" }
} finally {
    Pop-Location
}

Write-Output "OK. Log: $log"
