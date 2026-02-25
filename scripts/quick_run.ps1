param(
    [string]$UserAgent,
    [switch]$ForceFresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent \"Name email@domain.com\""
    exit 1
}

Write-Host "Preflight connectivity..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/check_sec_connectivity.ps1 -UserAgent $UserAgent

Write-Host "Fetching SEC data..."
$forceFreshArg = @()
if ($ForceFresh) { $forceFreshArg = @("-ForceFresh") }
& powershell.exe -ExecutionPolicy Bypass -File scripts/fetch_sec_retry.ps1 -UserAgent $UserAgent -FailFast @forceFreshArg

Write-Host "Validating SEC cache..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/validate_sec_files.ps1

Write-Host "Capturing tool versions..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/print_versions.ps1

Write-Host "Quick run completed."
