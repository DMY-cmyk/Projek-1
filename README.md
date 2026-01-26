# Projek-1

Rust workspace centered on a detailed plan to analyze Apple Inc. fundamentals using SEC `data.sec.gov` APIs. The code is a minimal starter binary and can be expanded into a data-fetching and analysis tool.

## Contents
- `src/main.rs` starter binary.
- `Plan.md` detailed analysis plan (gitignored).
- `.gitignore` includes Rust build outputs and credential/secrets patterns.

## Plan parameters (from Plan.md)
- Analysis date: 2025-01-01.
- Reporting cut-off: most recent fiscal year available as of 2025-01-01.
- Currency/units: USD, billions.
- History length: 5 years annual.
- Data source: SEC `data.sec.gov` (company facts, submissions, optional frames).

## Requirements
- Rust toolchain (cargo + rustc).
- On Windows, the MSVC linker is required to build with the default toolchain.

## Quick start
```powershell
cargo run
```

## Plan highlights
- Collect 10-K, 10-Q, 8-K, shareholder letter, and earnings transcripts.
- Use SEC APIs for standardized XBRL data with caching and rate limits.
- Normalize to USD billions and reconcile tags across filings.
- Analyze profitability, growth mix, balance sheet, cash flow, valuation, and risks.
- Validate SEC data against filings and log API requests.

## Next steps
- Build a Rust module to fetch and cache SEC API JSON.
- Add data outputs under `data/`, `models/`, and `outputs/`.
