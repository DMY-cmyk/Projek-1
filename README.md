# Projek-1
Docs updated: 2026-02-23

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
