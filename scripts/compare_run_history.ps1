param(
    [string]$HistoryPath = "outputs/run_history.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $HistoryPath)) {
    Write-Host "No run history found: $HistoryPath"
    exit 0
}

$rows = Import-Csv -Path $HistoryPath
if (-not $rows -or $rows.Count -lt 2) {
    Write-Host "Not enough history to compare."
    exit 0
}

$last = $rows[-1]
$prev = $rows[-2]

Write-Host "Run History Delta (last vs previous)"
Write-Host "------------------------------------"
Write-Host ("Timestamp: {0} -> {1}" -f $prev.Timestamp, $last.Timestamp)
Write-Host ("AsOfDate: {0} -> {1}" -f $prev.AsOfDate, $last.AsOfDate)
Write-Host ("Price: {0} -> {1}" -f $prev.Price, $last.Price)
Write-Host ("FreshDataUsed: {0} -> {1}" -f $prev.FreshDataUsed, $last.FreshDataUsed)
