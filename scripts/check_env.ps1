param(
    [switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Environment Check"
Write-Host "-----------------"

$policy = Get-ExecutionPolicy -List
Write-Host "Execution policy:"
$policy.GetEnumerator() | ForEach-Object { Write-Host ("- {0}: {1}" -f $_.Key, $_.Value) }

function Check-Command([string]$name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("{0}: OK ({1})" -f $name, $cmd.Source)
        return $true
    }
    Write-Host ("{0}: MISSING" -f $name)
    return $false
}

Check-Command "cargo" | Out-Null
Check-Command "rustc" | Out-Null
Check-Command "powershell" | Out-Null

$required = @(
    "scripts/fetch_sec_sources.ps1",
    "scripts/fetch_sec_retry.ps1",
    "scripts/extract_companyfacts.ps1",
    "scripts/compute_metrics.ps1",
    "scripts/validate_financials.ps1",
    "scripts/build_report_pack.ps1"
)

Write-Host ""
Write-Host "Required scripts:"
foreach ($path in $required) {
    if (Test-Path $path) {
        Write-Host ("- {0}: OK" -f $path)
    } else {
        Write-Host ("- {0}: MISSING" -f $path)
    }
}

if ($Verbose) {
    Write-Host ""
    Write-Host "Rust versions:"
    try { & rustc --version } catch { Write-Host "rustc --version failed" }
    try { & cargo --version } catch { Write-Host "cargo --version failed" }
}
