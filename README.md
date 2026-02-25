# Projek-1
Docs updated: 2026-02-25

Rust workspace centered on a detailed plan to analyze Apple Inc. fundamentals using SEC `data.sec.gov` APIs. The code is a minimal starter binary and can be expanded into a data-fetching and analysis tool.

## Contents
- `src/main.rs` starter binary.
- `Plan.md` detailed analysis plan.
- `analysis_config.toml` plan parameters used for the analysis run.
- `scripts/` PowerShell pipeline for SEC fetch/extract/metrics/report.
- `research/`, `data/`, `models/`, `outputs/` working folders.
- `.gitignore` includes Rust build outputs and credential/secrets patterns.

## Plan parameters (from `analysis_config.toml`)
- Analysis date: 2025-01-01.
- Reporting cut-off: most recent fiscal year available as of 2025-01-01.
- Currency/units: USD, billions.
- History length: 5 years annual.
- Data source: SEC `data.sec.gov` (company facts, submissions, optional frames).

## Requirements
- Rust toolchain (cargo + rustc).
- On Windows, the MSVC linker is required to build with the default toolchain.
- PowerShell (for the analysis scripts).
- On Windows, .NET charting (System.Windows.Forms.DataVisualization) is needed to render charts.

## Quick start
```powershell
cargo run
```

## SEC API fetch (Rust)
Fetch and cache SEC JSON into `research/sec/` with request logging.
```powershell
cargo run -- fetch-sec --cik 0000320193 --user-agent "Name email@domain.com"
```

## Full pipeline (Rust + PowerShell)
Run the end-to-end pipeline (fetch, extract, metrics, valuation, report, charts).
```powershell
cargo run -- run-pipeline --cik 0000320193 --user-agent "Name email@domain.com" --price 264.58 --as-of-date 2026-02-20
```

## Charts (PowerShell)
Generate PNG charts into `outputs/charts/`.
```powershell
.\scripts\build_charts.ps1
```

## Dashboard (PowerShell)
Generate a lightweight monitoring dashboard in `outputs/dashboard.md`.
```powershell
.\scripts\build_dashboard.ps1
```

## Key events log (PowerShell)
Generate a concise filings log (10-K/10-Q/8-K) in `outputs/key_events.md`.
```powershell
.\scripts\build_key_events.ps1
```

## Data freshness (PowerShell)
Check how old the latest filings and valuation snapshot are in `outputs/freshness_report.md`.
```powershell
.\scripts\check_data_freshness.ps1
```

## Change log (PowerShell)
Summarize year-over-year deltas into `outputs/change_log.md`.
```powershell
.\scripts\build_change_log.ps1
```

## Drift alerts (PowerShell)
Flag outliers vs 5-year averages in `outputs/drift_alerts.md`.
```powershell
.\scripts\build_drift_alerts.ps1
```

## Scenario stress tester (PowerShell)
Generate a simple stress table in `outputs/scenario_stress.md`.
```powershell
.\scripts\build_scenario_stress.ps1
```

## Report pack (PowerShell)
Run all generators and write a run log in `outputs/run_log.md`.
```powershell
.\scripts\build_report_pack.ps1
```

## One-command refresh (PowerShell)
Fetch SEC data and run the full report pack in one command.
```powershell
.\scripts\refresh_all.ps1 -UserAgent "Name email@domain.com" -Price 264.58 -AsOfDate 2026-02-20
```

## One-command refresh (safe)
Runs preflight + cache validation before extraction.
```powershell
.\scripts\refresh_all_safe.ps1 -UserAgent "Name email@domain.com" -Price 264.58 -AsOfDate 2026-02-20
```

## One-command refresh (CI)
Runs safe refresh and fails if required outputs are missing.
```powershell
.\scripts\refresh_all_ci.ps1 -UserAgent "Name email@domain.com" -Price 264.58 -AsOfDate 2026-02-20
```

## One-command refresh (safe + summary)
Runs safe refresh and writes `outputs/run_summary.md`.
```powershell
.\scripts\refresh_all_report.ps1 -UserAgent "Name email@domain.com" -Price 264.58 -AsOfDate 2026-02-20
```

## Refresh + report (PowerShell)
Runs `refresh_all_report.ps1` then prints output and fetch summaries.
```powershell
.\scripts\refresh_and_report.ps1 -UserAgent "Name email@domain.com" -Price 264.58 -AsOfDate 2026-02-20
```

## Quick run (PowerShell)
Preflight + fetch + cache validation only (no extraction).
```powershell
.\scripts\quick_run.ps1 -UserAgent "Name email@domain.com"
```

## Environment check (PowerShell)
Verify execution policy, toolchain, and required scripts.
```powershell
.\scripts\check_env.ps1
```

## Input validation (PowerShell)
Validate `-AsOfDate`, `-Price`, and User-Agent format.
```powershell
.\scripts\validate_inputs.ps1 -AsOfDate 2026-02-20 -Price 264.58 -UserAgent "Name email@domain.com"
```

## Verify outputs (PowerShell)
Check for required output files after a run.
```powershell
.\scripts\verify_outputs.ps1
```

## Export run bundle (PowerShell)
Zip key run artifacts into `outputs/run_bundle.zip`.
```powershell
.\scripts\export_run_bundle.ps1
```

## Run history (PowerShell)
Append key run metadata to `outputs/run_history.csv`.
```powershell
.\scripts\append_run_history.ps1 -AsOfDate 2026-02-20 -Price 264.58 -UserAgent "Name email@domain.com"
```

## Print run summary (PowerShell)
Print a concise view of `outputs/run_summary.md`.
```powershell
.\scripts\print_run_summary.ps1
```

## Compare run history (PowerShell)
Compare the last two runs in `outputs/run_history.csv`.
```powershell
.\scripts\compare_run_history.ps1
```

## List recent runs (PowerShell)
Show the last N rows of `outputs/run_history.csv`.
```powershell
.\scripts\list_recent_runs.ps1 -Count 5
```

## Outputs summary (PowerShell)
List output files with size and last modified time.
```powershell
.\scripts\summarize_outputs.ps1
```

## Clean outputs (PowerShell)
Remove `outputs/*.md` and `outputs/*.json`. Use `-DryRun` to preview. Use `-IncludeHistory` to delete `run_history.csv` and `run_summary.md`.
```powershell
.\scripts\clean_outputs.ps1 -DryRun
.\scripts\clean_outputs.ps1
.\scripts\clean_outputs.ps1 -IncludeHistory
```

## SEC fetch with retry (PowerShell)
Retry SEC fetch with exponential backoff and log errors to `outputs/fetch_errors.md`.
```powershell
.\scripts\fetch_sec_retry.ps1 -UserAgent "Name email@domain.com" -MaxAttempts 3 -BaseDelaySeconds 5
```

## SEC fetch (fail fast on preflight)
Exit immediately if preflight fails on both endpoints.
```powershell
.\scripts\fetch_sec_retry.ps1 -UserAgent "Name email@domain.com" -FailFast
```

## Restore SEC cache (PowerShell)
Restore cached `submissions_*.json` and `companyfacts_*.json` from the latest `cache_backup_*` folder.
```powershell
.\scripts\restore_sec_cache.ps1
```

## Rotate fetch logs (PowerShell)
Archive `outputs/fetch_status.md` and `outputs/fetch_errors.md` with timestamps.
```powershell
.\scripts\rotate_fetch_logs.ps1
```

## Fetch summary (PowerShell)
Print a one-screen summary from `outputs/fetch_status.md` and `outputs/fetch_errors.md`.
```powershell
.\scripts\print_fetch_summary.ps1
```

## Fetch health check (PowerShell)
Rotate logs, run preflight, fetch (fail-fast), then print a summary.
```powershell
.\scripts\health_check_fetch.ps1 -UserAgent "Name email@domain.com"
```

## SEC cache verification (PowerShell)
Check the latest SEC cache files and flag if older than N days.
```powershell
.\scripts\verify_sec_cache.ps1 -MaxAgeDays 7
```

## SEC request status summary (PowerShell)
Summarize success/fail counts per endpoint from `research/sec/request_status.csv`.
```powershell
.\scripts\fetch_sec_status.ps1
```

## SEC cache validation (PowerShell)
Validate that the latest SEC JSON files are non-empty and parseable.
```powershell
.\scripts\validate_sec_files.ps1
```

## Trim request status log (PowerShell)
Keep only the last N days in `research/sec/request_status.csv`.
```powershell
.\scripts\trim_request_status.ps1 -MaxAgeDays 30
```

## SEC connectivity preflight (PowerShell)
Ping `data.sec.gov` and `www.sec.gov/Archives` and record latency + status in `outputs/fetch_status.md`.
```powershell
.\scripts\check_sec_connectivity.ps1 -UserAgent "Name email@domain.com"
```

## SEC fetch (force fresh, no cache fallback)
Skip cached `submissions_*.json` and `companyfacts_*.json` if downloads fail.
```powershell
.\scripts\fetch_sec_retry.ps1 -UserAgent "Name email@domain.com" -ForceFresh
```

## One-command refresh (dry run)
Validate inputs and print planned steps without network calls.
```powershell
.\scripts\refresh_all_dryrun.ps1 -UserAgent "Name email@domain.com" -Price 264.58 -AsOfDate 2026-02-20
```

## Refresh status (PowerShell)
Verify expected outputs and timestamps in `outputs/refresh_status.md`.
```powershell
.\scripts\refresh_all_status.ps1
```

## Quick review (PowerShell)
Summarize key outputs in `outputs/quick_review.md`.
```powershell
.\scripts\build_quick_review.ps1
```

## Cleanup (PowerShell)
Dry-run cleanup of old SEC JSONs and run logs; add `-Execute` to delete.
```powershell
.\scripts\cleanup_runs.ps1
.\scripts\cleanup_runs.ps1 -Execute
```

## Cleanup plan
Dry-run cleanup plan written to `outputs/cleanup_plan.md` when running `cleanup_runs.ps1`.

## Health check (PowerShell)
Validate output presence and freshness in `outputs/health_check.md`.
```powershell
.\scripts\build_health_check.ps1
```

## Summary JSON (PowerShell)
Write a machine-readable snapshot to `outputs/summary.json`.
```powershell
.\scripts\build_summary_json.ps1
```

## Export bundle (PowerShell)
Zip CSVs and key outputs into `outputs/export_bundle.zip`.
```powershell
.\scripts\build_export_bundle.ps1
```

## Outputs manifest (PowerShell)
Write hashes and sizes to `outputs/manifest.json`.
```powershell
.\scripts\build_outputs_manifest.ps1
```

## Report pack (CI)
Run all generators and fail on error; log to `outputs/run_log_ci.md`.
```powershell
.\scripts\build_report_pack_ci.ps1
```

## Sanity checks (PowerShell)
Validate basic relationships in `outputs/sanity_checks.md`.
```powershell
.\scripts\build_sanity_checks.ps1
```

## Data dictionary (PowerShell)
Generate column reference in `outputs/data_dictionary.md`.
```powershell
.\scripts\build_data_dictionary.ps1
```

## Release notes (PowerShell)
Summarize recent changes in `outputs/release_notes.md`.
```powershell
.\scripts\build_release_notes.ps1
```

## Benchmark snapshot (PowerShell)
Generate peer snapshot in `outputs/benchmark_snapshot.md`.
```powershell
.\scripts\build_benchmark_snapshot.ps1
```

## Benchmark history (PowerShell)
Append snapshot rows to `outputs/benchmark_history.csv`.
```powershell
.\scripts\append_benchmark_history.ps1
```
## Peer multiples refresh (PowerShell)
Fetch latest peer multiples (best-effort HTML parsing) into `data/peer_multiples.csv`.
```powershell
.\scripts\update_peer_multiples.ps1
```

## Analysis pipeline (PowerShell)
Run these in order after setting a real SEC User-Agent.
```powershell
.\scripts\fetch_sec_sources.ps1 -UserAgent "Name email@domain.com"
.\scripts\extract_companyfacts.ps1 -CompanyFactsPath "research\sec\companyfacts_YYYY-MM-DD.json"
.\scripts\compute_metrics.ps1
.\scripts\validate_financials.ps1
.\scripts\compute_valuation.ps1 -Price 0.00 -AsOfDate YYYY-MM-DD
.\scripts\build_report.ps1
```

## Outputs
- `data/financials_*.csv` extracted SEC facts (USD billions).
- `data/metrics_*.csv` derived metrics (margins, growth, liquidity, cash flow).
- `data/valuation_snapshot.csv` valuation multiples snapshot.
- `data/validation_report.txt` data health checks.
- `data/tag_validation_report.txt` SEC tag unit/period checks.
- `data/reconciliation_notes.md` net sales reconciliation notes.
- `data/one_time_items_notes.md` notable one-time items from 10-K.
- `data/reconciliation_balance_sheet.md` balance sheet equation checks.
- `data/reconciliation_cashflow.md` cash flow change vs net cash flow checks.
- `outputs/report.md` draft report assembled from tables.
- `models/dcf_base_case.csv` and `models/dcf_summary.md` illustrative DCF.
- `research/notes_debt_liquidity.md` debt maturity and interest sensitivity notes.
- `outputs/fetch_status.md` SEC fetch status (fresh vs cached).
- `research/sec/request_status.csv` per-request status code and error summary.

## Troubleshooting
- If SEC requests fail, ensure the User-Agent is a real name + email and try again.
- Missing tags are common in XBRL; check `data/validation_report.txt` and update tag mappings in `scripts/extract_companyfacts.ps1`.
- If the fetch script times out, rerun it; the SEC endpoints can be slow.

## Plan highlights
- Collect 10-K, 10-Q, 8-K, shareholder letter, and earnings transcripts.
- Use SEC APIs for standardized XBRL data with caching and rate limits.
- Normalize to USD billions and reconcile tags across filings.
- Analyze profitability, growth mix, balance sheet, cash flow, valuation, and risks.
- Validate SEC data against filings and log API requests.

## Next steps
- Rust module for SEC fetch/caching has been added (`cargo run -- fetch-sec`).
- Charts can be generated from `data/` via `scripts/build_charts.ps1`.
- Peer multiples data is tracked in `data/peer_multiples.csv` with sources in `research/peer_multiples_sources.md`.
- Peer fundamentals are tracked in `data/peer_fundamentals.csv` with sources in `research/peer_fundamentals_sources.md`.
