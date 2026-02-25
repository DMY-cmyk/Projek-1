param(
    [string]$DataDir = "data",
    [int]$MaxAgeDays = 14
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$msg) {
    Write-Error $msg
    exit 1
}

$multiplesPath = Join-Path $DataDir "peer_multiples.csv"
$fundamentalsPath = Join-Path $DataDir "peer_fundamentals.csv"

if (-not (Test-Path $multiplesPath)) { Fail "Missing file: $multiplesPath" }
if (-not (Test-Path $fundamentalsPath)) { Fail "Missing file: $fundamentalsPath" }

$multiples = Import-Csv $multiplesPath
$fundamentals = Import-Csv $fundamentalsPath
if ($multiples.Count -lt 1) { Fail "peer_multiples.csv has no rows." }
if ($fundamentals.Count -lt 1) { Fail "peer_fundamentals.csv has no rows." }

$requiredMultiplesCols = @("Ticker", "Company", "PE", "EV_EBITDA", "P_FCF", "AsOfDate", "Source")
$requiredFundCols = @("Ticker", "Company", "FiscalYear", "Revenue", "RevenueYoY", "GrossMargin", "OperatingMargin", "NetMargin", "Source")

foreach ($col in $requiredMultiplesCols) {
    if (-not ($multiples[0].PSObject.Properties.Name -contains $col)) {
        Fail "peer_multiples.csv missing required column: $col"
    }
}
foreach ($col in $requiredFundCols) {
    if (-not ($fundamentals[0].PSObject.Properties.Name -contains $col)) {
        Fail "peer_fundamentals.csv missing required column: $col"
    }
}

$mInfo = Get-Item $multiplesPath
$fInfo = Get-Item $fundamentalsPath
$cutoff = (Get-Date).AddDays(-$MaxAgeDays)
if ($mInfo.LastWriteTime -lt $cutoff) {
    Fail "peer_multiples.csv is stale (> $MaxAgeDays days). LastWriteTime: $($mInfo.LastWriteTime)"
}
if ($fInfo.LastWriteTime -lt $cutoff) {
    Fail "peer_fundamentals.csv is stale (> $MaxAgeDays days). LastWriteTime: $($fInfo.LastWriteTime)"
}

Write-Host "Peer data validation OK."
Write-Host ("- peer_multiples.csv rows: {0}, updated: {1}" -f $multiples.Count, $mInfo.LastWriteTime)
Write-Host ("- peer_fundamentals.csv rows: {0}, updated: {1}" -f $fundamentals.Count, $fInfo.LastWriteTime)
