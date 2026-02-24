param(
    [string]$OutPath = "outputs/health_check.md",
    [int]$FreshnessDays = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Exists([string]$path) {
    return Test-Path $path
}

function AgeDays([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    $info = Get-Item $path
    return (New-TimeSpan -Start $info.LastWriteTime -End (Get-Date)).Days
}

$checks = @()

$checks += [pscustomobject]@{Check="Report exists"; Result=(Test-Exists "outputs/report.md")}
$checks += [pscustomobject]@{Check="Dashboard exists"; Result=(Test-Exists "outputs/dashboard.md")}
$checks += [pscustomobject]@{Check="Key events exists"; Result=(Test-Exists "outputs/key_events.md")}
$checks += [pscustomobject]@{Check="Freshness report exists"; Result=(Test-Exists "outputs/freshness_report.md")}
$checks += [pscustomobject]@{Check="Change log exists"; Result=(Test-Exists "outputs/change_log.md")}
$checks += [pscustomobject]@{Check="Drift alerts exists"; Result=(Test-Exists "outputs/drift_alerts.md")}
$checks += [pscustomobject]@{Check="Scenario stress exists"; Result=(Test-Exists "outputs/scenario_stress.md")}
$checks += [pscustomobject]@{Check="Quick review exists"; Result=(Test-Exists "outputs/quick_review.md")}
$checks += [pscustomobject]@{Check="Run log exists"; Result=(Test-Exists "outputs/run_log.md")}
$checks += [pscustomobject]@{Check="Cleanup plan exists"; Result=(Test-Exists "outputs/cleanup_plan.md")}

$chartPaths = @(
    "outputs/charts/revenue_operating_income.png",
    "outputs/charts/margins.png",
    "outputs/charts/fcf_capital_returns.png",
    "outputs/charts/net_cash.png",
    "outputs/charts/peer_multiples.png",
    "outputs/charts/peer_revenue_growth.png",
    "outputs/charts/peer_margins.png"
)

foreach ($c in $chartPaths) {
    $checks += [pscustomobject]@{Check=("Chart exists: " + $c); Result=(Test-Exists $c)}
}

$freshnessAge = AgeDays "outputs/freshness_report.md"
$runLogAge = AgeDays "outputs/run_log.md"

$checks += [pscustomobject]@{Check=("Freshness report age <= {0} days" -f $FreshnessDays); Result=($freshnessAge -ne $null -and $freshnessAge -le $FreshnessDays)}
$checks += [pscustomobject]@{Check=("Run log age <= {0} days" -f $FreshnessDays); Result=($runLogAge -ne $null -and $runLogAge -le $FreshnessDays)}

$report = @()
$report += "# Health Check"
$report += ""
$report += ("Generated: {0:yyyy-MM-dd HH:mm:ss} local time" -f (Get-Date))
$report += ""
$report += "|Check|Result|"
$report += "|---|---|"
foreach ($c in $checks) {
    $report += ("|{0}|{1}|" -f $c.Check, ($(if ($c.Result) { "PASS" } else { "FAIL" })))
}

$failCount = @($checks | Where-Object { -not $_.Result }).Count
$report += ""
$report += ("Failures: {0}" -f $failCount)

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote health check to $OutPath."
