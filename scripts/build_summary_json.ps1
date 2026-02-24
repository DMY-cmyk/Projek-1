param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/summary.json"
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

$income = Load-Csv (Join-Path $DataDir "financials_income.csv") | Sort-Object -Property FiscalYear
$metricsProfit = Load-Csv (Join-Path $DataDir "metrics_profitability.csv") | Sort-Object -Property FiscalYear
$metricsCash = Load-Csv (Join-Path $DataDir "metrics_cashflow.csv") | Sort-Object -Property FiscalYear
$metricsBalance = Load-Csv (Join-Path $DataDir "metrics_balance.csv") | Sort-Object -Property FiscalYear
$valuation = Load-Csv (Join-Path $DataDir "valuation_snapshot.csv") | Sort-Object -Property AsOfDate

$latestIncome = $income | Select-Object -Last 1
$latestProfit = $metricsProfit | Select-Object -Last 1
$latestCash = $metricsCash | Select-Object -Last 1
$latestBalance = $metricsBalance | Select-Object -Last 1
$latestValuation = $valuation | Select-Object -Last 1

$summary = [pscustomobject]@{
    generated_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    fiscal_year = [int]$latestIncome.FiscalYear
    revenue = [double]$latestIncome.Revenue
    gross_margin = [double]$latestProfit.GrossMargin
    operating_margin = [double]$latestProfit.OperatingMargin
    net_margin = [double]$latestProfit.NetMargin
    fcf = [double]$latestCash.FCF
    fcf_conversion = [double]$latestCash.FCFConversion
    net_cash = [double]$latestBalance.NetCash
    current_ratio = [double]$latestBalance.CurrentRatio
    quick_ratio = [double]$latestBalance.QuickRatio
    valuation = @{
        as_of_date = $latestValuation.AsOfDate
        price = [double]$latestValuation.Price
        market_cap_billions = [double]$latestValuation.MarketCapBillions
        enterprise_value_billions = [double]$latestValuation.EnterpriseValueBillions
        pe = [double]$latestValuation.PE
        ev_ebitda = [double]$latestValuation.EV_EBITDA
        ev_fcf = [double]$latestValuation.EV_FCF
        p_fcf = [double]$latestValuation.P_FCF
    }
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$summary | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote summary JSON to $OutPath."
