param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/data_dictionary.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Load-Csv([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    return Import-Csv $path
}

function Describe-Columns([string]$filePath, [string]$note) {
    $rows = Load-Csv $filePath
    if (-not $rows) { return @() }
    $columns = $rows[0].PSObject.Properties.Name
    $out = @()
    foreach ($c in $columns) {
        $out += [pscustomobject]@{
            File = (Split-Path $filePath -Leaf)
            Column = $c
            Description = $note
        }
    }
    return $out
}

$entries = @()
$entries += Describe-Columns (Join-Path $DataDir "financials_income.csv") "Income statement metrics in USD billions."
$entries += Describe-Columns (Join-Path $DataDir "financials_balance.csv") "Balance sheet metrics in USD billions."
$entries += Describe-Columns (Join-Path $DataDir "financials_cashflow.csv") "Cash flow metrics in USD billions."
$entries += Describe-Columns (Join-Path $DataDir "metrics_profitability.csv") "Profitability ratios (decimal form)."
$entries += Describe-Columns (Join-Path $DataDir "metrics_growth.csv") "Growth metrics (decimal form)."
$entries += Describe-Columns (Join-Path $DataDir "metrics_balance.csv") "Balance sheet ratios and net cash (USD billions)."
$entries += Describe-Columns (Join-Path $DataDir "metrics_cashflow.csv") "Cash flow ratios and EBITDA (USD billions or decimals)."
$entries += Describe-Columns (Join-Path $DataDir "valuation_snapshot.csv") "Valuation snapshot and yields."
$entries += Describe-Columns (Join-Path $DataDir "shares_diluted.csv") "Diluted share counts."
$entries += Describe-Columns (Join-Path $DataDir "peer_multiples.csv") "Peer valuation multiples (latest close)."
$entries += Describe-Columns (Join-Path $DataDir "peer_fundamentals.csv") "Peer fundamentals (latest fiscal year)."

$entries = $entries | Sort-Object File, Column

$report = @()
$report += "# Data Dictionary"
$report += ""
$report += "|File|Column|Description|"
$report += "|---|---|---|"
foreach ($e in $entries) {
    $report += ("|{0}|{1}|{2}|" -f $e.File, $e.Column, $e.Description)
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote data dictionary to $OutPath."
