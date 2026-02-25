param(
    [int]$MaxAgeDays = 7,
    [string]$OutDir = "research/sec"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $OutDir)) {
    Write-Host "No SEC cache directory found: $OutDir"
    exit 0
}

function Get-Latest([string]$pattern) {
    return Get-ChildItem -Path $OutDir -Filter $pattern | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
}

$now = Get-Date
$latestSub = Get-Latest "submissions_*.json"
$latestFacts = Get-Latest "companyfacts_*.json"

Write-Host "SEC Cache Check"
Write-Host "--------------"
Write-Host ("Max age (days): {0}" -f $MaxAgeDays)

function Report([string]$label, $file) {
    if (-not $file) {
        Write-Host ("{0}: MISSING" -f $label)
        return
    }
    $ageDays = [math]::Round(($now - $file.LastWriteTime).TotalDays, 2)
    $status = if ($ageDays -le $MaxAgeDays) { "OK" } else { "STALE" }
    Write-Host ("{0}: {1} | {2} days | {3}" -f $label, $file.Name, $ageDays, $status)
}

Report "Submissions" $latestSub
Report "Companyfacts" $latestFacts
