param(
    [string]$HistoryPath = "outputs/run_history.csv",
    [string]$RunLogPath = "outputs/run_log.md",
    [string]$OutPath = "outputs/scheduler_outcome.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path "outputs")) {
    New-Item -ItemType Directory -Force "outputs" | Out-Null
}

$verdict = "PASS"
$details = @()

# Check latest run_history.csv entry
if (Test-Path $HistoryPath) {
    $rows = Import-Csv $HistoryPath
    if ($rows.Count -gt 0) {
        $latest = $rows | Select-Object -Last 1
        $details += "Latest run history entry:"
        $details += "  Timestamp:  $($latest.Timestamp)"
        $details += "  AsOfDate:   $($latest.AsOfDate)"
        $details += "  Status:     $($latest.Status)"

        $ec = 0
        if ($latest.PSObject.Properties.Name -contains "ExitCode") {
            $ec = [int]$latest.ExitCode
        }
        $details += "  ExitCode:   $ec"

        if ($ec -ne 0 -or $latest.Status -eq "Failed") {
            $verdict = "FAIL"
        }
    } else {
        $details += "run_history.csv is empty."
    }
} else {
    $details += "run_history.csv not found."
}

$details += ""

# Check run_log.md for non-zero exit codes
if (Test-Path $RunLogPath) {
    $logContent = Get-Content $RunLogPath
    $failLines = $logContent | Select-String -Pattern "\|\s*[1-9]\d*\s*\|" -AllMatches
    if ($failLines.Count -gt 0) {
        $verdict = "FAIL"
        $details += "run_log.md contains non-zero exit codes:"
        foreach ($line in $failLines) {
            $details += "  $($line.Line.Trim())"
        }
    } else {
        $details += "run_log.md: all steps show exit code 0."
    }
} else {
    $details += "run_log.md not found (no report pack run yet)."
}

# Write outcome report
$report = @(
    "# Scheduler Outcome Report",
    "",
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "",
    "## Verdict: $verdict",
    ""
)
$report += $details

$report | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Scheduler outcome: $verdict (wrote $OutPath)"

# Write Event Log warning on FAIL
if ($verdict -eq "FAIL") {
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists("Projek1")) {
            [System.Diagnostics.EventLog]::CreateEventSource("Projek1", "Application")
        }
        Write-EventLog -LogName Application -Source "Projek1" -EventId 1000 -EntryType Warning `
            -Message "Projek1 scheduler outcome: FAIL. See $OutPath for details."
        Write-Host "Event Log warning written (EventId 1000)."
    } catch {
        Write-Warning "Could not write Event Log: $_"
    }
}
