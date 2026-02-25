param(
    [string]$Symbol = "AAPL",
    [string]$OutPath = "research/market_price_source.txt"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-SourceLog([string]$provider, [double]$price, [string]$sourceTimestamp, [string]$note) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $lines = @(
        "# Market Price Source",
        "",
        "* LoggedAt: $now",
        "* Symbol: $Symbol",
        "* Provider: $provider",
        "* Price: $price",
        "* SourceTimestamp: $sourceTimestamp",
        "* Note: $note"
    )
    $outDir = Split-Path -Parent $OutPath
    if ($outDir -and -not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Force $outDir | Out-Null
    }
    $lines | Out-File -FilePath $OutPath -Encoding utf8
}

function Try-Stooq([string]$ticker) {
    $url = "https://stooq.com/q/l/?s=$($ticker.ToLower()).us&i=5"
    $csv = Invoke-WebRequest -UseBasicParsing -Uri $url | Select-Object -ExpandProperty Content
    $parts = $csv.Trim().Split(",")
    if ($parts.Length -lt 7) { return $null }
    $price = [double]$parts[6]
    if ($price -le 0) { return $null }
    $srcTs = "{0} {1}" -f $parts[1], $parts[2]
    return [pscustomobject]@{
        Provider = "Stooq"
        Price = $price
        SourceTimestamp = $srcTs
        Note = "Stooq delayed feed"
    }
}

function Try-YahooChart([string]$ticker) {
    $url = "https://query1.finance.yahoo.com/v8/finance/chart/$ticker?range=1d&interval=1d"
    $r = Invoke-RestMethod -Uri $url
    if (-not $r.chart.result) { return $null }

    $result = $r.chart.result[0]
    $closeArr = $result.indicators.quote[0].close
    if (-not $closeArr -or $closeArr.Count -eq 0) { return $null }

    $latest = $closeArr[$closeArr.Count - 1]
    if ($null -eq $latest) { return $null }
    $price = [double]$latest
    if ($price -le 0) { return $null }

    $ts = $null
    if ($result.timestamp -and $result.timestamp.Count -gt 0) {
        $epoch = [int64]$result.timestamp[$result.timestamp.Count - 1]
        $ts = [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToString("yyyy-MM-dd HH:mm:ss zzz")
    } else {
        $ts = "unknown"
    }

    return [pscustomobject]@{
        Provider = "YahooChart"
        Price = $price
        SourceTimestamp = $ts
        Note = "Yahoo chart endpoint daily close"
    }
}

function Try-LocalValuationCache {
    $path = "data/valuation_snapshot.csv"
    if (-not (Test-Path $path)) { return $null }
    $row = Import-Csv $path | Select-Object -First 1
    if (-not $row -or -not $row.Price) { return $null }
    $price = [double]$row.Price
    if ($price -le 0) { return $null }
    $srcTs = if ($row.AsOfDate) { "$($row.AsOfDate) 00:00:00 local" } else { "unknown" }
    return [pscustomobject]@{
        Provider = "LocalValuationCache"
        Price = $price
        SourceTimestamp = $srcTs
        Note = "Fallback from data/valuation_snapshot.csv"
    }
}

$candidates = @(
    { param($s) Try-Stooq $s },
    { param($s) Try-YahooChart $s },
    { param($s) Try-LocalValuationCache }
)

$resolved = $null
foreach ($provider in $candidates) {
    try {
        $candidate = & $provider $Symbol
        if ($candidate) {
            $resolved = $candidate
            break
        }
    } catch {
        continue
    }
}

if (-not $resolved) {
    Write-Error "Unable to resolve latest price from all providers."
    exit 1
}

Write-SourceLog -provider $resolved.Provider -price $resolved.Price -sourceTimestamp $resolved.SourceTimestamp -note $resolved.Note
Write-Host ("Resolved {0} price: {1} ({2} @ {3})" -f $Symbol, $resolved.Price, $resolved.Provider, $resolved.SourceTimestamp)
Write-Output $resolved.Price
