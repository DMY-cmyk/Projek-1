param(
    [string]$DataDir = "data",
    [string]$OutDir = "outputs/charts"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms.DataVisualization

function New-LineChart {
    param(
        [string]$Title,
        [string]$YAxisTitle,
        [hashtable]$SeriesMap,
        [string]$OutPath
    )

    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Width = 1200
    $chart.Height = 700

    $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $chartArea.AxisX.Title = "Fiscal Year"
    $chartArea.AxisX.Interval = 1
    $chartArea.AxisY.Title = $YAxisTitle
    $chart.ChartAreas.Add($chartArea) | Out-Null

    $legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
    $legend.Docking = "Bottom"
    $chart.Legends.Add($legend) | Out-Null

    $chart.Titles.Add($Title) | Out-Null

    foreach ($name in $SeriesMap.Keys) {
        $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
        $series.Name = $name
        $series.ChartType = "Line"
        $series.BorderWidth = 3
        $series.MarkerStyle = "Circle"
        $series.MarkerSize = 6
        $series.Points.DataBindXY($SeriesMap[$name].X, $SeriesMap[$name].Y)
        $chart.Series.Add($series) | Out-Null
    }

    $dir = Split-Path -Parent $OutPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $chart.SaveImage($OutPath, "Png")
    $chart.Dispose()
}

function Read-CsvSorted {
    param([string]$Path)
    return Import-Csv -Path $Path | Sort-Object -Property FiscalYear
}

$income = Read-CsvSorted -Path (Join-Path $DataDir "financials_income.csv")
$profit = Read-CsvSorted -Path (Join-Path $DataDir "metrics_profitability.csv")
$balance = Read-CsvSorted -Path (Join-Path $DataDir "metrics_balance.csv")
$cashflow = Read-CsvSorted -Path (Join-Path $DataDir "financials_cashflow.csv")
$metricsCashflow = Read-CsvSorted -Path (Join-Path $DataDir "metrics_cashflow.csv")

$years = $income | ForEach-Object { [int]$_.FiscalYear }

New-LineChart `
    -Title "Revenue and Operating Income (USD Billions)" `
    -YAxisTitle "USD Billions" `
    -SeriesMap @{
        "Revenue" = @{
            X = $years
            Y = $income | ForEach-Object { [double]$_.Revenue }
        }
        "Operating Income" = @{
            X = $years
            Y = $income | ForEach-Object { [double]$_.OperatingIncome }
        }
    } `
    -OutPath (Join-Path $OutDir "revenue_operating_income.png")

New-LineChart `
    -Title "Margins (Percent)" `
    -YAxisTitle "Percent" `
    -SeriesMap @{
        "Gross Margin" = @{
            X = $profit | ForEach-Object { [int]$_.FiscalYear }
            Y = $profit | ForEach-Object { [double]$_.GrossMargin * 100 }
        }
        "Operating Margin" = @{
            X = $profit | ForEach-Object { [int]$_.FiscalYear }
            Y = $profit | ForEach-Object { [double]$_.OperatingMargin * 100 }
        }
        "Net Margin" = @{
            X = $profit | ForEach-Object { [int]$_.FiscalYear }
            Y = $profit | ForEach-Object { [double]$_.NetMargin * 100 }
        }
    } `
    -OutPath (Join-Path $OutDir "margins.png")

$buybacksByYear = @{}
$dividendsByYear = @{}
foreach ($row in $cashflow) {
    $buybacksByYear[[int]$row.FiscalYear] = [double]$row.Buyback
    $dividendsByYear[[int]$row.FiscalYear] = [double]$row.Dividends
}

New-LineChart `
    -Title "Free Cash Flow and Capital Returns (USD Billions)" `
    -YAxisTitle "USD Billions" `
    -SeriesMap @{
        "Free Cash Flow" = @{
            X = $metricsCashflow | ForEach-Object { [int]$_.FiscalYear }
            Y = $metricsCashflow | ForEach-Object { [double]$_.FCF }
        }
        "Buybacks" = @{
            X = $metricsCashflow | ForEach-Object { [int]$_.FiscalYear }
            Y = $metricsCashflow | ForEach-Object { $buybacksByYear[[int]$_.FiscalYear] }
        }
        "Dividends" = @{
            X = $metricsCashflow | ForEach-Object { [int]$_.FiscalYear }
            Y = $metricsCashflow | ForEach-Object { $dividendsByYear[[int]$_.FiscalYear] }
        }
    } `
    -OutPath (Join-Path $OutDir "fcf_capital_returns.png")

New-LineChart `
    -Title "Net Cash (USD Billions)" `
    -YAxisTitle "USD Billions" `
    -SeriesMap @{
        "Net Cash" = @{
            X = $balance | ForEach-Object { [int]$_.FiscalYear }
            Y = $balance | ForEach-Object { [double]$_.NetCash }
        }
    } `
    -OutPath (Join-Path $OutDir "net_cash.png")
