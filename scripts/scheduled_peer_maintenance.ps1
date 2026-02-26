param(
    [int]$MaxAgeDays = 14
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path "$scriptRoot\..").Path
Set-Location $projectRoot

Write-Host "=== Scheduled Peer Maintenance ==="
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$exitCode = 0
$status = "Success"

try {
    & powershell.exe -ExecutionPolicy Bypass -File scripts/peer_maintenance.ps1 -MaxAgeDays $MaxAgeDays
    if ($LASTEXITCODE -ne 0) {
        $exitCode = $LASTEXITCODE
        $status = "Failed"
    }
} catch {
    Write-Warning "peer_maintenance.ps1 threw an exception: $_"
    $exitCode = 1
    $status = "Failed"
}

# Append run history with exit code and status
$asOf = Get-Date -Format "yyyy-MM-dd"
$ua = "peer-maintenance"
if (Test-Path "research/sec_user_agent.txt") {
    $fromFile = (Get-Content -Raw "research/sec_user_agent.txt").Trim()
    if ($fromFile.Length -ge 6) { $ua = $fromFile }
}

try {
    & powershell.exe -ExecutionPolicy Bypass -File scripts/append_run_history.ps1 `
        -AsOfDate $asOf -Price 0 -UserAgent $ua -ExitCode $exitCode -Status $status
} catch {
    Write-Warning "append_run_history.ps1 failed: $_"
}

# Write Windows Event Log on failure
if ($exitCode -ne 0) {
    try {
        $msg = "Projek1 peer maintenance failed. ExitCode=$exitCode"
        if (-not [System.Diagnostics.EventLog]::SourceExists("Projek1")) {
            [System.Diagnostics.EventLog]::CreateEventSource("Projek1", "Application")
        }
        Write-EventLog -LogName Application -Source "Projek1" -EventId 1002 -EntryType Error -Message $msg
        Write-Host "Event Log entry written (EventId 1002)."
    } catch {
        Write-Warning "Could not write Event Log: $_"
    }
}

# Run outcome checker
try {
    & powershell.exe -ExecutionPolicy Bypass -File scripts/check_scheduler_outcomes.ps1
} catch {
    Write-Warning "check_scheduler_outcomes.ps1 failed: $_"
}

Write-Host "Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Status=$status ExitCode=$exitCode"
exit $exitCode
