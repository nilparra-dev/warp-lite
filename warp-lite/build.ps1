param(
    [int]$Jobs = 6
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ProjectTools = (Resolve-Path (Join-Path $Repo '..\tools') -ErrorAction SilentlyContinue)
$Log = Join-Path $env:TEMP "warp-lite-build-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

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
    $winget = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path $winget) {
        $hit = Get-ChildItem -Path $winget -Recurse -Filter $Exe -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }
    return $null
}

$cmake = Find-ToolDir -Exe 'cmake.exe' -Candidates @(
    "$env:ProgramFiles\CMake\bin",
    "$env:LOCALAPPDATA\Programs\CMake\bin"
) -SearchRoots @($ProjectTools)
$protoc = Find-ToolDir -Exe 'protoc.exe' -Candidates @(
    "$env:ProgramFiles\Protobuf\bin",
    "$env:LOCALAPPDATA\Programs\Protobuf\bin"
) -SearchRoots @($ProjectTools)
$llvm = Find-ToolDir -Exe 'libclang.dll' -Candidates @(
    "$env:ProgramFiles\LLVM\bin",
    "${env:ProgramFiles(x86)}\LLVM\bin"
) -SearchRoots @($ProjectTools)

if (-not $cmake) { throw 'cmake.exe no encontrado. Instala CMake o define WARP_LITE_TOOLS.' }
if (-not $protoc) { throw 'protoc.exe no encontrado. Instala protoc (Google.Protobuf).' }

$env:PATH = "$cmake;$protoc;$env:PATH"
if ($llvm) {
    $env:PATH = "$llvm;$env:PATH"
    $env:LIBCLANG_PATH = $llvm
}
$env:CARGO_BUILD_JOBS = "$Jobs"
$env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'

Write-Output "Repo:    $Repo"
Write-Output "CMake:   $cmake"
Write-Output "protoc:  $protoc"
Write-Output "LLVM:    $llvm"
Write-Output "Log:     $Log"

Push-Location $Repo
try {
    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & cargo build --release --bin warp-oss --features 'gui,skip_login' --timings *>&1 |
        Tee-Object -FilePath $Log
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previousEap
    if ($exit -ne 0) { throw "cargo build falló con código $exit. Mira $Log" }
} finally {
    Pop-Location
}

Write-Output "OK: $Repo\target\release\warp-oss.exe"
