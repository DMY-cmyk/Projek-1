param(
    [string]$UserAgentFile = "research/sec_user_agent.txt",
    [string]$AsOfDate = (Get-Date -Format "yyyy-MM-dd")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path "$scriptRoot\..").Path
Set-Location $projectRoot

Write-Host "=== Scheduled Refresh: $AsOfDate ==="
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$exitCode = 0
$status = "Success"

try {
    & powershell.exe -ExecutionPolicy Bypass -File scripts/refresh_with_auto_price.ps1 `
        -UserAgentFile $UserAgentFile -AsOfDate $AsOfDate
    if ($LASTEXITCODE -ne 0) {
        $exitCode = $LASTEXITCODE
        $status = "Failed"
    }
} catch {
    Write-Warning "refresh_with_auto_price.ps1 threw an exception: $_"
    $exitCode = 1
    $status = "Failed"
}

# Resolve UserAgent for history logging
$ua = ""
if (Test-Path $UserAgentFile) {
    $ua = (Get-Content -Raw $UserAgentFile).Trim()
}
if (-not $ua -or $ua.Length -lt 6) { $ua = "scheduled-task" }

# Append run history with exit code and status
try {
    & powershell.exe -ExecutionPolicy Bypass -File scripts/append_run_history.ps1 `
        -AsOfDate $AsOfDate -Price 0 -UserAgent $ua -ExitCode $exitCode -Status $status
} catch {
    Write-Warning "append_run_history.ps1 failed: $_"
}

# Write Windows Event Log on failure
if ($exitCode -ne 0) {
    try {
        $msg = "Projek1 scheduled refresh failed. AsOfDate=$AsOfDate ExitCode=$exitCode"
        # Create event source if needed (requires admin on first run)
        if (-not [System.Diagnostics.EventLog]::SourceExists("Projek1")) {
            [System.Diagnostics.EventLog]::CreateEventSource("Projek1", "Application")
        }
        Write-EventLog -LogName Application -Source "Projek1" -EventId 1001 -EntryType Error -Message $msg
        Write-Host "Event Log entry written (EventId 1001)."
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
