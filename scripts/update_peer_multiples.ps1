param(
    [string]$OutPath = "data/peer_multiples.csv",
    [string]$AsOfDate = (Get-Date -Format "yyyy-MM-dd")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Page([string]$url) {
    return Invoke-WebRequest -Uri $url -UseBasicParsing
}

function Get-Metric([string]$html, [string]$label) {
    $pattern = [regex]::Escape($label) + '.*?<div[^>]*>([0-9.]+)</div>'
    $match = [regex]::Match($html, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($match.Success) { return [double]$match.Groups[1].Value }
    return $null
}

function Get-StockAnalysisMultiples([string]$symbol) {
    $url = "https://stockanalysis.com/stocks/$symbol/"
    $resp = Get-Page $url
    $html = $resp.Content
    return [pscustomobject]@{
        Url = $url
        PE = Get-Metric $html "P/E Ratio"
        EV_EBITDA = Get-Metric $html "EV/EBITDA"
        P_FCF = Get-Metric $html "P/FCF"
    }
}

function Get-StockAnalysisMultiplesQuote([string]$exchange, [string]$symbol) {
    $url = "https://stockanalysis.com/quote/$exchange/$symbol/"
    $resp = Get-Page $url
    $html = $resp.Content
    return [pscustomobject]@{
        Url = $url
        PE = Get-Metric $html "P/E Ratio"
        EV_EBITDA = Get-Metric $html "EV/EBITDA"
        P_FCF = Get-Metric $html "P/FCF"
    }
}

$rows = @()

$apple = Import-Csv data/valuation_snapshot.csv | Select-Object -First 1
$rows += [pscustomobject]@{
    Company = "Apple"
    Ticker = "AAPL"
    AsOfDate = $apple.AsOfDate
    PE = $apple.PE
    EV_EBITDA = $apple.EV_EBITDA
    P_FCF = $apple.P_FCF
    Source = "data/valuation_snapshot.csv"
}

$msft = Get-StockAnalysisMultiples "msft"
$rows += [pscustomobject]@{
    Company = "Microsoft"
    Ticker = "MSFT"
    AsOfDate = $AsOfDate
    PE = $msft.PE
    EV_EBITDA = $msft.EV_EBITDA
    P_FCF = $msft.P_FCF
    Source = $msft.Url
}

$googl = Get-StockAnalysisMultiples "googl"
$rows += [pscustomobject]@{
    Company = "Alphabet"
    Ticker = "GOOGL"
    AsOfDate = $AsOfDate
    PE = $googl.PE
    EV_EBITDA = $googl.EV_EBITDA
    P_FCF = $googl.P_FCF
    Source = $googl.Url
}

$samsung = Get-StockAnalysisMultiplesQuote "fra" "SSUN"
$rows += [pscustomobject]@{
    Company = "Samsung Electronics"
    Ticker = "SSUN"
    AsOfDate = $AsOfDate
    PE = $samsung.PE
    EV_EBITDA = $samsung.EV_EBITDA
    P_FCF = $samsung.P_FCF
    Source = $samsung.Url
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation
Write-Host "Done. Wrote $OutPath."
