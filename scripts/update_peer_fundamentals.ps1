param(
    [string]$OutPath = "data/peer_fundamentals.csv",
    [string]$UserAgent = "",
    [string]$UserAgentFile = "research/sec_user_agent.txt",
    [string]$SecCacheDir = "research/sec/peers"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Resolve SEC User-Agent from param, file, or env
if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    if (Test-Path $UserAgentFile) {
        $UserAgent = (Get-Content $UserAgentFile -Raw).Trim()
    }
}
if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    if ($env:SEC_USER_AGENT) {
        $UserAgent = $env:SEC_USER_AGENT.Trim()
    }
}

function Get-Page([string]$url) {
    return Invoke-WebRequest -Uri $url -UseBasicParsing
}

function Get-Metric([string]$html, [string]$label) {
    $pattern = [regex]::Escape($label) + '.*?<div[^>]*>([0-9,.]+)</div>'
    $match = [regex]::Match($html, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($match.Success) { return $match.Groups[1].Value -replace ",", "" }
    return $null
}

function Get-PercentMetric([string]$html, [string]$label) {
    $pattern = [regex]::Escape($label) + '.*?<div[^>]*>([0-9.]+)%</div>'
    $match = [regex]::Match($html, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($match.Success) { return [double]$match.Groups[1].Value / 100.0 }
    return $null
}

# --- Apple: read from local financials_income.csv ---
Write-Host "Reading Apple fundamentals from data/financials_income.csv..."
$appleIncome = Import-Csv "data/financials_income.csv"
$appleCurrent = $appleIncome | Select-Object -First 1
$applePrior = $appleIncome | Select-Object -Skip 1 -First 1

$appleRevenue = [double]$appleCurrent.Revenue
$appleRevenuePrior = [double]$applePrior.Revenue
$appleYoY = [math]::Round(($appleRevenue - $appleRevenuePrior) / $appleRevenuePrior, 6)
$appleGrossMargin = [math]::Round([double]$appleCurrent.GrossProfit / $appleRevenue, 6)
$appleOpMargin = [math]::Round([double]$appleCurrent.OperatingIncome / $appleRevenue, 6)
$appleNetMargin = [math]::Round([double]$appleCurrent.NetIncome / $appleRevenue, 6)

$rows = @()
$rows += [pscustomobject]@{
    Company        = "Apple"
    Ticker         = "AAPL"
    FiscalYear     = $appleCurrent.FiscalYear
    Revenue        = $appleRevenue
    RevenuePrior   = $appleRevenuePrior
    RevenueYoY     = $appleYoY
    GrossMargin    = $appleGrossMargin
    OperatingMargin = $appleOpMargin
    NetMargin      = $appleNetMargin
    Currency       = "USD (billions)"
    Source         = "data/financials_income.csv"
}

# --- SEC peers (MSFT, GOOGL): fetch companyfacts and extract ---
$secPeers = @(
    @{ Company = "Microsoft"; Ticker = "MSFT"; Cik = "0000789019"; Currency = "USD (millions)" },
    @{ Company = "Alphabet"; Ticker = "GOOGL"; Cik = "0001652044"; Currency = "USD (millions)" }
)

foreach ($peer in $secPeers) {
    $ticker = $peer.Ticker
    $cik = $peer.Cik
    $peerCacheDir = Join-Path $SecCacheDir $ticker
    $peerDataDir = Join-Path $peerCacheDir "data"

    if (-not (Test-Path $peerCacheDir)) {
        New-Item -ItemType Directory -Force $peerCacheDir | Out-Null
    }

    $fetchOk = $true
    if ($UserAgent -and $UserAgent.Trim().Length -ge 6) {
        Write-Host "Fetching SEC data for $ticker (CIK $cik)..."
        try {
            & powershell.exe -ExecutionPolicy Bypass -File scripts/fetch_sec_sources.ps1 `
                -Cik $cik -UserAgent $UserAgent -OutDir $peerCacheDir
            if ($LASTEXITCODE -ne 0) { $fetchOk = $false }
        } catch {
            Write-Warning "SEC fetch failed for $ticker`: $_"
            $fetchOk = $false
        }
    } else {
        Write-Warning "No SEC User-Agent available; skipping SEC fetch for $ticker."
        $fetchOk = $false
    }

    # Find latest companyfacts JSON
    $factsFile = $null
    if ($fetchOk) {
        $factsFile = Get-ChildItem -Path $peerCacheDir -Filter "companyfacts_*.json" |
            Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
    }
    if (-not $factsFile) {
        $factsFile = Get-ChildItem -Path $peerCacheDir -Filter "companyfacts_*.json" -ErrorAction SilentlyContinue |
            Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
    }

    if ($factsFile) {
        Write-Host "Extracting $ticker financials from $($factsFile.Name)..."
        & powershell.exe -ExecutionPolicy Bypass -File scripts/extract_companyfacts.ps1 `
            -CompanyFactsPath $factsFile.FullName -OutDir $peerDataDir -Years 2 -UsdScale 1000000

        $incPath = Join-Path $peerDataDir "financials_income.csv"
        if (Test-Path $incPath) {
            $inc = Import-Csv $incPath
            $cur = $inc | Select-Object -First 1
            $prior = $inc | Select-Object -Skip 1 -First 1

            $rev = [double]$cur.Revenue
            $revPrior = if ($prior -and $prior.Revenue) { [double]$prior.Revenue } else { $null }
            $yoy = if ($revPrior -and $revPrior -ne 0) {
                [math]::Round(($rev - $revPrior) / $revPrior, 6)
            } else { "" }
            $grossMargin = if ($cur.GrossProfit -and $rev -ne 0) {
                [math]::Round([double]$cur.GrossProfit / $rev, 6)
            } else { "" }
            $opMargin = if ($cur.OperatingIncome -and $rev -ne 0) {
                [math]::Round([double]$cur.OperatingIncome / $rev, 6)
            } else { "" }
            $netMargin = if ($cur.NetIncome -and $rev -ne 0) {
                [math]::Round([double]$cur.NetIncome / $rev, 6)
            } else { "" }

            $rows += [pscustomobject]@{
                Company        = $peer.Company
                Ticker         = $ticker
                FiscalYear     = $cur.FiscalYear
                Revenue        = $rev
                RevenuePrior   = $revPrior
                RevenueYoY     = $yoy
                GrossMargin    = $grossMargin
                OperatingMargin = $opMargin
                NetMargin      = $netMargin
                Currency       = $peer.Currency
                Source         = "SEC companyfacts (CIK $cik)"
            }
            Write-Host "$ticker fundamentals extracted."
            continue
        }
    }

    # Fallback: retain existing row from current CSV
    Write-Warning "Could not extract $ticker fundamentals; retaining existing row."
    if (Test-Path $OutPath) {
        $existing = Import-Csv $OutPath | Where-Object { $_.Ticker -eq $ticker }
        if ($existing) {
            $rows += $existing | Select-Object -First 1
        }
    }
}

# --- Samsung: scrape stockanalysis.com ---
Write-Host "Fetching Samsung fundamentals from stockanalysis.com..."
$samsungOk = $false
try {
    $saUrl = "https://stockanalysis.com/quote/fra/SSUN/financials/"
    $resp = Get-Page $saUrl
    $html = $resp.Content

    $revRaw = Get-Metric $html "Revenue"
    $grossMarginRaw = Get-PercentMetric $html "Gross Margin"
    $opMarginRaw = Get-PercentMetric $html "Operating Margin"
    $netMarginRaw = Get-PercentMetric $html "Profit Margin"

    if ($revRaw) {
        $samsungOk = $true
        Write-Host "Samsung data retrieved from stockanalysis.com."
    }
} catch {
    Write-Warning "Samsung scrape failed: $_"
}

if ($samsungOk) {
    # stockanalysis.com shows Samsung in KRW billions; current CSV uses KRW millions
    # Retain existing row format — best-effort update with margins only if available
    if (Test-Path $OutPath) {
        $existing = Import-Csv $OutPath | Where-Object { $_.Ticker -eq "005930.KS" }
        if ($existing) {
            $samRow = $existing | Select-Object -First 1
            if ($grossMarginRaw) { $samRow.GrossMargin = [math]::Round($grossMarginRaw, 6) }
            if ($opMarginRaw) { $samRow.OperatingMargin = [math]::Round($opMarginRaw, 6) }
            if ($netMarginRaw) { $samRow.NetMargin = [math]::Round($netMarginRaw, 6) }
            $samRow.Source = "stockanalysis.com/quote/fra/SSUN/financials/"
            $rows += $samRow
        } else {
            Write-Warning "No existing Samsung row; skipping."
        }
    }
} else {
    Write-Warning "Samsung scrape failed; retaining existing row."
    if (Test-Path $OutPath) {
        $existing = Import-Csv $OutPath | Where-Object { $_.Ticker -eq "005930.KS" }
        if ($existing) {
            $rows += $existing | Select-Object -First 1
        }
    }
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation
Write-Host "Done. Wrote $OutPath with $($rows.Count) rows."
