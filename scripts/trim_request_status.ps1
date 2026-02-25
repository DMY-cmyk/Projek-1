param(
    [int]$MaxAgeDays = 30,
    [string]$LogPath = "research/sec/request_status.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $LogPath)) {
    Write-Host "No request status log found: $LogPath"
    exit 0
}

$cutoff = (Get-Date).AddDays(-$MaxAgeDays)
$rows = Import-Csv -Path $LogPath
if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "Request status log is empty."
    exit 0
}

$kept = $rows | Where-Object { [datetime]$_.timestamp -ge $cutoff }
$kept | Export-Csv -Path $LogPath -NoTypeInformation
Write-Host ("Trimmed request status log to last {0} days." -f $MaxAgeDays)
