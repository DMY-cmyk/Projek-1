param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/report.md"
)

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
$balance = Load-Csv (Join-Path $DataDir "financials_balance.csv")
$cashflow = Load-Csv (Join-Path $DataDir "financials_cashflow.csv")
$metricsProfit = Load-Csv (Join-Path $DataDir "metrics_profitability.csv")
$metricsGrowth = Load-Csv (Join-Path $DataDir "metrics_growth.csv")
$metricsBalance = Load-Csv (Join-Path $DataDir "metrics_balance.csv")
$metricsCash = Load-Csv (Join-Path $DataDir "metrics_cashflow.csv")
$valuation = Load-Csv (Join-Path $DataDir "valuation_snapshot.csv")

$report = @()
$report += "# Apple Fundamentals Report"
$report += ""
$report += "## Executive Summary"
$report += "- TODO: Summarize key takeaways."
$report += ""
$report += "## Business Overview"
$report += "- See `research/notes_business_overview.md` for structured notes."
$report += ""
$report += "## Financials"
$report += "### Income Statement (USD billions)"
$report += To-MdTable $income @("FiscalYear","Revenue","GrossProfit","OperatingIncome","NetIncome")
$report += ""
$report += "### Balance Sheet (USD billions)"
$report += To-MdTable $balance @("FiscalYear","CashAndEquivalents","MarketableSecurities","MarketableSecuritiesNoncurrent","TotalDebt","TotalEquity")
$report += ""
$report += "### Cash Flow (USD billions)"
$report += To-MdTable $cashflow @("FiscalYear","CFO","Capex","Buyback","Dividends")
$report += ""
$report += "## Metrics"
$report += "### Profitability"
$report += To-MdTable $metricsProfit @("FiscalYear","GrossMargin","OperatingMargin","NetMargin")
$report += ""
$report += "### Growth"
$report += To-MdTable $metricsGrowth @("FiscalYear","RevenueYoY")
$report += ""
$report += "### Balance Sheet and Liquidity"
$report += To-MdTable $metricsBalance @("FiscalYear","ROA","ROE","ROIC","NetCash","CurrentRatio","QuickRatio")
$report += ""
$report += "### Cash Flow Quality"
$report += To-MdTable $metricsCash @("FiscalYear","FCF","FCFConversion","CapexPctRevenue","EBITDA","EBITDAMargin")
$report += ""
$report += "## Valuation Snapshot"
$report += To-MdTable $valuation @("AsOfDate","Price","MarketCapBillions","EnterpriseValueBillions","PE","EV_EBITDA","EV_FCF","P_FCF","BuybackYield","DividendYield","PayoutRatio","TotalPayoutRatio")
$report += ""
$report += "## Competitive Landscape and Risks"
$report += "- See `research/notes_competitive_risks.md`."
$report += ""
$report += "## Management and Governance"
$report += "- See `research/notes_management_governance.md`."
$report += ""
$report += "## Thesis and Scenarios"
$report += "- See `research/notes_thesis_scenarios.md`."
$report += ""
$report += "## Appendix"
$report += "- Data sources: `research/sec/`, `research/market_price_source.txt`."

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote report to $OutPath."
