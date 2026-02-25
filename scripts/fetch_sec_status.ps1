param(
    [string]$LogPath = "research/sec/request_status.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $LogPath)) {
    Write-Host "No request status log found: $LogPath"
    exit 0
}

$rows = Import-Csv -Path $LogPath
if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "Request status log is empty."
    exit 0
}

$summary = $rows | Group-Object url | ForEach-Object {
    $group = $_.Group
    $ok = ($group | Where-Object { $_.ok -eq "True" }).Count
    $fail = ($group | Where-Object { $_.ok -eq "False" }).Count
    [pscustomobject]@{
        Url = $_.Name
        Ok = $ok
        Fail = $fail
        LastStatus = ($group | Select-Object -Last 1).status_code
    }
}

Write-Host "SEC Request Status Summary"
Write-Host "--------------------------"
$summary | Sort-Object -Property Fail -Descending | Format-Table -AutoSize
