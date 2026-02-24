param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/change_log.md"
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

function Get-Delta([double]$current, [double]$previous) {
    return $current - $previous
}

$income = Load-Csv (Join-Path $DataDir "financials_income.csv") | Sort-Object -Property FiscalYear
$metricsProfit = Load-Csv (Join-Path $DataDir "metrics_profitability.csv") | Sort-Object -Property FiscalYear
$metricsBalance = Load-Csv (Join-Path $DataDir "metrics_balance.csv") | Sort-Object -Property FiscalYear
$metricsCash = Load-Csv (Join-Path $DataDir "metrics_cashflow.csv") | Sort-Object -Property FiscalYear
$cashflow = Load-Csv (Join-Path $DataDir "financials_cashflow.csv") | Sort-Object -Property FiscalYear

$latestIncome = $income | Select-Object -Last 1
$priorIncome = $income | Select-Object -Last 2 | Select-Object -First 1
$latestProfit = $metricsProfit | Select-Object -Last 1
$priorProfit = $metricsProfit | Select-Object -Last 2 | Select-Object -First 1
$latestBalance = $metricsBalance | Select-Object -Last 1
$priorBalance = $metricsBalance | Select-Object -Last 2 | Select-Object -First 1
$latestCash = $metricsCash | Select-Object -Last 1
$priorCash = $metricsCash | Select-Object -Last 2 | Select-Object -First 1
$latestCashflow = $cashflow | Select-Object -Last 1
$priorCashflow = $cashflow | Select-Object -Last 2 | Select-Object -First 1

$rows = @()
$rows += [pscustomobject]@{
    Metric = "Revenue (USD B)"
    Latest = $latestIncome.Revenue
    Prior = $priorIncome.Revenue
    Change = [math]::Round((Get-Delta $latestIncome.Revenue $priorIncome.Revenue), 3)
}
$rows += [pscustomobject]@{
    Metric = "Operating Income (USD B)"
    Latest = $latestIncome.OperatingIncome
    Prior = $priorIncome.OperatingIncome
    Change = [math]::Round((Get-Delta $latestIncome.OperatingIncome $priorIncome.OperatingIncome), 3)
}
$rows += [pscustomobject]@{
    Metric = "Net Income (USD B)"
    Latest = $latestIncome.NetIncome
    Prior = $priorIncome.NetIncome
    Change = [math]::Round((Get-Delta $latestIncome.NetIncome $priorIncome.NetIncome), 3)
}
$rows += [pscustomobject]@{
    Metric = "Gross Margin"
    Latest = $latestProfit.GrossMargin
    Prior = $priorProfit.GrossMargin
    Change = [math]::Round((Get-Delta $latestProfit.GrossMargin $priorProfit.GrossMargin), 4)
}
$rows += [pscustomobject]@{
    Metric = "Operating Margin"
    Latest = $latestProfit.OperatingMargin
    Prior = $priorProfit.OperatingMargin
    Change = [math]::Round((Get-Delta $latestProfit.OperatingMargin $priorProfit.OperatingMargin), 4)
}
$rows += [pscustomobject]@{
    Metric = "Net Margin"
    Latest = $latestProfit.NetMargin
    Prior = $priorProfit.NetMargin
    Change = [math]::Round((Get-Delta $latestProfit.NetMargin $priorProfit.NetMargin), 4)
}
$rows += [pscustomobject]@{
    Metric = "Net Cash (USD B)"
    Latest = $latestBalance.NetCash
    Prior = $priorBalance.NetCash
    Change = [math]::Round((Get-Delta $latestBalance.NetCash $priorBalance.NetCash), 3)
}
$rows += [pscustomobject]@{
    Metric = "Free Cash Flow (USD B)"
    Latest = $latestCash.FCF
    Prior = $priorCash.FCF
    Change = [math]::Round((Get-Delta $latestCash.FCF $priorCash.FCF), 3)
}
$rows += [pscustomobject]@{
    Metric = "Buybacks (USD B)"
    Latest = $latestCashflow.Buyback
    Prior = $priorCashflow.Buyback
    Change = [math]::Round((Get-Delta $latestCashflow.Buyback $priorCashflow.Buyback), 3)
}
$rows += [pscustomobject]@{
    Metric = "Dividends (USD B)"
    Latest = $latestCashflow.Dividends
    Prior = $priorCashflow.Dividends
    Change = [math]::Round((Get-Delta $latestCashflow.Dividends $priorCashflow.Dividends), 3)
}

$report = @()
$report += "# Change Log"
$report += ""
$report += ("Latest vs prior fiscal year: FY{0} vs FY{1}" -f $latestIncome.FiscalYear, $priorIncome.FiscalYear)
$report += ""
$report += To-MdTable $rows @("Metric","Latest","Prior","Change")
$report += ""
$report += "Notes:"
$report += "- Positive Change means latest year is higher than the prior year."
$report += "- Margins are shown as decimals (e.g., 0.4691 = 46.91%)."

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote change log to $OutPath."
