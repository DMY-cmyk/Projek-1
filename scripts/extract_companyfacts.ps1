param(
    [Parameter(Mandatory = $true)][string]$CompanyFactsPath,
    [string]$OutDir = "data",
    [int]$Years = 5,
    [double]$UsdScale = 1000000000.0
)

if (-not (Test-Path $CompanyFactsPath)) {
    Write-Error "Company facts JSON not found: $CompanyFactsPath"
    exit 1
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Force $OutDir | Out-Null
}

$json = Get-Content $CompanyFactsPath -Raw | ConvertFrom-Json
if ($null -eq $json -or $null -eq $json.facts -or $null -eq $json.facts."us-gaap") {
    Write-Error "Invalid companyfacts JSON structure."
    exit 1
}
$facts = $json.facts."us-gaap"

function Get-Series([string]$tag, [string]$unit = "USD") {
    if (-not $facts.PSObject.Properties.Name.Contains($tag)) { return @() }
    $units = $facts.$tag.units
    if (-not $units.PSObject.Properties.Name.Contains($unit)) { return @() }
    return $units.$unit
}

function Get-FyValue([string]$tag, [string]$unit = "USD", [string]$form = "10-K") {
    $series = Get-Series $tag $unit
    if ($series.Count -eq 0) { return @{} }
    $rows = $series | Where-Object { $_.form -eq $form -and $_.fp -eq "FY" -and $_.fy }
    $byFy = @{}
    foreach ($row in $rows) {
        $byFy[$row.fy] = $row
    }
    return $byFy
}

function Scale-Usd([object]$val) {
    if ($null -eq $val) { return $null }
    return [math]::Round(($val / $UsdScale), 4)
}

$incomeTags = [ordered]@{
    Revenue            = "RevenueFromContractWithCustomerExcludingAssessedTax"
    RevenueAlt         = "SalesRevenueNet"
    GrossProfit        = "GrossProfit"
    OperatingIncome    = "OperatingIncomeLoss"
    NetIncome          = "NetIncomeLoss"
    EPSDiluted         = "EarningsPerShareDiluted"
}

$balanceTags = [ordered]@{
    CashAndEquivalents      = "CashAndCashEquivalentsAtCarryingValue"
    MarketableSecurities    = "MarketableSecuritiesCurrent"
    MarketableSecuritiesNoncurrent = "MarketableSecuritiesNoncurrent"
    TotalDebt               = "Debt"
    TotalEquity             = "StockholdersEquity"
    TotalAssets             = "Assets"
    TotalLiabilities        = "Liabilities"
    CurrentAssets           = "AssetsCurrent"
    CurrentLiabilities      = "LiabilitiesCurrent"
    Inventory               = "InventoryNet"
}

$cashflowTags = [ordered]@{
    CFO     = "NetCashProvidedByUsedInOperatingActivities"
    CFI     = "NetCashProvidedByUsedInInvestingActivities"
    CFF     = "NetCashProvidedByUsedInFinancingActivities"
    Capex   = "PaymentsToAcquirePropertyPlantAndEquipment"
    DepAmort = "DepreciationAndAmortization"
    Buyback = "PaymentsForRepurchaseOfCommonStock"
    Dividends = "PaymentsOfDividends"
}

$sharesTag = "WeightedAverageNumberOfDilutedSharesOutstanding"

$revenueMap = Get-FyValue $incomeTags.Revenue
if ($revenueMap.Count -eq 0) {
    $revenueMap = Get-FyValue $incomeTags.RevenueAlt
}

$fyList = $revenueMap.Keys | Sort-Object -Descending | Select-Object -First $Years

function Get-FyValueWithFallbacks([string[]]$tagList, [string]$unit = "USD", [string]$form = "10-K") {
    foreach ($t in $tagList) {
        $m = Get-FyValue $t $unit $form
        if ($m.Count -gt 0) { return $m }
    }
    return @{}
}

function Get-FyValueSum([string[]]$tagList, [string]$unit = "USD", [string]$form = "10-K") {
    $maps = @()
    foreach ($t in $tagList) {
        $m = Get-FyValue $t $unit $form
        if ($m.Count -gt 0) { $maps += $m }
    }
    if ($maps.Count -eq 0) { return @{} }
    $result = @{}
    $allFys = $maps | ForEach-Object { $_.Keys } | Sort-Object -Unique
    foreach ($fy in $allFys) {
        $sum = 0.0
        foreach ($m in $maps) {
            if ($m.ContainsKey($fy)) { $sum += $m[$fy].val }
        }
        $result[$fy] = @{ val = $sum }
    }
    return $result
}

function Build-Table($tags, [bool]$scaleUsd) {
    $rows = @()
    foreach ($fy in $fyList) {
        $row = [ordered]@{ FiscalYear = $fy }
        foreach ($key in $tags.Keys) {
            $tag = $tags[$key]
            $val = $null
            if ($key -eq "TotalDebt") {
                $map = Get-FyValueSum @("LongTermDebtNoncurrent", "LongTermDebtCurrent", "CommercialPaper")
                if ($map.Count -eq 0) {
                    $map = Get-FyValueSum @("LongTermDebt", "CommercialPaper")
                }
                if ($map.Count -eq 0) {
                    $map = Get-FyValueWithFallbacks @("Debt", "LongTermDebtAndCapitalLeaseObligations")
                }
                if ($map.ContainsKey($fy)) { $val = $map[$fy].val }
                if ($null -ne $val) { $val = Scale-Usd $val }
            } elseif ($key -eq "DepAmort") {
                $map = Get-FyValueWithFallbacks @("DepreciationDepletionAndAmortization", "DepreciationAndAmortization", "Depreciation")
                if ($map.ContainsKey($fy)) { $val = $map[$fy].val }
                if ($scaleUsd) { $val = Scale-Usd $val }
            } elseif ($key -eq "EPSDiluted") {
                $map = Get-FyValue "EarningsPerShareDiluted" "USD/shares"
                if ($map.ContainsKey($fy)) { $val = $map[$fy].val }
            } else {
                $map = Get-FyValue $tag
                if ($map.ContainsKey($fy)) { $val = $map[$fy].val }
                if ($scaleUsd) { $val = Scale-Usd $val }
            }
            $row[$key] = $val
        }
        $rows += [pscustomobject]$row
    }
    return $rows
}

$incomeRows = Build-Table $incomeTags $true
$balanceRows = Build-Table $balanceTags $true
$cashflowRows = Build-Table $cashflowTags $true

$sharesMap = Get-FyValue $sharesTag "shares"
if ($sharesMap.Count -eq 0) { $sharesMap = Get-FyValue $sharesTag }
$sharesRows = @()
foreach ($fy in $fyList) {
    $val = $null
    if ($sharesMap.ContainsKey($fy)) { $val = $sharesMap[$fy].val }
    if ($null -ne $val) { $val = [math]::Round(($val / 1000000000.0), 4) }
    $sharesRows += [pscustomobject]@{ FiscalYear = $fy; DilutedSharesBillions = $val }
}

$incomeRows | Export-Csv -Path (Join-Path $OutDir "financials_income.csv") -NoTypeInformation
$balanceRows | Export-Csv -Path (Join-Path $OutDir "financials_balance.csv") -NoTypeInformation
$cashflowRows | Export-Csv -Path (Join-Path $OutDir "financials_cashflow.csv") -NoTypeInformation
$sharesRows | Export-Csv -Path (Join-Path $OutDir "shares_diluted.csv") -NoTypeInformation

Write-Host "Done. Wrote CSVs to $OutDir."
