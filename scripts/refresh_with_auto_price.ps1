param(
    [string]$UserAgent,
    [string]$UserAgentFile = "research/sec_user_agent.txt",
    [string]$AsOfDate = (Get-Date -Format "yyyy-MM-dd"),
    [string]$Symbol = "AAPL",
    [switch]$ForceFresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    if (Test-Path $UserAgentFile) {
        $fromFile = (Get-Content -Raw $UserAgentFile).Trim()
        if ($fromFile.Length -ge 6) {
            $UserAgent = $fromFile
        }
    }
}

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Pass -UserAgent or populate $UserAgentFile"
    exit 1
}

$priceOutput = & powershell.exe -ExecutionPolicy Bypass -File scripts/get_latest_price.ps1 -Symbol $Symbol
$priceText = ($priceOutput | Select-Object -Last 1).ToString().Trim()
$price = [double]$priceText
$priceArg = $price.ToString("0.####", [System.Globalization.CultureInfo]::InvariantCulture)

$args = @(
    "-ExecutionPolicy", "Bypass",
    "-File", "scripts/refresh_all_report.ps1",
    "-UserAgent", $UserAgent,
    "-Price", $priceArg,
    "-AsOfDate", $AsOfDate
)
if ($ForceFresh) { $args += "-ForceFresh" }

& powershell.exe @args
