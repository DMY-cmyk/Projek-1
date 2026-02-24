param(
    [string]$SecDir = "research/sec",
    [string]$OutputsDir = "outputs",
    [int]$KeepSecFiles = 3,
    [int]$KeepRunLogs = 5,
    [string]$PlanPath = "outputs/cleanup_plan.md",
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
    $plan = @()
    $plan += "# Cleanup Plan (Dry Run)"
    $plan += ""
    $plan += ("Generated: {0:yyyy-MM-dd HH:mm:ss} local time" -f (Get-Date))
    $plan += ""
    $plan += "## SEC JSON to remove"
    if ($removeSec.Count -gt 0) {
        foreach ($f in $removeSec) { $plan += "- " + $f.FullName }
    } else {
        $plan += "- None"
    }
    $plan += ""
    $plan += "## Run logs to remove"
    if ($removeLogs.Count -gt 0) {
        foreach ($f in $removeLogs) { $plan += "- " + $f.FullName }
    } else {
        $plan += "- None"
    }

    $outDir = Split-Path $PlanPath -Parent
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Force $outDir | Out-Null
    }
    $plan -join "`n" | Out-File -FilePath $PlanPath -Encoding utf8
    Write-Host ("Dry run only. Plan written to {0}. Re-run with -Execute to delete." -f $PlanPath)
}
