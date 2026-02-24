param(
    [string]$OutPath = "outputs/benchmark_snapshot.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Load-Csv([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    return Import-Csv $path
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

$multiples = Load-Csv "data/peer_multiples.csv"
$fundamentals = Load-Csv "data/peer_fundamentals.csv"

$report = @()
$report += "# Benchmark Snapshot"
$report += ""
$report += ("Generated: {0:yyyy-MM-dd HH:mm:ss} local time" -f (Get-Date))
$report += ""

if ($multiples) {
    $report += "## Peer Multiples"
    $report += To-MdTable $multiples @("Company","Ticker","AsOfDate","PE","EV_EBITDA","P_FCF")
    $report += ""
} else {
    $report += "## Peer Multiples"
    $report += "Missing: data/peer_multiples.csv"
    $report += ""
}

if ($fundamentals) {
    $report += "## Peer Fundamentals"
    $report += To-MdTable $fundamentals @("Company","Ticker","FiscalYear","RevenueYoY","GrossMargin","OperatingMargin","NetMargin","Currency")
    $report += ""
} else {
    $report += "## Peer Fundamentals"
    $report += "Missing: data/peer_fundamentals.csv"
    $report += ""
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote benchmark snapshot to $OutPath."
