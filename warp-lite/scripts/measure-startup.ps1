param(
    [Parameter(Mandatory = $true)]
    [string]$Exe,
    [int]$Runs = 5,
    [int]$SettleSeconds = 5,
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'
if (-not $OutDir) {
    $OutDir = Join-Path $PSScriptRoot '..\notes\bench'
}
$Exe = (Resolve-Path $Exe).Path
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Get-ChildSnapshot {
    param([int]$ParentId)
    $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $ParentId" -ErrorAction SilentlyContinue)
    $shell = $children |
        Where-Object { $_.Name -match '^(powershell|pwsh|bash|wsl|cmd)\.exe$' } |
        Select-Object -First 1
    [pscustomobject]@{
        shell = $shell
        children = $children
    }
}

function Get-ProcessMetrics {
    param([System.Diagnostics.Process]$Process, [System.Diagnostics.Stopwatch]$Clock)

    $windowMs = $null
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            $Process.Refresh()
            if ($Process.HasExited) { break }
            if ($Process.MainWindowHandle -ne [IntPtr]::Zero) {
                $windowMs = [math]::Round($Clock.Elapsed.TotalMilliseconds, 1)
                break
            }
        } catch { }
        Start-Sleep -Milliseconds 10
    }

    $shellMs = $null
    $shellName = $null
    $shellDeadline = [DateTime]::UtcNow.AddSeconds(20)
    while ([DateTime]::UtcNow -lt $shellDeadline) {
        try {
            $Process.Refresh()
            if ($Process.HasExited) { break }
        } catch { break }
        $snapshot = Get-ChildSnapshot -ParentId $Process.Id
        if ($snapshot.shell) {
            $shellMs = [math]::Round($Clock.Elapsed.TotalMilliseconds, 1)
            $shellName = $snapshot.shell.Name
            break
        }
        Start-Sleep -Milliseconds 150
    }

    Start-Sleep -Seconds $SettleSeconds
    $Process.Refresh()
    $workingSetMB = if ($Process.HasExited) { $null } else { [math]::Round($Process.WorkingSet64 / 1MB, 1) }
    $privateMB = if ($Process.HasExited) { $null } else { [math]::Round($Process.PrivateMemorySize64 / 1MB, 1) }
    $cpuSeconds = if ($Process.HasExited) { $null } else { [math]::Round($Process.TotalProcessorTime.TotalSeconds, 2) }
    $snapshot = if ($Process.HasExited) { [pscustomobject]@{ children = @() } } else { Get-ChildSnapshot -ParentId $Process.Id }
    $childCount = @($snapshot.children).Count
    $childProcesses = @($snapshot.children | ForEach-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue })
    $childWs = ($childProcesses | Measure-Object WorkingSet64 -Sum).Sum
    $childPrivate = ($childProcesses | Measure-Object PrivateMemorySize64 -Sum).Sum
    if ($null -eq $childWs) { $childWs = 0 }
    if ($null -eq $childPrivate) { $childPrivate = 0 }
    $treeWorkingSetMB = if ($Process.HasExited) { $null } else { [math]::Round(($Process.WorkingSet64 + $childWs) / 1MB, 1) }
    $treePrivateMB = if ($Process.HasExited) { $null } else { [math]::Round(($Process.PrivateMemorySize64 + $childPrivate) / 1MB, 1) }

    [pscustomobject]@{
        window_ms = $windowMs
        shell_ms = $shellMs
        shell_name = $shellName
        working_set_mb = $workingSetMB
        private_mb = $privateMB
        tree_working_set_mb = $treeWorkingSetMB
        tree_private_mb = $treePrivateMB
        cpu_seconds_after_settle = $cpuSeconds
        child_count = $childCount
        exited_early = $Process.HasExited
    }
}

function Get-Summary {
    param([object[]]$Results, [string]$Property)
    $values = @($Results | ForEach-Object { $_.$Property } | Where-Object { $null -ne $_ })
    if ($values.Count -eq 0) {
        return [pscustomobject]@{ count = 0; mean = $null; min = $null; max = $null }
    }
    $measure = $values | Measure-Object -Average -Minimum -Maximum
    [pscustomobject]@{
        count = $values.Count
        mean = [math]::Round($measure.Average, 1)
        min = [math]::Round($measure.Minimum, 1)
        max = [math]::Round($measure.Maximum, 1)
    }
}

$results = @()
for ($i = 1; $i -le $Runs; $i++) {
    $clock = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process -FilePath $Exe -PassThru
    $metrics = Get-ProcessMetrics -Process $proc -Clock $clock
    $metrics | Add-Member -NotePropertyName run -NotePropertyValue $i
    $metrics | Add-Member -NotePropertyName timestamp -NotePropertyValue (Get-Date).ToString('o')
    $results += $metrics

    if (-not $proc.HasExited) {
        try { $proc.CloseMainWindow() | Out-Null } catch { }
        Start-Sleep -Milliseconds 800
        try { if (-not $proc.HasExited) { $proc.Kill($true) } } catch { }
    }
    Start-Sleep -Seconds 2
}

$payload = [pscustomobject]@{
    exe = $Exe
    runs = $Runs
    settle_seconds = $SettleSeconds
    summary = [pscustomobject]@{
        window_ms = Get-Summary -Results $results -Property 'window_ms'
        shell_ms = Get-Summary -Results $results -Property 'shell_ms'
        working_set_mb = Get-Summary -Results $results -Property 'working_set_mb'
        private_mb = Get-Summary -Results $results -Property 'private_mb'
        tree_working_set_mb = Get-Summary -Results $results -Property 'tree_working_set_mb'
        tree_private_mb = Get-Summary -Results $results -Property 'tree_private_mb'
    }
    results = $results
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outFile = Join-Path $OutDir "startup-$stamp.json"
$payload | ConvertTo-Json -Depth 6 | Set-Content -Path $outFile -Encoding UTF8
$payload | ConvertTo-Json -Depth 6
Write-Output "Saved: $outFile"
