param(
    [string]$AsOfDate,
    [double]$Price,
    [string]$UserAgent,
    [string]$OutPath = "outputs/run_history.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $AsOfDate) {
    Write-Error "AsOfDate is required."
    exit 1
}

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent \"Name email@domain.com\""
    exit 1
}

if (-not (Test-Path "outputs")) {
    New-Item -ItemType Directory -Force "outputs" | Out-Null
}

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$fetchStatus = if (Test-Path "outputs/fetch_status.md") { (Get-Content "outputs/fetch_status.md" | Select-String -Pattern "^\* Fresh data used:").Line } else { "" }
$fresh = $false
if ($fetchStatus -match "true") { $fresh = $true }

$row = [pscustomobject]@{
    Timestamp = $ts
    AsOfDate = $AsOfDate
    Price = $Price
    UserAgent = $UserAgent
    FreshDataUsed = $fresh
}

if (-not (Test-Path $OutPath)) {
    $row | Export-Csv -Path $OutPath -NoTypeInformation
} else {
    $row | Export-Csv -Path $OutPath -NoTypeInformation -Append
}

Write-Host "Appended run history to $OutPath."
