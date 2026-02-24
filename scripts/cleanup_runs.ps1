param(
    [string]$SecDir = "research/sec",
    [string]$OutputsDir = "outputs",
    [int]$KeepSecFiles = 3,
    [int]$KeepRunLogs = 5,
    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FilesSorted([string]$path, [string]$pattern) {
    if (-not (Test-Path $path)) { return @() }
    return Get-ChildItem -Path $path -Filter $pattern | Sort-Object -Property LastWriteTime -Descending
}

function Plan-Remove($files, [int]$keep) {
    $list = @($files)
    if (-not $list -or $list.Count -le $keep) { return @() }
    return $list | Select-Object -Skip $keep
}

$secFiles = @()
$secFiles += Get-FilesSorted $SecDir "companyfacts_*.json"
$secFiles += Get-FilesSorted $SecDir "submissions_*.json"

$runLogs = Get-FilesSorted $OutputsDir "run_log*.md"

$removeSec = @((Plan-Remove $secFiles $KeepSecFiles))
$removeLogs = @((Plan-Remove $runLogs $KeepRunLogs))

Write-Host "Cleanup plan:"
Write-Host ("- SEC JSON to remove: {0}" -f $removeSec.Count)
Write-Host ("- Run logs to remove: {0}" -f $removeLogs.Count)

foreach ($f in $removeSec) { Write-Host ("SEC: {0}" -f $f.FullName) }
foreach ($f in $removeLogs) { Write-Host ("LOG: {0}" -f $f.FullName) }

if ($Execute) {
    foreach ($f in $removeSec) { Remove-Item -Force $f.FullName }
    foreach ($f in $removeLogs) { Remove-Item -Force $f.FullName }
    Write-Host "Cleanup complete."
} else {
    Write-Host "Dry run only. Re-run with -Execute to delete."
}
