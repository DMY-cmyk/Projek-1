param(
    [string]$OutDir = "outputs",
    [string]$BundleName = "run_bundle.zip"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $OutDir)) {
    Write-Host "No outputs directory found."
    exit 0
}

$paths = @(
    "outputs/run_summary.md",
    "outputs/run_log.md",
    "outputs/report.md",
    "outputs/summary.json"
)

$existing = $paths | Where-Object { Test-Path $_ }
if (-not $existing -or $existing.Count -eq 0) {
    Write-Host "No run outputs found to bundle."
    exit 0
}

$bundlePath = Join-Path $OutDir $BundleName
if (Test-Path $bundlePath) {
    Remove-Item -Path $bundlePath -Force
}

Compress-Archive -Path $existing -DestinationPath $bundlePath
Write-Host ("Wrote {0}" -f $bundlePath)
