param(
    [string]$DataDir = "data",
    [string]$OutPath = "outputs/drift_alerts.md",
    [double]$SigmaThreshold = 2.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Load-Csv([string]$path) {
    if (-not (Test-Path $path)) {
        Write-Error "Missing required file: $path"
        exit 1
    }
    return Import-Csv $path
}

function Mean([double[]]$values) {
    if (-not $values -or $values.Count -eq 0) { return $null }
    return ($values | Measure-Object -Average).Average
}

function StdDev([double[]]$values) {
    if (-not $values -or $values.Count -lt 2) { return $null }
    $avg = Mean $values
    $sum = 0.0
    foreach ($v in $values) {
        $sum += [math]::Pow($v - $avg, 2)
    }
    return [math]::Sqrt($sum / ($values.Count - 1))
}

$metricsProfit = Load-Csv (Join-Path $DataDir "metrics_profitability.csv") | Sort-Object -Property FiscalYear
$metricsCash = Load-Csv (Join-Path $DataDir "metrics_cashflow.csv") | Sort-Object -Property FiscalYear
$metricsBalance = Load-Csv (Join-Path $DataDir "metrics_balance.csv") | Sort-Object -Property FiscalYear

$latestYear = ($metricsProfit | Select-Object -Last 1).FiscalYear

$series = @(
    [pscustomobject]@{Name="Gross Margin"; Values=($metricsProfit | ForEach-Object { [double]$_.GrossMargin }); Latest=([double]($metricsProfit | Select-Object -Last 1).GrossMargin)},
    [pscustomobject]@{Name="Operating Margin"; Values=($metricsProfit | ForEach-Object { [double]$_.OperatingMargin }); Latest=([double]($metricsProfit | Select-Object -Last 1).OperatingMargin)},
    [pscustomobject]@{Name="Net Margin"; Values=($metricsProfit | ForEach-Object { [double]$_.NetMargin }); Latest=([double]($metricsProfit | Select-Object -Last 1).NetMargin)},
    [pscustomobject]@{Name="FCF Conversion"; Values=($metricsCash | ForEach-Object { [double]$_.FCFConversion }); Latest=([double]($metricsCash | Select-Object -Last 1).FCFConversion)},
    [pscustomobject]@{Name="Capex % Revenue"; Values=($metricsCash | ForEach-Object { [double]$_.CapexPctRevenue }); Latest=([double]($metricsCash | Select-Object -Last 1).CapexPctRevenue)},
    [pscustomobject]@{Name="ROIC"; Values=($metricsBalance | ForEach-Object { [double]$_.ROIC }); Latest=([double]($metricsBalance | Select-Object -Last 1).ROIC)},
    [pscustomobject]@{Name="Current Ratio"; Values=($metricsBalance | ForEach-Object { [double]$_.CurrentRatio }); Latest=([double]($metricsBalance | Select-Object -Last 1).CurrentRatio)}
)

$alerts = @()
$rows = @()
foreach ($s in $series) {
    $avg = Mean $s.Values
    $sd = StdDev $s.Values
    if ($null -eq $avg -or $null -eq $sd -or $sd -eq 0) { continue }
    $z = ($s.Latest - $avg) / $sd
    $rows += [pscustomobject]@{
        Metric = $s.Name
        Latest = [math]::Round($s.Latest, 4)
        Mean = [math]::Round($avg, 4)
        StdDev = [math]::Round($sd, 4)
        ZScore = [math]::Round($z, 2)
    }
    if ([math]::Abs($z) -ge $SigmaThreshold) {
        $alerts += [pscustomobject]@{
            Metric = $s.Name
            ZScore = [math]::Round($z, 2)
            Direction = if ($z -gt 0) { "Above" } else { "Below" }
        }
    }
}

$report = @()
$report += "# Metrics Drift Alerts"
$report += ""
$report += ("Latest fiscal year: FY{0}" -f $latestYear)
$report += ("Threshold: |Z| >= {0}" -f $SigmaThreshold)
$report += ""
$report += "## Z-Score Summary"
$report += "|" + "Metric|Latest|Mean|StdDev|ZScore" + "|"
$report += "|---|---|---|---|---|"
foreach ($r in $rows) {
    $report += ("|{0}|{1}|{2}|{3}|{4}|" -f $r.Metric, $r.Latest, $r.Mean, $r.StdDev, $r.ZScore)
}
$report += ""
$report += "## Alerts"
if ($alerts.Count -gt 0) {
    foreach ($a in $alerts) {
        $report += ("- {0}: {1} ({2} {3}σ)" -f $a.Metric, $a.Direction, [math]::Abs($a.ZScore), $SigmaThreshold)
    }
} else {
    $report += "- No drift alerts."
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$report -join "`n" | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote drift alerts to $OutPath."
