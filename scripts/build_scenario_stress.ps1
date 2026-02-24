param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/scenario_stress.md",
    [double[]]$RevenueShocks = @(-0.05, 0.0, 0.05),
    [double[]]$OperatingMarginShocks = @(-0.02, 0.0, 0.02),
    [double[]]$WaccShocks = @(0.00, 0.01, 0.02),
    [double]$BaseWacc = 0.08
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

$income = Load-Csv (Join-Path $DataDir "financials_income.csv") | Sort-Object -Property FiscalYear
$latestIncome = $income | Select-Object -Last 1

$baseRevenue = [double]$latestIncome.Revenue
$baseOperatingMargin = [double]$latestIncome.OperatingIncome / [double]$latestIncome.Revenue

$rows = @()
foreach ($rShock in $RevenueShocks) {
    foreach ($mShock in $OperatingMarginShocks) {
        foreach ($wShock in $WaccShocks) {
            $adjRevenue = $baseRevenue * (1 + $rShock)
            $adjOpMargin = $baseOperatingMargin + $mShock
            $adjOpIncome = $adjRevenue * $adjOpMargin
            $adjWacc = $BaseWacc + $wShock
            $rows += [pscustomobject]@{
                RevenueShock = "{0:P0}" -f $rShock
                MarginShock = "{0:P0}" -f $mShock
                Wacc = "{0:P2}" -f $adjWacc
                AdjRevenue = [math]::Round($adjRevenue, 2)
                AdjOperatingIncome = [math]::Round($adjOpIncome, 2)
            }
        }
    }
}

$report = @()
$report += "# Scenario Stress Tester"
$report += ""
$report += ("Base year: FY{0}" -f $latestIncome.FiscalYear)
$report += ("Base revenue: {0} (USD B)" -f $baseRevenue)
$report += ("Base operating margin: {0:P2}" -f $baseOperatingMargin)
$report += ""
$report += "Shocks:"
$report += "- Revenue shocks: " + ((($RevenueShocks | ForEach-Object { "{0:P0}" -f $_ }) | Sort-Object) -join ", ")
$report += "- Operating margin shocks: " + ((($OperatingMarginShocks | ForEach-Object { "{0:P0}" -f $_ }) | Sort-Object) -join ", ")
$report += ("- WACC base: {0:P2}, shocks: {1}" -f $BaseWacc, ((($WaccShocks | ForEach-Object { "{0:P0}" -f $_ }) | Sort-Object) -join ", "))
$report += ""
$report += To-MdTable $rows @("RevenueShock","MarginShock","Wacc","AdjRevenue","AdjOperatingIncome")

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote scenario stress to $OutPath."
