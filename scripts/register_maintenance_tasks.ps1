param(
    [string]$UserAgent,
    [string]$UserAgentFile = "research/sec_user_agent.txt",
    [string]$RefreshTaskName = "Projek1-RefreshWeekly",
    [string]$PeerTaskName = "Projek1-PeerMaintenanceWeekly",
    [string]$RefreshTime = "07:30",
    [string]$PeerTime = "08:00"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent ""Name email@domain.com"""
    exit 1
}

$root = (Resolve-Path "$PSScriptRoot\..").Path
$refreshScript = Join-Path $root "scripts\refresh_with_auto_price.ps1"
$peerScript = Join-Path $root "scripts\peer_maintenance.ps1"
$userAgentFilePath = Join-Path $root $UserAgentFile
$uaDir = Split-Path -Parent $userAgentFilePath
if ($uaDir -and -not (Test-Path $uaDir)) {
    New-Item -ItemType Directory -Force $uaDir | Out-Null
}
$UserAgent | Out-File -FilePath $userAgentFilePath -Encoding utf8

$refreshTr = "powershell.exe -ExecutionPolicy Bypass -File `"$refreshScript`" -UserAgentFile `"$userAgentFilePath`""
$peerTr = "powershell.exe -ExecutionPolicy Bypass -File `"$peerScript`""

Write-Host "Registering scheduled task: $RefreshTaskName"
& schtasks.exe /Create /F /SC WEEKLY /D WED /TN $RefreshTaskName /TR $refreshTr /ST $RefreshTime | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to register task: $RefreshTaskName"
    exit 1
}

Write-Host "Registering scheduled task: $PeerTaskName"
& schtasks.exe /Create /F /SC WEEKLY /D WED /TN $PeerTaskName /TR $peerTr /ST $PeerTime | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to register task: $PeerTaskName"
    exit 1
}

Write-Host "Scheduled tasks created/updated."
