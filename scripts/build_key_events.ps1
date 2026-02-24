param(
    [string]$SecDir = "research/sec",
    [string]$OutPath = "outputs/key_events.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-LatestSubmissionsPath([string]$dir) {
    $files = Get-ChildItem -Path $dir -Filter "submissions_*.json" -ErrorAction SilentlyContinue
    if (-not $files) { return $null }
    return ($files | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1).FullName
}

function To-MdTable($rows, [string[]]$columns) {
    $header = "|" + ($columns -join "|") + "|"
    $sep = "|" + (($columns | ForEach-Object { "---" }) -join "|") + "|"
    $lines = @($header, $sep)
    foreach ($r in $rows) {
        $vals = @()
        foreach ($c in $columns) {
            $v = $r.$c
            if ($null -eq $v -or $v -eq "") { $v = "" }
            $vals += $v
        }
        $lines += "|" + ($vals -join "|") + "|"
    }
    return $lines -join "`n"
}

$submissionsPath = Get-LatestSubmissionsPath $SecDir
if (-not $submissionsPath) {
    Write-Error "No submissions JSON found in $SecDir"
    exit 1
}

$submissions = Get-Content -Raw $submissionsPath | ConvertFrom-Json
$recent = $submissions.filings.recent

$rows = @()
for ($i = 0; $i -lt $recent.form.Count; $i++) {
    $rows += [pscustomobject]@{
        Form = $recent.form[$i]
        FilingDate = $recent.filingDate[$i]
        ReportDate = $recent.reportDate[$i]
        Accession = $recent.accessionNumber[$i]
    }
}

$rows = $rows | Sort-Object -Property FilingDate -Descending

$filtered = $rows | Where-Object { $_.Form -in @("10-K","10-Q","8-K") } | Select-Object -First 20

$report = @()
$report += "# Key Events Log"
$report += ""
$report += "Source: $submissionsPath"
$report += ""
$report += "Latest filings (10-K, 10-Q, 8-K):"
$report += To-MdTable $filtered @("Form","FilingDate","ReportDate","Accession")

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote key events to $OutPath."
