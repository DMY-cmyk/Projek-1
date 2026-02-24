param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/report.md"
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

function Get-Median([double[]]$values) {
    if (-not $values -or $values.Count -eq 0) { return $null }
    $sorted = $values | Sort-Object
    $count = $sorted.Count
    if ($count % 2 -eq 1) {
        return [double]$sorted[($count - 1) / 2]
    }
    $mid1 = [double]$sorted[($count / 2) - 1]
    $mid2 = [double]$sorted[$count / 2]
    return ($mid1 + $mid2) / 2.0
}

$income = Load-Csv (Join-Path $DataDir "financials_income.csv")
$balance = Load-Csv (Join-Path $DataDir "financials_balance.csv")
$cashflow = Load-Csv (Join-Path $DataDir "financials_cashflow.csv")
$metricsProfit = Load-Csv (Join-Path $DataDir "metrics_profitability.csv")
$metricsGrowth = Load-Csv (Join-Path $DataDir "metrics_growth.csv")
$metricsBalance = Load-Csv (Join-Path $DataDir "metrics_balance.csv")
$metricsCash = Load-Csv (Join-Path $DataDir "metrics_cashflow.csv")
$valuation = Load-Csv (Join-Path $DataDir "valuation_snapshot.csv")

$latestIncome = $income | Sort-Object -Property FiscalYear -Descending | Select-Object -First 1
$latestRevenue = [double]$latestIncome.Revenue
$latestGrossMargin = [double]$latestIncome.GrossProfit / $latestRevenue
$latestOperatingMargin = [double]$latestIncome.OperatingIncome / $latestRevenue
$latestNetMargin = [double]$latestIncome.NetIncome / $latestRevenue
$onePctRevenue = $latestRevenue * 0.01
$netIncomeImpact = $onePctRevenue * $latestNetMargin

$peerPath = Join-Path $DataDir "peer_multiples.csv"
$peerData = @()
if (Test-Path $peerPath) {
    $peerData = Import-Csv $peerPath
}

$peerPe = Get-Median ($peerData | ForEach-Object { [double]$_.PE })
$peerEvEbitda = Get-Median ($peerData | ForEach-Object { [double]$_.EV_EBITDA })
$peerPfcf = Get-Median ($peerData | ForEach-Object { [double]$_.P_FCF })

$report = @()
$report += '# Apple Fundamentals Report'
$report += ''
$report += '## Executive Summary'
$report += '- FY2025 revenue was $416.161B with YoY growth of 6.43%.'
$report += '- Profitability remained strong with FY2025 gross margin 46.9%, operating margin 32.0%, and net margin 26.9%.'
$report += '- FY2025 free cash flow was $98.767B with FCF conversion of 0.882.'
$report += '- Net cash at FY2025 was $33.763B; liquidity ratios remained below 1.0 (current ratio 0.893).'
$report += '- Capital returns remained large (FY2025 buybacks $90.711B, dividends $15.421B).'
$report += '- Valuation snapshot (2026-02-20 close) implies elevated multiples vs cash flow yields.'
$report += '- A simplified DCF base case produces an illustrative equity value per share below the snapshot price, implying higher growth/margins are priced in.'
$report += ''
$report += '## Business Overview'
$report += 'Source notes: `research/notes_business_overview.md`'
$report += '- Apple sells hardware (iPhone, Mac, iPad, wearables, home devices, accessories) and services (advertising, AppleCare, cloud services, digital content, payment services).'
$report += '- The Company manages its business by geography: Americas, Europe, Greater China, Japan, Rest of Asia Pacific.'
$report += '- Distribution: direct channels (retail/online/direct sales) and indirect channels (carriers/resellers); FY2025 net sales mix was 40% direct and 60% indirect.'
$report += ''
$report += 'The portfolio mix underscores a large device installed base that supports services revenue. Services are delivered primarily through Apple platforms (App Store, subscriptions, cloud, payments), while product cycles remain the main driver of absolute revenue changes. Geographic segmentation reflects exposure to macro and FX conditions across major regions, with the Americas and Europe providing the majority of sales.'
$report += ''
$report += 'Strategy emphasis in the FY2025 10-K highlights pricing pressure, ongoing innovation and R&D, supply chain resilience, and continued services expansion. The business model is reinforced by ecosystem interdependence: services usage increases device stickiness, and device adoption expands the services addressable base.'
$report += ''
$report += 'FY2025 net sales by product (USD billions):'
$report += '|Product|NetSales|'
$report += '|---|---|'
$report += '|iPhone|209.586|'
$report += '|Mac|33.708|'
$report += '|iPad|28.023|'
$report += '|Wearables, Home and Accessories|35.686|'
$report += '|Services|109.158|'
$report += '|Total|416.161|'
$report += ''
$report += 'FY2025 net sales by geography (USD billions):'
$report += '|Region|NetSales|'
$report += '|---|---|'
$report += '|Americas|178.353|'
$report += '|Europe|111.032|'
$report += '|Greater China|64.377|'
$report += '|Japan|28.703|'
$report += '|Rest of Asia Pacific|33.696|'
$report += '|Total|416.161|'
$report += ''
$report += '## Financials'
$report += '### Income Statement (USD billions)'
$report += To-MdTable $income @("FiscalYear","Revenue","GrossProfit","OperatingIncome","NetIncome")
$report += ''
$report += 'One-time item note:'
$report += '- FY2024 included a one-time net income tax charge of $10.2B related to the EU State Aid decision (see `data/one_time_items_notes.md`).'
$report += ''
$report += '### Balance Sheet (USD billions)'
$report += To-MdTable $balance @("FiscalYear","CashAndEquivalents","MarketableSecurities","MarketableSecuritiesNoncurrent","TotalDebt","TotalEquity")
$report += ''
$report += 'Debt and liquidity notes (FY2025 10-K):'
$report += '- Fixed-rate notes outstanding: $91.3B with $12.4B due within 12 months.'
$report += '- Future interest payments on notes: $37.0B total, $2.6B due within 12 months.'
$report += '- Commercial paper outstanding: $8.0B due within 12 months.'
$report += '- Interest rate sensitivity: +100 bps implies +$129M annual interest expense for term debt.'
$report += ''
$report += '### Cash Flow (USD billions)'
$report += To-MdTable $cashflow @("FiscalYear","CFO","Capex","Buyback","Dividends")
$report += ''
$report += '## Charts'
$report += 'Source: `data/*.csv` (derived from SEC data.sec.gov). Period: FY2021-FY2025. Generated with `scripts/build_charts.ps1`.'
$report += ''
$report += '![Revenue and Operating Income (USD Billions)](charts/revenue_operating_income.png)'
$report += ''
$report += '![Margins (Percent)](charts/margins.png)'
$report += ''
$report += '![Free Cash Flow and Capital Returns (USD Billions)](charts/fcf_capital_returns.png)'
$report += ''
$report += '![Net Cash (USD Billions)](charts/net_cash.png)'
$report += ''
$report += '## Metrics'
$report += '### Profitability'
$report += To-MdTable $metricsProfit @("FiscalYear","GrossMargin","OperatingMargin","NetMargin")
$report += ''
$report += '### Growth'
$report += To-MdTable $metricsGrowth @("FiscalYear","RevenueYoY")
$report += ''
$report += '### Balance Sheet and Liquidity'
$report += To-MdTable $metricsBalance @("FiscalYear","ROA","ROE","ROIC","NetCash","CurrentRatio","QuickRatio")
$report += ''
$report += '### Cash Flow Quality'
$report += To-MdTable $metricsCash @("FiscalYear","FCF","FCFConversion","CapexPctRevenue","EBITDA","EBITDAMargin")
$report += ''
$report += '## Competitive Landscape and Risks'
$report += 'Source notes: `research/notes_competitive_risks.md`'
$report += '- Competitive intensity is high across hardware and services, with aggressive pricing and short product cycles.'
$report += '- Component supply risks persist due to limited-source parts and competition for supply.'
$report += '- Geographic exposure introduces macro and FX sensitivity.'
$report += ''
$report += 'Platform and regulatory exposure are structurally important because digital services depend on App Store distribution and on-device monetization. Changes to platform rules, privacy regulation, or payment policies could alter services economics. These risks are directional inferences from the 10-K risk factors and should be re-validated against the latest regulatory actions.'
$report += ''
$report += 'Greater China remains a meaningful contributor to revenue (15.47% in FY2025) and experienced a YoY decline, which adds sensitivity to regional demand trends and competitive dynamics.'
$report += ''
$report += '## Management and Governance'
$report += 'Source notes: `research/notes_management_governance.md`'
$report += '- 2026 proxy lists eight director nominees, with the Board indicating all directors except the CEO are independent.'
$report += '- 2025 say-on-pay received 92% support.'
$report += ''
$report += 'Committee composition in the 2026 proxy shows continued emphasis on independent oversight across audit/finance, compensation, and governance. Shareholder proposals in 2026 include a request for a China entanglement audit, indicating ongoing stakeholder focus on geopolitical and supply chain risk.'
$report += ''
$report += '## Valuation Snapshot'
$report += To-MdTable $valuation @("AsOfDate","Price","MarketCapBillions","EnterpriseValueBillions","PE","EV_EBITDA","EV_FCF","P_FCF","BuybackYield","DividendYield","PayoutRatio","TotalPayoutRatio")
$report += ''
$report += '## Non-Recurring Items and Multiples'
$report += '- **FY2025 (latest year, used for snapshot multiples):** No material one-time items identified. The P/E of 35.4 and other multiples reflect clean operating earnings.'
$report += '- **FY2024 impact on trailing comparisons:** The $10.2B one-time EU State Aid tax charge reduced FY2024 reported net income to $93.7B. Excluding the charge, adjusted FY2024 net income would be ~$103.9B. This means:'
$report += '  - Reported FY2024 to FY2025 net income growth appears +19.5%, but adjusted growth is ~+7.8%.'
$report += '  - FY2024 FCF conversion of 1.16x (vs. typical ~1.0x) is inflated because the tax charge reduced reported net income while cash flow was unaffected (the $15.8B payment to Ireland occurred in FY2024 Q4 but was classified as an investing outflow per the escrow arrangement).'
$report += '- **Conclusion:** Current snapshot multiples (based on FY2025) are not distorted by one-time items. However, YoY growth comparisons vs FY2024 should be interpreted with the EU tax charge in mind.'
$report += ''
$report += '## Valuation Context'
if ($peerPe -and $peerEvEbitda -and $peerPfcf) {
    $report += ("- Peer median multiples (Apple, Microsoft, Alphabet, Samsung): P/E {0:N2}, EV/EBITDA {1:N2}, P/FCF {2:N2}." -f $peerPe, $peerEvEbitda, $peerPfcf)
} else {
    $report += '- Peer median multiples (Apple, Microsoft, Alphabet, Samsung): N/A (missing data/peer_multiples.csv).'
}
$report += '- Apple current multiples vs peer median: P/E and EV/EBITDA remain above the peer median; P/FCF is also above median.'
$report += '- Historical context: Macrotrends provides multi-year series for Apple P/E and price-to-free-cash-flow; use those charts for historical range context.'
$report += ''
$report += 'Peer multiples chart (as of latest closes shown in sources; see `data/peer_multiples.csv` and `research/peer_multiples_sources.md`):'
$report += ''
$report += '![Peer Valuation Multiples (As of latest close)](charts/peer_multiples.png)'
$report += ''
$report += '## Peer Fundamentals'
$report += 'Source: `data/peer_fundamentals.csv` and `research/peer_fundamentals_sources.md` (latest fiscal years for each peer).'
$report += ''
$report += '![Peer Revenue Growth (Latest Fiscal Year)](charts/peer_revenue_growth.png)'
$report += ''
$report += '![Peer Margins (Latest Fiscal Year)](charts/peer_margins.png)'
$report += ''
$report += '## Quantified Sensitivities (FY' + $latestIncome.FiscalYear + ')'
$report += ("- 1% change in revenue implies about ${0:N2}B revenue swing." -f $onePctRevenue)
$report += ("- 100 bps change in gross margin implies about ${0:N2}B change in gross profit." -f $onePctRevenue)
$report += ("- 100 bps change in operating margin implies about ${0:N2}B change in operating income." -f $onePctRevenue)
$report += ("- At FY{0} net margin of {1:N1}%, a 1% revenue swing implies about ${2:N2}B net income impact." -f $latestIncome.FiscalYear, ($latestNetMargin * 100), $netIncomeImpact)
$report += ''
$report += '## DCF Base Case (Illustrative)'
$report += 'Source: `models/dcf_summary.md`, `models/dcf_scenarios.csv`, `models/dcf_sensitivity.csv`'
$report += '- Equity value per share (illustrative): $141.61'
$report += '- Key assumptions: 3% revenue growth, 31.5% EBIT margin, 8.0% WACC, 2.5% terminal growth.'
$report += '- This DCF is simplified and intended as a sensitivity anchor rather than a definitive valuation.'
$report += '- Scenario range (bull/base/bear): $194.05 / $141.61 / $96.11 per share.'
$report += '- The 2026-02-20 close price of $264.58 is above the base and bull scenarios, implying the market is pricing in higher growth or margins than the base case.'
$report += ''
$report += '## Thesis and Scenarios'
$report += 'Source notes: `research/notes_thesis_scenarios.md`'
$report += '- Bull: services mix expansion and stronger upgrade cycles drive higher growth.'
$report += '- Base: low single-digit growth with stable margins and continued capital returns.'
$report += '- Bear: price pressure and slower device demand compress margins and growth.'
$report += ''
$report += 'Key KPIs to monitor each quarter include total revenue growth, services mix, iPhone cycle strength, and margin stability. Capital return pace (buybacks and dividends) is a key indicator of management confidence and capital discipline.'
$report += ''
$report += '## Appendix'
$report += '- Data sources: `research/sec/`, `research/market_price_source.txt`, `research/peer_multiples_sources.md`.'
$report += '- Assumptions and calculations: `data/`, `models/dcf_summary.md`.'
$report += '- Reconciliation checks: `data/reconciliation_notes.md`, `data/reconciliation_balance_sheet.md`, `data/reconciliation_cashflow.md`.'
$report += '- Latest filings log: `outputs/key_events.md`.'
$report += '- Data freshness: `outputs/freshness_report.md`.'
$report += '- Change log: `outputs/change_log.md`.'
$report += '- Drift alerts: `outputs/drift_alerts.md`.'
$report += '- Scenario stress: `outputs/scenario_stress.md`.'
$report += '- Report pack log: `outputs/run_log.md`.'
$report += '- Refresh status: `outputs/refresh_status.md`.'
$report += '- Quick review: `outputs/quick_review.md`.'
$report += '- Cleanup plan (dry run): `outputs/cleanup_plan.md`.'
$report += '- Health check: `outputs/health_check.md`.'
$report += '- Summary JSON: `outputs/summary.json`.'

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote report to $OutPath."
