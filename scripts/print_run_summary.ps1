param(
    [string]$SummaryPath = "outputs/run_summary.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $SummaryPath)) {
    Write-Host "No run summary found: $SummaryPath"
    exit 0
}

$lines = Get-Content -Path $SummaryPath
Write-Host "Run Summary"
Write-Host "-----------"
$lines | Where-Object { $_ -notmatch "^#" } | ForEach-Object { Write-Host $_ }
