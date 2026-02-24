param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/dashboard.md",
    [string]$ChartsDir = "outputs/charts"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Load-Csv([string]$path) {
    if (-not (Test-Path $path)) {
        Write-Error "Missing required file: $path"
        exit 1
    }
    return Import-Csv $path
}

function To-MdTable($rows, [string[]]$columns) {
    $header = "|" + ($columns -join "|") + "|"
    $sep = "|" + (($columns | ForEach-Object { "---" }) -join "|") + "|"
    $lines = @($header, $sep)
    foreach ($r in $rows) {
        $vals = @()
        foreach ($c in $columns) {
            $v = $r.$c
            if ($null -eq $v -or $v -eq "") { $v = "" }
            $vals += $v
        }
        $lines += "|" + ($vals -join "|") + "|"
    }
    return $lines -join "`n"
}

$income = Load-Csv (Join-Path $DataDir "financials_income.csv")
$metricsProfit = Load-Csv (Join-Path $DataDir "metrics_profitability.csv")
$metricsCash = Load-Csv (Join-Path $DataDir "metrics_cashflow.csv")
$valuation = Load-Csv (Join-Path $DataDir "valuation_snapshot.csv")
$metricsGrowth = Load-Csv (Join-Path $DataDir "metrics_growth.csv")

$latestIncome = $income | Sort-Object -Property FiscalYear -Descending | Select-Object -First 1
$latestMargins = $metricsProfit | Sort-Object -Property FiscalYear -Descending | Select-Object -First 1
$latestCash = $metricsCash | Sort-Object -Property FiscalYear -Descending | Select-Object -First 1
$latestValuation = $valuation | Sort-Object -Property AsOfDate -Descending | Select-Object -First 1
$latestGrowth = $metricsGrowth | Sort-Object -Property FiscalYear -Descending | Select-Object -First 1

$dashboard = @()
$dashboard += "# Apple Quarterly Monitoring Dashboard"
$dashboard += ""
$dashboard += "## Snapshot (Latest Annual)"
$dashboard += "- Fiscal year: FY$($latestIncome.FiscalYear)"
$dashboard += ("- Revenue: {0}B (YoY {1:P2})" -f $latestIncome.Revenue, [double]$latestGrowth.RevenueYoY)
$dashboard += ("- Gross margin: {0:P2}" -f [double]$latestMargins.GrossMargin)
$dashboard += ("- Operating margin: {0:P2}" -f [double]$latestMargins.OperatingMargin)
$dashboard += ("- Net margin: {0:P2}" -f [double]$latestMargins.NetMargin)
$dashboard += ("- Free cash flow: {0}B (FCF conversion {1:P2})" -f $latestCash.FCF, [double]$latestCash.FCFConversion)
$dashboard += ""
$dashboard += "## Market Snapshot"
$dashboard += To-MdTable @($latestValuation) @("AsOfDate","Price","MarketCapBillions","EnterpriseValueBillions","PE","EV_EBITDA","EV_FCF","P_FCF","BuybackYield","DividendYield")
$dashboard += ""
$dashboard += "## KPI Trend (Annual)"
$dashboard += "Charts source: `outputs/charts/` (run `scripts/build_charts.ps1`)."
$dashboard += ""
$dashboard += "![Revenue and Operating Income](charts/revenue_operating_income.png)"
$dashboard += ""
$dashboard += "![Margins](charts/margins.png)"
$dashboard += ""
$dashboard += "![Free Cash Flow and Capital Returns](charts/fcf_capital_returns.png)"
$dashboard += ""
$dashboard += "## Key Events"
$dashboard += "See `outputs/key_events.md` (run `scripts/build_key_events.ps1`)."
$dashboard += ""
$dashboard += "## Data Freshness"
$dashboard += "See `outputs/freshness_report.md` (run `scripts/check_data_freshness.ps1`)."
$dashboard += ""
$dashboard += "## Change Log"
$dashboard += "See `outputs/change_log.md` (run `scripts/build_change_log.ps1`)."
$dashboard += ""
$dashboard += "## Drift Alerts"
$dashboard += "See `outputs/drift_alerts.md` (run `scripts/build_drift_alerts.ps1`)."
$dashboard += ""
$dashboard += "## Scenario Stress"
$dashboard += "See `outputs/scenario_stress.md` (run `scripts/build_scenario_stress.ps1`)."
$dashboard += ""
$dashboard += "## Report Pack"
$dashboard += "Run all generators and capture a run log in `outputs/run_log.md` (run `scripts/build_report_pack.ps1`)."
$dashboard += ""
$dashboard += "## Refresh Status"
$dashboard += "Verify expected outputs with `outputs/refresh_status.md` (run `scripts/refresh_all_status.ps1`)."
$dashboard += ""
$dashboard += "## Quick Review"
$dashboard += "Summarize key outputs in `outputs/quick_review.md` (run `scripts/build_quick_review.ps1`)."
$dashboard += ""
$dashboard += "## Cleanup Plan"
$dashboard += "See `outputs/cleanup_plan.md` (dry run via `scripts/cleanup_runs.ps1`)."
$dashboard += ""
$dashboard += "## Health Check"
$dashboard += "See `outputs/health_check.md` (run `scripts/build_health_check.ps1`)."
$dashboard += ""
$dashboard += "## Summary JSON"
$dashboard += "Machine-readable snapshot in `outputs/summary.json` (run `scripts/build_summary_json.ps1`)."
$dashboard += ""
$dashboard += "## Export Bundle"
$dashboard += "Zip bundle in `outputs/export_bundle.zip` (run `scripts/build_export_bundle.ps1`)."
$dashboard += ""
$dashboard += "## Outputs Manifest"
$dashboard += "Integrity manifest in `outputs/manifest.json` (run `scripts/build_outputs_manifest.ps1`)."
$dashboard += ""
$dashboard += "## Report Pack (CI)"
$dashboard += "CI-friendly run log in `outputs/run_log_ci.md` (run `scripts/build_report_pack_ci.ps1`)."
$dashboard += ""
$dashboard += "## Sanity Checks"
$dashboard += "Validate basic relationships in `outputs/sanity_checks.md` (run `scripts/build_sanity_checks.ps1`)."
$dashboard += ""
$dashboard += "## Quarterly Inputs (Optional)"
$dashboard += "If quarterly CSVs exist, drop them into `data/quarterly_*.csv` and re-run this script."
$dashboard += "Expected columns: `Period`, `Revenue`, `GrossMargin`, `OperatingMargin`, `NetMargin`, `FCF`."

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$dashboard -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote dashboard to $OutPath."
