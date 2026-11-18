$ErrorActionPreference = 'Stop'

$configDir = Join-Path $env:LOCALAPPDATA 'warp\WarpLite\config'
$target = Join-Path $configDir 'settings.toml'
$source = Join-Path $PSScriptRoot 'settings.toml'

New-Item -ItemType Directory -Force -Path $configDir | Out-Null

if (Test-Path $target) {
    $backup = "$target.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $target $backup
    Write-Output "Backup: $backup"
}

Copy-Item $source $target -Force
Write-Output "Installed: $target"
