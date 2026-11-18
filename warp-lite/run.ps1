$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Exe = Join-Path $Repo 'target\release\warp-oss.exe'

if (-not (Test-Path $Exe)) {
    throw "No existe $Exe. Ejecuta primero warp-lite\build.ps1."
}

$settings = Join-Path $env:LOCALAPPDATA 'warp\WarpOss\config\settings.toml'
if (-not (Test-Path $settings)) {
    Write-Output 'No hay settings.toml; instalando el perfil warp-lite...'
    & (Join-Path $PSScriptRoot 'install-settings.ps1')
}

Start-Process -FilePath $Exe -WorkingDirectory $Repo
