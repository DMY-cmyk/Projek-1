Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Projek-1 Helpers"
Write-Host "----------------"
@(
    @{ Name = "check_env.ps1"; Desc = "Check execution policy, toolchain, and required scripts." },
    @{ Name = "validate_inputs.ps1"; Desc = "Validate AsOfDate, Price, and User-Agent format." },
    @{ Name = "help_search.ps1"; Desc = "Filter helper list by a keyword query." },
    @{ Name = "check_sec_connectivity.ps1"; Desc = "Preflight SEC endpoints and log latency/status." },
    @{ Name = "fetch_sec_retry.ps1"; Desc = "Fetch SEC data with retries and optional fail-fast." },
    @{ Name = "quick_run.ps1"; Desc = "Preflight + fetch + cache validation (no extraction)." },
    @{ Name = "refresh_all.ps1"; Desc = "Full refresh pipeline (basic)." },
    @{ Name = "refresh_all_safe.ps1"; Desc = "Full refresh with preflight + cache validation." },
    @{ Name = "refresh_all_report.ps1"; Desc = "Safe refresh + run summary + history." },
    @{ Name = "refresh_with_auto_price.ps1"; Desc = "Refresh using auto-resolved market price fallback chain." },
    @{ Name = "refresh_and_report.ps1"; Desc = "Refresh + output + fetch summaries." },
    @{ Name = "refresh_all_ci.ps1"; Desc = "Safe refresh + output verification (CI)." },
    @{ Name = "export_run_bundle.ps1"; Desc = "Zip key run artifacts into outputs/run_bundle.zip." },
    @{ Name = "append_run_history.ps1"; Desc = "Append run metadata to outputs/run_history.csv." },
    @{ Name = "compare_run_history.ps1"; Desc = "Compare last two runs." },
    @{ Name = "list_recent_runs.ps1"; Desc = "Show last N run history entries." },
    @{ Name = "print_run_summary.ps1"; Desc = "Print outputs/run_summary.md." },
    @{ Name = "summarize_outputs.ps1"; Desc = "List outputs with size and timestamps." },
    @{ Name = "verify_outputs.ps1"; Desc = "Check required output files." },
    @{ Name = "clean_outputs.ps1"; Desc = "Remove outputs/*.md and *.json (optional include history)." },
    @{ Name = "rotate_fetch_logs.ps1"; Desc = "Archive fetch_status.md and fetch_errors.md." },
    @{ Name = "print_fetch_summary.ps1"; Desc = "Summarize fetch status and last error." },
    @{ Name = "print_versions.ps1"; Desc = "Write PowerShell, Git, and Rust versions to outputs/versions.md." },
    @{ Name = "fetch_sec_status.ps1"; Desc = "Summarize request_status.csv by endpoint." },
    @{ Name = "trim_request_status.ps1"; Desc = "Trim request_status.csv to last N days." },
    @{ Name = "verify_sec_cache.ps1"; Desc = "Check latest SEC cache age." },
    @{ Name = "get_latest_price.ps1"; Desc = "Resolve market price from providers + log source metadata." },
    @{ Name = "peer_maintenance.ps1"; Desc = "Refresh peer multiples then validate peer datasets." },
    @{ Name = "verify_peer_data.ps1"; Desc = "Validate peer CSV schema, freshness, and non-empty rows." },
    @{ Name = "run_regression_checks.ps1"; Desc = "Run regression checks for critical helper scripts." },
    @{ Name = "register_maintenance_tasks.ps1"; Desc = "Create/refresh scheduled weekly maintenance tasks." },
    @{ Name = "validate_sec_files.ps1"; Desc = "Validate SEC JSON files are non-empty and parseable." },
    @{ Name = "restore_sec_cache.ps1"; Desc = "Restore cached SEC JSONs from latest backup." },
    @{ Name = "health_check_fetch.ps1"; Desc = "Rotate logs + preflight + fetch + summary." },
    @{ Name = "fetch_sec_sources.ps1"; Desc = "Fetch SEC submissions/companyfacts and filings." },
    @{ Name = "update_peer_fundamentals.ps1"; Desc = "Auto-refresh data/peer_fundamentals.csv from SEC and web sources." },
    @{ Name = "update_peer_multiples.ps1"; Desc = "Fetch latest peer multiples into data/peer_multiples.csv." },
    @{ Name = "scheduled_refresh.ps1"; Desc = "Wrapper for scheduled refresh with outcome logging and alerts." },
    @{ Name = "scheduled_peer_maintenance.ps1"; Desc = "Wrapper for scheduled peer maintenance with outcome logging." },
    @{ Name = "check_scheduler_outcomes.ps1"; Desc = "Generate scheduler outcome report in outputs/scheduler_outcome.md." },
    @{ Name = "list_scheduler_outcomes.ps1"; Desc = "Display recent scheduler outcomes from run_history.csv." }
) | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.Name, $_.Desc)
}
