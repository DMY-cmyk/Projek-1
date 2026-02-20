# Projek-1
Docs updated: 2026-02-20

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

## Quick start
```powershell
cargo run
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
- `outputs/report.md` draft report assembled from tables.

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
- Build a Rust module to fetch and cache SEC API JSON.
- Expand report narrative using the notes in `research/`.
