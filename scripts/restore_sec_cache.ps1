param(
    [string]$OutDir = "research/sec"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$backup = Get-ChildItem -Path $OutDir -Directory -Filter "cache_backup_*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
if (-not $backup) {
    Write-Host "No cache backup found under $OutDir."
    exit 0
}

Get-ChildItem -Path $backup.FullName -Filter "submissions_*.json" | Move-Item -Destination $OutDir
Get-ChildItem -Path $backup.FullName -Filter "companyfacts_*.json" | Move-Item -Destination $OutDir

Write-Host ("Restored cached JSONs from {0}" -f $backup.Name)
