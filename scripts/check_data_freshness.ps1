param(
    [string]$SecDir = "research/sec",
    [string]$ValuationPath = "data/valuation_snapshot.csv",
    [int]$WarnDays = 60,
    [string]$OutPath = "outputs/freshness_report.md"
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

function Read-Csv([string]$path) {
    if (-not (Test-Path $path)) { return @() }
    return Import-Csv $path
}

$now = Get-Date
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

$keyForms = @("10-K","10-Q","8-K")
$latestKey = $rows | Where-Object { $_.Form -in $keyForms } |
    Sort-Object -Property FilingDate -Descending |
    Select-Object -First 1

$valuation = Read-Csv $ValuationPath | Sort-Object -Property AsOfDate -Descending | Select-Object -First 1

$filingAgeDays = $null
if ($latestKey) {
    $filingAgeDays = (New-TimeSpan -Start ([datetime]$latestKey.FilingDate) -End $now).Days
}

$valuationAgeDays = $null
if ($valuation) {
    $valuationAgeDays = (New-TimeSpan -Start ([datetime]$valuation.AsOfDate) -End $now).Days
}

$issues = @()
if ($null -ne $filingAgeDays -and $filingAgeDays -gt $WarnDays) {
    $issues += "Latest SEC filing is $filingAgeDays days old (threshold $WarnDays)."
}
if ($null -ne $valuationAgeDays -and $valuationAgeDays -gt $WarnDays) {
    $issues += "Valuation snapshot is $valuationAgeDays days old (threshold $WarnDays)."
}

$report = @()
$report += "# Data Freshness Report"
$report += ""
$report += ("Generated: {0:yyyy-MM-dd HH:mm:ss} local time" -f $now)
$report += ("Warning threshold: {0} days" -f $WarnDays)
$report += ""
$report += "## Latest SEC Filing"
if ($latestKey) {
    $report += To-MdTable @($latestKey) @("Form","FilingDate","ReportDate","Accession")
    $report += ("Age (days): {0}" -f $filingAgeDays)
} else {
    $report += "No filings found."
}
$report += ""
$report += "## Latest Valuation Snapshot"
if ($valuation) {
    $report += To-MdTable @($valuation) @("AsOfDate","Price","MarketCapBillions","EnterpriseValueBillions","PE","EV_EBITDA","EV_FCF","P_FCF")
    $report += ("Age (days): {0}" -f $valuationAgeDays)
} else {
    $report += "No valuation snapshot found."
}
$report += ""
$report += "## Alerts"
if ($issues.Count -gt 0) {
    foreach ($issue in $issues) {
        $report += "- " + $issue
    }
} else {
    $report += "- No freshness warnings."
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote freshness report to $OutPath."
