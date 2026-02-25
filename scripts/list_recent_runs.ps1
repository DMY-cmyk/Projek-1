param(
    [int]$Count = 5,
    [string]$HistoryPath = "outputs/run_history.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $HistoryPath)) {
    Write-Host "No run history found: $HistoryPath"
    exit 0
}

$rows = Import-Csv -Path $HistoryPath
if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "Run history is empty."
    exit 0
}

$rows | Select-Object -Last $Count | Format-Table -AutoSize
