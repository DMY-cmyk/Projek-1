param(
    [string]$LogPath = "outputs/run_log_ci.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Run-Step([string]$label, [string]$scriptPath) {
    $start = Get-Date
    $exitCode = 0
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $scriptPath | Out-Null
        $exitCode = $LASTEXITCODE
    } catch {
        $exitCode = 1
    }
    $end = Get-Date
    return [pscustomobject]@{
        Step = $label
        Started = $start
        Ended = $end
        ExitCode = $exitCode
    }
}

$steps = New-Object System.Collections.Generic.List[object]
$steps.Add((Run-Step "Build report" "scripts/build_report.ps1")) | Out-Null
$steps.Add((Run-Step "Build charts" "scripts/build_charts.ps1")) | Out-Null
$steps.Add((Run-Step "Build dashboard" "scripts/build_dashboard.ps1")) | Out-Null
$steps.Add((Run-Step "Build key events" "scripts/build_key_events.ps1")) | Out-Null
$steps.Add((Run-Step "Check data freshness" "scripts/check_data_freshness.ps1")) | Out-Null
$steps.Add((Run-Step "Build change log" "scripts/build_change_log.ps1")) | Out-Null
$steps.Add((Run-Step "Build drift alerts" "scripts/build_drift_alerts.ps1")) | Out-Null
$steps.Add((Run-Step "Build scenario stress" "scripts/build_scenario_stress.ps1")) | Out-Null
$steps.Add((Run-Step "Cleanup plan (dry run)" "scripts/cleanup_runs.ps1")) | Out-Null
$steps.Add((Run-Step "Health check" "scripts/build_health_check.ps1")) | Out-Null
$steps.Add((Run-Step "Summary JSON" "scripts/build_summary_json.ps1")) | Out-Null
$steps.Add((Run-Step "Export bundle" "scripts/build_export_bundle.ps1")) | Out-Null
$steps.Add((Run-Step "Outputs manifest" "scripts/build_outputs_manifest.ps1")) | Out-Null

$log = @()
$log += "# Report Pack CI Run Log"
$log += ""
$log += ("Run time: {0:yyyy-MM-dd HH:mm:ss} local time" -f (Get-Date))
$log += ""
$log += "|Step|Started|Ended|ExitCode|"
$log += "|---|---|---|---|"
foreach ($s in $steps) {
    $log += ("|{0}|{1:HH:mm:ss}|{2:HH:mm:ss}|{3}|" -f $s.Step, $s.Started, $s.Ended, $s.ExitCode)
}

$outDir = Split-Path $LogPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$log -join "`n" | Out-File -FilePath $LogPath -Encoding utf8

$failed = @($steps | Where-Object { $_.ExitCode -ne 0 })
if ($failed.Count -gt 0) {
    Write-Error ("Report pack CI failed: {0} step(s) failed." -f $failed.Count)
    exit 1
}

Write-Host "Done. Wrote CI run log to $LogPath."
