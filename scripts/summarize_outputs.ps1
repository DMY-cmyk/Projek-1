param(
    [string]$OutDir = "outputs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $OutDir)) {
    Write-Host "No outputs directory found: $OutDir"
    exit 0
}

$files = Get-ChildItem -Path $OutDir -File | Sort-Object -Property LastWriteTime -Descending
if (-not $files -or $files.Count -eq 0) {
    Write-Host "No output files found."
    exit 0
}

Write-Host "Outputs Summary"
Write-Host "---------------"
$files | Select-Object Name, @{Name="SizeKB";Expression={[math]::Round($_.Length / 1KB, 2)}}, LastWriteTime | Format-Table -AutoSize
