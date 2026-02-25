param(
    [string]$OutDir = "outputs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not [System.IO.Path]::IsPathRooted($OutDir)) {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $OutDir = Join-Path $repoRoot $OutDir
}

if (-not (Test-Path $OutDir)) {
    Write-Host "No outputs directory found."
    exit 0
}

$required = @(
    "report.md",
    "run_log.md",
    "summary.json",
    "manifest.json",
    "freshness_report.md",
    "versions.md"
)

Write-Host "Outputs Verification"
Write-Host "--------------------"
foreach ($name in $required) {
    $path = Join-Path $OutDir $name
    if (Test-Path $path) {
        Write-Host ("- {0}: OK" -f $name)
    } else {
        Write-Host ("- {0}: MISSING" -f $name)
    }
}

$missing = @($required | Where-Object { -not (Test-Path (Join-Path $OutDir $_)) })
if ($missing.Count -gt 0) {
    Write-Error ("Missing required outputs: {0}" -f ($missing -join ", "))
    exit 1
}
