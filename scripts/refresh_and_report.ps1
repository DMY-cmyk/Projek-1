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

Write-Host "Running refresh + report..."
$forceFreshArg = @()
if ($ForceFresh) { $forceFreshArg = @("-ForceFresh") }
& powershell.exe -ExecutionPolicy Bypass -File scripts/refresh_all_report.ps1 -UserAgent $UserAgent -Price $Price -AsOfDate $AsOfDate @forceFreshArg

Write-Host "Outputs summary..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/summarize_outputs.ps1

Write-Host "Fetch summary..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/print_fetch_summary.ps1

Write-Host "Exporting run bundle..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/export_run_bundle.ps1
