param(
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

$income = Load-Csv (Join-Path $DataDir "financials_income.csv")
$balance = Load-Csv (Join-Path $DataDir "financials_balance.csv")
$cashflow = Load-Csv (Join-Path $DataDir "financials_cashflow.csv")
$shares = Load-Csv (Join-Path $DataDir "shares_diluted.csv")

function To-Num([object]$v) {
    if ($null -eq $v -or $v -eq "") { return $null }
    return [double]$v
}

function Index-ByFy($rows) {
    $map = @{}
    foreach ($r in $rows) { $map[$r.FiscalYear] = $r }
    return $map
}

$incMap = Index-ByFy $income
$balMap = Index-ByFy $balance
$cfMap = Index-ByFy $cashflow
$shMap = Index-ByFy $shares

$years = $income.FiscalYear | Sort-Object -Descending

$profitRows = @()
$growthRows = @()
$balanceRows = @()
$cashRows = @()
$cagrRows = @()

for ($i = 0; $i -lt $years.Count; $i++) {
    $fy = $years[$i]
    $inc = $incMap[$fy]
    $bal = $balMap[$fy]
    $cf = $cfMap[$fy]
    $shr = $shMap[$fy]

    $rev = To-Num $inc.Revenue
    $gp = To-Num $inc.GrossProfit
    $op = To-Num $inc.OperatingIncome
    $ni = To-Num $inc.NetIncome

    $gm = if ($rev) { [math]::Round(($gp / $rev), 4) } else { $null }
    $om = if ($rev) { [math]::Round(($op / $rev), 4) } else { $null }
    $nm = if ($rev) { [math]::Round(($ni / $rev), 4) } else { $null }

    $profitRows += [pscustomobject]@{
        FiscalYear = $fy
        GrossMargin = $gm
        OperatingMargin = $om
        NetMargin = $nm
    }

    $prevFy = if ($i + 1 -lt $years.Count) { $years[$i + 1] } else { $null }
    $prevRev = if ($prevFy) { To-Num $incMap[$prevFy].Revenue } else { $null }
    $revYoY = if ($prevRev) { [math]::Round(($rev / $prevRev) - 1, 4) } else { $null }

    $growthRows += [pscustomobject]@{
        FiscalYear = $fy
        RevenueYoY = $revYoY
    }

    $assets = To-Num $bal.TotalAssets
    $equity = To-Num $bal.TotalEquity
    $cash = To-Num $bal.CashAndEquivalents
    $mktCur = To-Num $bal.MarketableSecurities
    $mktNon = To-Num $bal.MarketableSecuritiesNoncurrent
    $debt = To-Num $bal.TotalDebt
    $curAssets = To-Num $bal.CurrentAssets
    $curLiab = To-Num $bal.CurrentLiabilities
    $inventory = To-Num $bal.Inventory
    $roa = if ($assets) { [math]::Round(($ni / $assets), 4) } else { $null }
    $roe = if ($equity) { [math]::Round(($ni / $equity), 4) } else { $null }

    $invested = $null
    if ($null -ne $debt -or $null -ne $equity) {
        $invested = 0
        if ($null -ne $debt) { $invested += $debt }
        if ($null -ne $equity) { $invested += $equity }
        if ($null -ne $cash) { $invested -= $cash }
    }
    $roic = if ($invested -and $op) { [math]::Round(($op / $invested), 4) } else { $null }

    $netCash = $null
    if ($null -ne $cash -or $null -ne $mktCur -or $null -ne $mktNon -or $null -ne $debt) {
        $netCash = 0
        if ($null -ne $cash) { $netCash += $cash }
        if ($null -ne $mktCur) { $netCash += $mktCur }
        if ($null -ne $mktNon) { $netCash += $mktNon }
        if ($null -ne $debt) { $netCash -= $debt }
        $netCash = [math]::Round($netCash, 4)
    }
    $currentRatio = if ($curAssets -and $curLiab) { [math]::Round(($curAssets / $curLiab), 4) } else { $null }
    $quickRatio = if ($curAssets -and $curLiab) {
        $quickBase = if ($null -ne $inventory) { $curAssets - $inventory } else { $curAssets }
        [math]::Round(($quickBase / $curLiab), 4)
    } else { $null }

    $balanceRows += [pscustomobject]@{
        FiscalYear = $fy
        ROA = $roa
        ROE = $roe
        ROIC = $roic
        InvestedCapital = $invested
        NetCash = $netCash
        CurrentRatio = $currentRatio
        QuickRatio = $quickRatio
    }

    $cfo = To-Num $cf.CFO
    $capex = To-Num $cf.Capex
    $fcf = if ($null -ne $cfo -and $null -ne $capex) { [math]::Round(($cfo - $capex), 4) } else { $null }
    $fcfConv = if ($ni -and $fcf) { [math]::Round(($fcf / $ni), 4) } else { $null }
    $capexPct = if ($rev -and $capex) { [math]::Round(($capex / $rev), 4) } else { $null }

    $da = To-Num $cf.DepAmort
    $ebitda = if ($op -and $da) { [math]::Round(($op + $da), 4) } else { $null }
    $ebitdaMargin = if ($rev -and $ebitda) { [math]::Round(($ebitda / $rev), 4) } else { $null }

    $cashRows += [pscustomobject]@{
        FiscalYear = $fy
        FCF = $fcf
        FCFConversion = $fcfConv
        CapexPctRevenue = $capexPct
        EBITDA = $ebitda
        EBITDAMargin = $ebitdaMargin
    }
}

$profitRows | Export-Csv -Path (Join-Path $OutDir "metrics_profitability.csv") -NoTypeInformation
$growthRows | Export-Csv -Path (Join-Path $OutDir "metrics_growth.csv") -NoTypeInformation
$balanceRows | Export-Csv -Path (Join-Path $OutDir "metrics_balance.csv") -NoTypeInformation
$cashRows | Export-Csv -Path (Join-Path $OutDir "metrics_cashflow.csv") -NoTypeInformation

if ($years.Count -ge 2) {
    $startYearKey = [string]$years[-1]
    $endYearKey = [string]$years[0]
    $startYear = [int]$startYearKey
    $endYear = [int]$endYearKey
    $startRev = To-Num $incMap[$startYearKey].Revenue
    $endRev = To-Num $incMap[$endYearKey].Revenue
    $periods = $endYear - $startYear
    $cagr = $null
    if ($startRev -and $endRev -and $periods -gt 0) {
        $cagr = [math]::Round(([math]::Pow(($endRev / $startRev), (1.0 / $periods)) - 1), 4)
    }
    $cagrRows += [pscustomobject]@{
        Metric = "Revenue"
        StartYear = $startYear
        EndYear = $endYear
        StartValue = $startRev
        EndValue = $endRev
        CAGR = $cagr
    }
    $cagrRows | Export-Csv -Path (Join-Path $OutDir "metrics_cagr.csv") -NoTypeInformation
}

Write-Host "Done. Wrote metrics CSVs to $OutDir."
