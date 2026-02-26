param(
    [int]$Count = 10,
    [string]$HistoryPath = "outputs/run_history.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $HistoryPath)) {
    Write-Host "No run history found at $HistoryPath."
    exit 0
}

$rows = Import-Csv $HistoryPath
if ($rows.Count -eq 0) {
    Write-Host "Run history is empty."
    exit 0
}

$recent = $rows | Select-Object -Last $Count

Write-Host "Last $Count scheduler outcomes from $HistoryPath`:"
Write-Host ""
$recent | Format-Table -Property Timestamp, AsOfDate, Status, ExitCode -AutoSize

$total = $rows.Count
$successCount = ($rows | Where-Object {
    $_.Status -eq "Success" -or (-not $_.PSObject.Properties.Name.Contains("Status"))
}).Count
$failCount = $total - $successCount

Write-Host "Summary: $total total runs, $successCount succeeded, $failCount failed."
