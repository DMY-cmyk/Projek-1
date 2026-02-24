param(
    [string]$OutPath = "outputs/refresh_status.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$items = @(
    "outputs/report.md",
    "outputs/charts/revenue_operating_income.png",
    "outputs/charts/margins.png",
    "outputs/charts/fcf_capital_returns.png",
    "outputs/charts/net_cash.png",
    "outputs/charts/peer_multiples.png",
    "outputs/charts/peer_revenue_growth.png",
    "outputs/charts/peer_margins.png",
    "outputs/dashboard.md",
    "outputs/key_events.md",
    "outputs/freshness_report.md",
    "outputs/change_log.md",
    "outputs/drift_alerts.md",
    "outputs/scenario_stress.md",
    "outputs/run_log.md"
)

$rows = @()
foreach ($item in $items) {
    if (Test-Path $item) {
        $info = Get-Item $item
        $rows += [pscustomobject]@{
            Path = $item
            Exists = "Yes"
            LastWriteTime = $info.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            SizeKB = [math]::Round(($info.Length / 1KB), 1)
        }
    } else {
        $rows += [pscustomobject]@{
            Path = $item
            Exists = "No"
            LastWriteTime = ""
            SizeKB = ""
        }
    }
}

$report = @()
$report += "# Refresh Status"
$report += ""
$report += ("Generated: {0:yyyy-MM-dd HH:mm:ss} local time" -f (Get-Date))
$report += ""
$report += "|Path|Exists|LastWriteTime|SizeKB|"
$report += "|---|---|---|---|"
foreach ($r in $rows) {
    $report += ("|{0}|{1}|{2}|{3}|" -f $r.Path, $r.Exists, $r.LastWriteTime, $r.SizeKB)
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote refresh status to $OutPath."
