param(
    [string]$OutPath = "outputs/quick_review.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-IfExists([string]$path) {
    if (Test-Path $path) {
        return Get-Content -Raw $path
    }
    return ""
}

$freshness = Read-IfExists "outputs/freshness_report.md"
$changeLog = Read-IfExists "outputs/change_log.md"
$drift = Read-IfExists "outputs/drift_alerts.md"
$scenario = Read-IfExists "outputs/scenario_stress.md"
$keyEvents = Read-IfExists "outputs/key_events.md"

$report = @()
$report += "# Quick Review"
$report += ""
$report += "## Key Events"
if ($keyEvents) {
    $report += ($keyEvents -split "`n" | Select-Object -First 15)
} else {
    $report += "Missing: outputs/key_events.md"
}
$report += ""
$report += "## Freshness"
if ($freshness) {
    $report += ($freshness -split "`n" | Select-Object -First 20)
} else {
    $report += "Missing: outputs/freshness_report.md"
}
$report += ""
$report += "## Change Log"
if ($changeLog) {
    $report += ($changeLog -split "`n" | Select-Object -First 20)
} else {
    $report += "Missing: outputs/change_log.md"
}
$report += ""
$report += "## Drift Alerts"
if ($drift) {
    $report += ($drift -split "`n" | Select-Object -First 20)
} else {
    $report += "Missing: outputs/drift_alerts.md"
}
$report += ""
$report += "## Scenario Stress"
if ($scenario) {
    $report += ($scenario -split "`n" | Select-Object -First 20)
} else {
    $report += "Missing: outputs/scenario_stress.md"
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote quick review to $OutPath."
