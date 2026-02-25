param(
    [switch]$DryRun,
    [switch]$IncludeHistory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$outDir = "outputs"
if (-not (Test-Path $outDir)) {
    Write-Host "No outputs directory found."
    exit 0
}

$targets = @("*.md", "*.json")
$files = foreach ($pattern in $targets) {
    Get-ChildItem -Path $outDir -Filter $pattern -File
}

if (-not $files -or $files.Count -eq 0) {
    Write-Host "No output files to clean."
    exit 0
}

Write-Host "Outputs clean"
Write-Host "-------------"
foreach ($f in $files) {
    if (-not $IncludeHistory -and ($f.Name -eq "run_history.csv" -or $f.Name -eq "run_summary.md")) {
        continue
    }
    if ($DryRun) {
        Write-Host ("DRY RUN: {0}" -f $f.Name)
    } else {
        Remove-Item -Path $f.FullName -Force
        Write-Host ("Deleted: {0}" -f $f.Name)
    }
}
