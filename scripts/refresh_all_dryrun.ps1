param(
    [string]$UserAgent,
    [double]$Price = 264.58,
    [string]$AsOfDate = "2026-02-20"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent \"Name email@domain.com\""
    exit 1
}

Write-Host "Dry run: inputs look valid."
Write-Host ("- UserAgent: {0}" -f $UserAgent)
Write-Host ("- Price: {0}" -f $Price)
Write-Host ("- AsOfDate: {0}" -f $AsOfDate)

Write-Host ""
Write-Host "Dry run: planned steps"
Write-Host "1) scripts/fetch_sec_sources.ps1 -UserAgent <redacted>"
Write-Host "2) scripts/extract_companyfacts.ps1 -CompanyFactsPath <latest companyfacts_*.json>"
Write-Host "3) scripts/compute_metrics.ps1"
Write-Host "4) scripts/validate_financials.ps1"
Write-Host "5) scripts/compute_valuation.ps1 -Price $Price -AsOfDate $AsOfDate"
Write-Host "6) scripts/build_report_pack.ps1"
