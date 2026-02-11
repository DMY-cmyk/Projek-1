param(
    [string]$DataDir = "data",
    [string]$OutPath = "data/validation_report.txt"
)

function Load-Csv([string]$path) {
    if (-not (Test-Path $path)) {
        Write-Error "Missing required file: $path"
        exit 1
    }
    return Import-Csv $path
}

function Count-Nulls($rows, [string]$col) {
    $count = 0
    foreach ($r in $rows) {
        $v = $r.$col
        if ($null -eq $v -or $v -eq "") { $count++ }
    }
    return $count
}

$income = Load-Csv (Join-Path $DataDir "financials_income.csv")
$balance = Load-Csv (Join-Path $DataDir "financials_balance.csv")
$cashflow = Load-Csv (Join-Path $DataDir "financials_cashflow.csv")
$shares = Load-Csv (Join-Path $DataDir "shares_diluted.csv")

$script:lines = @()
$script:lines += "Validation Report - {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$script:lines += ""

function Add-NullSummary([string]$name, $rows) {
    $cols = $rows[0].PSObject.Properties.Name | Where-Object { $_ -ne "FiscalYear" }
    $script:lines += "$($name):"
    foreach ($c in $cols) {
        $n = Count-Nulls $rows $c
        $script:lines += "  $($c): $n missing"
    }
    $script:lines += ""
}

Add-NullSummary "Income Statement" $income
Add-NullSummary "Balance Sheet" $balance
Add-NullSummary "Cash Flow" $cashflow
Add-NullSummary "Shares" $shares

$yearsIncome = $income.FiscalYear
$yearsBalance = $balance.FiscalYear
$yearsCash = $cashflow.FiscalYear
$yearsShares = $shares.FiscalYear

$script:lines += "Year Alignment:"
$script:lines += "  Income vs Balance: {0}" -f (([string]::Join(",", $yearsIncome)) -eq ([string]::Join(",", $yearsBalance)))
$script:lines += "  Income vs Cashflow: {0}" -f (([string]::Join(",", $yearsIncome)) -eq ([string]::Join(",", $yearsCash)))
$script:lines += "  Income vs Shares: {0}" -f (([string]::Join(",", $yearsIncome)) -eq ([string]::Join(",", $yearsShares)))

$script:lines | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote validation report to $OutPath."
