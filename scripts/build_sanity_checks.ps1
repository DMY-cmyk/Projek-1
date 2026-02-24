param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/sanity_checks.md"
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

function Check-Range([string]$name, [double]$value, [double]$min, [double]$max) {
    return [pscustomobject]@{
        Check = $name
        Value = [math]::Round($value, 4)
        Result = if ($value -ge $min -and $value -le $max) { "PASS" } else { "FAIL" }
    }
}

$income = Load-Csv (Join-Path $DataDir "financials_income.csv") | Sort-Object -Property FiscalYear
$balance = Load-Csv (Join-Path $DataDir "financials_balance.csv") | Sort-Object -Property FiscalYear
$profit = Load-Csv (Join-Path $DataDir "metrics_profitability.csv") | Sort-Object -Property FiscalYear
$balanceMetrics = Load-Csv (Join-Path $DataDir "metrics_balance.csv") | Sort-Object -Property FiscalYear

$latestIncome = $income | Select-Object -Last 1
$latestBalance = $balance | Select-Object -Last 1
$latestProfit = $profit | Select-Object -Last 1
$latestBalanceMetrics = $balanceMetrics | Select-Object -Last 1

$checks = @()
$checks += Check-Range "Gross margin in [0,1]" ([double]$latestProfit.GrossMargin) 0 1
$checks += Check-Range "Operating margin in [0,1]" ([double]$latestProfit.OperatingMargin) 0 1
$checks += Check-Range "Net margin in [0,1]" ([double]$latestProfit.NetMargin) 0 1
$checks += Check-Range "Current ratio > 0" ([double]$latestBalanceMetrics.CurrentRatio) 0 10
$checks += Check-Range "Quick ratio > 0" ([double]$latestBalanceMetrics.QuickRatio) 0 10

$cash = [double]$latestBalance.CashAndEquivalents
$mktSec = [double]$latestBalance.MarketableSecurities
$mktSecNoncurrent = [double]$latestBalance.MarketableSecuritiesNoncurrent
$totalDebt = [double]$latestBalance.TotalDebt
$netCashCalc = $cash + $mktSec + $mktSecNoncurrent - $totalDebt
$netCashReported = [double]$latestBalanceMetrics.NetCash
$netCashDelta = [math]::Round(($netCashCalc - $netCashReported), 3)

$checks += [pscustomobject]@{
    Check = "Net cash calc ~ reported (USD B)"
    Value = $netCashDelta
    Result = if ([math]::Abs($netCashDelta) -le 1.0) { "PASS" } else { "FAIL" }
}

$report = @()
$report += "# Sanity Checks"
$report += ""
$report += ("Latest fiscal year: FY{0}" -f $latestIncome.FiscalYear)
$report += ""
$report += "|Check|Value|Result|"
$report += "|---|---|---|"
foreach ($c in $checks) {
    $report += ("|{0}|{1}|{2}|" -f $c.Check, $c.Value, $c.Result)
}

$fails = @($checks | Where-Object { $_.Result -ne "PASS" })
$report += ""
$report += ("Failures: {0}" -f $fails.Count)

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote sanity checks to $OutPath."
