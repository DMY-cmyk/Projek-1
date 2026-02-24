param(
    [string]$DataDir = "data",
    [string]$OutputsDir = "outputs",
    [string]$OutPath = "outputs/export_bundle.zip"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (Test-Path $OutPath) {
    Remove-Item -Force $OutPath
}

$items = @()
$items += Get-ChildItem -Path $DataDir -Filter "*.csv" | Select-Object -ExpandProperty FullName
$items += @(
    (Join-Path $OutputsDir "report.md"),
    (Join-Path $OutputsDir "dashboard.md"),
    (Join-Path $OutputsDir "quick_review.md"),
    (Join-Path $OutputsDir "summary.json"),
    (Join-Path $OutputsDir "health_check.md"),
    (Join-Path $OutputsDir "change_log.md"),
    (Join-Path $OutputsDir "freshness_report.md"),
    (Join-Path $OutputsDir "drift_alerts.md"),
    (Join-Path $OutputsDir "scenario_stress.md"),
    (Join-Path $OutputsDir "key_events.md"),
    (Join-Path $OutputsDir "run_log.md"),
    (Join-Path $OutputsDir "cleanup_plan.md")
)

$items = $items | Where-Object { Test-Path $_ } | Sort-Object -Unique

if ($items.Count -eq 0) {
    Write-Error "No files found to bundle."
    exit 1
}

Compress-Archive -Path $items -DestinationPath $OutPath -Force
Write-Host "Done. Wrote export bundle to $OutPath."
