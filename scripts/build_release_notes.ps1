param(
    [string]$OutPath = "outputs/release_notes.md",
    [int]$CommitCount = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-GitLog([int]$count) {
    $log = git log --oneline -n $count
    return $log -split "`n"
}

function File-Info([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    $info = Get-Item $path
    return [pscustomobject]@{
        Path = $path
        LastWrite = $info.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
}

$recentCommits = Read-GitLog $CommitCount
$keyOutputs = @(
    "outputs/report.md",
    "outputs/dashboard.md",
    "outputs/run_log.md",
    "outputs/summary.json",
    "outputs/manifest.json"
)

$report = @()
$report += "# Release Notes"
$report += ""
$report += ("Generated: {0:yyyy-MM-dd HH:mm:ss} local time" -f (Get-Date))
$report += ""
$report += "## Recent Commits"
foreach ($line in $recentCommits) {
    if ($line.Trim().Length -gt 0) {
        $report += "- " + $line.Trim()
    }
}
$report += ""
$report += "## Output Timestamps"
foreach ($p in $keyOutputs) {
    $info = File-Info $p
    if ($info) {
        $report += ("- {0}: {1}" -f $info.Path, $info.LastWrite)
    } else {
        $report += ("- {0}: MISSING" -f $p)
    }
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote release notes to $OutPath."
