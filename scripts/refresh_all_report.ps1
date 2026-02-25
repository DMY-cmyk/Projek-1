param(
    [string]$UserAgent,
    [Nullable[double]]$Price = $null,
    [string]$AsOfDate = "2026-02-20",
    [switch]$ForceFresh,
    [switch]$AutoPrice,
    [string]$Symbol = "AAPL"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent \"Name email@domain.com\""
    exit 1
}

if ($AutoPrice -or -not $Price) {
    $resolvedPriceText = & powershell.exe -ExecutionPolicy Bypass -File scripts/get_latest_price.ps1 -Symbol $Symbol
    $Price = [double]$resolvedPriceText
    Write-Host ("Resolved market price for {0}: {1}" -f $Symbol, $Price)
}

& powershell.exe -ExecutionPolicy Bypass -File scripts/validate_inputs.ps1 -AsOfDate $AsOfDate -Price $Price -UserAgent $UserAgent

Write-Host "Running safe refresh..."
$forceFreshArg = @()
if ($ForceFresh) { $forceFreshArg = @("-ForceFresh") }
& powershell.exe -ExecutionPolicy Bypass -File scripts/refresh_all_safe.ps1 -UserAgent $UserAgent -Price $Price -AsOfDate $AsOfDate @forceFreshArg

$summaryPath = "outputs/run_summary.md"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$fetchStatus = if (Test-Path "outputs/fetch_status.md") { (Get-Content "outputs/fetch_status.md" | Select-String -Pattern "^\* Fresh data used:").Line } else { "" }
$latestFacts = Get-ChildItem -Path research/sec -Filter "companyfacts_*.json" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
$latestFactsName = if ($latestFacts) { $latestFacts.Name } else { "" }

$lines = @(
    "# Refresh Run Summary",
    "",
    ("* Timestamp: {0}" -f $ts),
    ("* AsOfDate: {0}" -f $AsOfDate),
    ("* Price: {0}" -f $Price),
    ("* UserAgent: {0}" -f $UserAgent),
    ("* ForceFresh: {0}" -f ($ForceFresh.ToString().ToLower())),
    ("* Latest companyfacts: {0}" -f $latestFactsName),
    ("* {0}" -f $fetchStatus),
    "",
    "## Outputs",
    "- outputs/report.md",
    "- outputs/run_log.md",
    "- outputs/fetch_status.md",
    "- outputs/fetch_errors.md",
    "- outputs/summary.json",
    "- outputs/versions.md"
)

$lines | Out-File -FilePath $summaryPath -Encoding utf8
Write-Host "Wrote $summaryPath."

Write-Host "Appending run history..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/append_run_history.ps1 -AsOfDate $AsOfDate -Price $Price -UserAgent $UserAgent

Write-Host "Capturing tool versions..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/print_versions.ps1
