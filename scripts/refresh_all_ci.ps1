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

$forceFreshArg = @()
if ($ForceFresh) { $forceFreshArg = @("-ForceFresh") }

Write-Host "Running safe refresh (CI mode)..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/refresh_all_safe.ps1 -UserAgent $UserAgent -Price $Price -AsOfDate $AsOfDate @forceFreshArg

Write-Host "Verifying outputs..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/verify_outputs.ps1
