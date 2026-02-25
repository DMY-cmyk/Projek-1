param(
    [string]$UserAgent,
    [double]$Price = 264.58,
    [string]$AsOfDate = "2026-02-20",
    [switch]$ForceFresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent \"Name email@domain.com\""
    exit 1
}

& powershell.exe -ExecutionPolicy Bypass -File scripts/validate_inputs.ps1 -AsOfDate $AsOfDate -Price $Price -UserAgent $UserAgent

Write-Host "Preflight connectivity..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/check_sec_connectivity.ps1 -UserAgent $UserAgent

Write-Host "Refreshing SEC sources..."
$forceFreshArg = @()
if ($ForceFresh) { $forceFreshArg = @("-ForceFresh") }
& powershell.exe -ExecutionPolicy Bypass -File scripts/fetch_sec_retry.ps1 -UserAgent $UserAgent -FailFast @forceFreshArg

Write-Host "Validating SEC cache..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/validate_sec_files.ps1

Write-Host "Extracting company facts..."
$factsPath = Get-ChildItem -Path research/sec -Filter "companyfacts_*.json" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
if (-not $factsPath) {
    Write-Error "No companyfacts JSON found under research/sec."
    exit 1
}
& powershell.exe -ExecutionPolicy Bypass -File scripts/extract_companyfacts.ps1 -CompanyFactsPath $factsPath.FullName

Write-Host "Computing metrics..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/compute_metrics.ps1

Write-Host "Validating financials..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/validate_financials.ps1

Write-Host "Computing valuation snapshot..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/compute_valuation.ps1 -Price $Price -AsOfDate $AsOfDate

Write-Host "Building report pack..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/build_report_pack.ps1

Write-Host "Done. All outputs refreshed (safe mode)."
