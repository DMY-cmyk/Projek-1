param(
    [string]$AsOfDate,
    [double]$Price,
    [string]$UserAgent,
    [string]$OutPath = "outputs/run_history.csv",
    [int]$ExitCode = 0,
    [string]$Status = "Success"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $AsOfDate) {
    Write-Error "AsOfDate is required."
    exit 1
}

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent ""Name email@domain.com"""
    exit 1
}

if (-not (Test-Path "outputs")) {
    New-Item -ItemType Directory -Force "outputs" | Out-Null
}

# Migrate existing CSV if it lacks ExitCode/Status columns
if (Test-Path $OutPath) {
    $header = (Get-Content $OutPath -TotalCount 1)
    if ($header -and $header -notmatch "ExitCode") {
        $existing = Import-Csv $OutPath
        $migrated = @()
        foreach ($r in $existing) {
            $migrated += [pscustomobject]@{
                Timestamp     = $r.Timestamp
                AsOfDate      = $r.AsOfDate
                Price         = $r.Price
                UserAgent     = $r.UserAgent
                FreshDataUsed = $r.FreshDataUsed
                ExitCode      = 0
                Status        = "Success"
            }
        }
        $migrated | Export-Csv -Path $OutPath -NoTypeInformation
        Write-Host "Migrated $OutPath to include ExitCode/Status columns."
    }
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
    ExitCode = $ExitCode
    Status = $Status
}

if (-not (Test-Path $OutPath)) {
    $row | Export-Csv -Path $OutPath -NoTypeInformation
} else {
    $row | Export-Csv -Path $OutPath -NoTypeInformation -Append
}

Write-Host "Appended run history to $OutPath."
