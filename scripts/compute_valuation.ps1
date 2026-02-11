param(
    [Parameter(Mandatory = $true)][double]$Price,
    [string]$AsOfDate = (Get-Date -Format "yyyy-MM-dd"),
    [string]$DataDir = "data",
    [string]$OutDir = "data"
)

function Load-Csv([string]$path) {
    if (-not (Test-Path $path)) {
        Write-Error "Missing required file: $path"
        exit 1
    }
    return Import-Csv $path
}

function To-Num([object]$v) {
    if ($null -eq $v -or $v -eq "") { return $null }
    return [double]$v
}

$income = Load-Csv (Join-Path $DataDir "financials_income.csv")
$balance = Load-Csv (Join-Path $DataDir "financials_balance.csv")
$cashflow = Load-Csv (Join-Path $DataDir "financials_cashflow.csv")
$metricsCash = Load-Csv (Join-Path $DataDir "metrics_cashflow.csv")
$shares = Load-Csv (Join-Path $DataDir "shares_diluted.csv")

$latestFy = ($income.FiscalYear | Sort-Object -Descending | Select-Object -First 1)

function Find-Row($rows, $fy) {
    return $rows | Where-Object { $_.FiscalYear -eq $fy } | Select-Object -First 1
}

$inc = Find-Row $income $latestFy
$bal = Find-Row $balance $latestFy
$cf = Find-Row $cashflow $latestFy
$mc = Find-Row $metricsCash $latestFy
$sh = Find-Row $shares $latestFy

$sharesB = To-Num $sh.DilutedSharesBillions
$netIncome = To-Num $inc.NetIncome
$ebitda = To-Num $mc.EBITDA
$fcf = To-Num $mc.FCF

$cash = To-Num $bal.CashAndEquivalents
$mktCur = To-Num $bal.MarketableSecurities
$mktNon = To-Num $bal.MarketableSecuritiesNoncurrent
$debt = To-Num $bal.TotalDebt

$buyback = To-Num $cf.Buyback
$dividends = To-Num $cf.Dividends

$marketCap = $null
if ($sharesB) { $marketCap = [math]::Round(($Price * $sharesB), 4) }

$netCash = $null
if ($null -ne $cash -or $null -ne $mktCur -or $null -ne $mktNon -or $null -ne $debt) {
    $netCash = 0
    if ($null -ne $cash) { $netCash += $cash }
    if ($null -ne $mktCur) { $netCash += $mktCur }
    if ($null -ne $mktNon) { $netCash += $mktNon }
    if ($null -ne $debt) { $netCash -= $debt }
    $netCash = [math]::Round($netCash, 4)
}

$enterpriseValue = $null
if ($marketCap -and $null -ne $netCash) { $enterpriseValue = [math]::Round(($marketCap - $netCash), 4) }

$pe = if ($marketCap -and $netIncome) { [math]::Round(($marketCap / $netIncome), 4) } else { $null }
$evEbitda = if ($enterpriseValue -and $ebitda) { [math]::Round(($enterpriseValue / $ebitda), 4) } else { $null }
$evFcf = if ($enterpriseValue -and $fcf) { [math]::Round(($enterpriseValue / $fcf), 4) } else { $null }
$pFcf = if ($marketCap -and $fcf) { [math]::Round(($marketCap / $fcf), 4) } else { $null }

$buybackYield = if ($marketCap -and $buyback) { [math]::Round(($buyback / $marketCap), 4) } else { $null }
$divYield = if ($marketCap -and $dividends) { [math]::Round(($dividends / $marketCap), 4) } else { $null }
$payout = if ($netIncome -and $dividends) { [math]::Round(($dividends / $netIncome), 4) } else { $null }
$totalPayout = if ($netIncome -and ($dividends -or $buyback)) {
    $sum = 0
    if ($dividends) { $sum += $dividends }
    if ($buyback) { $sum += $buyback }
    [math]::Round(($sum / $netIncome), 4)
} else { $null }

$row = [pscustomobject]@{
    AsOfDate = $AsOfDate
    Price = $Price
    LatestFiscalYear = $latestFy
    SharesBillions = $sharesB
    MarketCapBillions = $marketCap
    NetIncomeBillions = $netIncome
    EBITDA = $ebitda
    FCF = $fcf
    NetCashBillions = $netCash
    EnterpriseValueBillions = $enterpriseValue
    PE = $pe
    EV_EBITDA = $evEbitda
    EV_FCF = $evFcf
    P_FCF = $pFcf
    BuybackYield = $buybackYield
    DividendYield = $divYield
    PayoutRatio = $payout
    TotalPayoutRatio = $totalPayout
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Force $OutDir | Out-Null
}

$row | Export-Csv -Path (Join-Path $OutDir "valuation_snapshot.csv") -NoTypeInformation
Write-Host "Done. Wrote valuation snapshot to $OutDir."
