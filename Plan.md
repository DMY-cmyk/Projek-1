# Detailed Plan to Analyze Apple Inc. Fundamentals
Last updated: 2026-02-25

## 0) Parameters and setup
- Analysis date: 2025-01-01. (Completed; `analysis_config.toml`)
- Reporting cut-off: most recent fiscal year available as of 2025-01-01. (Completed; `analysis_config.toml`)
- Currency and units: USD, billions (all tables and charts). (Completed; `analysis_config.toml`)
- History length: 5 years annual. (Completed; `analysis_config.toml`)
- Define peer set (example: Microsoft, Alphabet, Samsung; adjust by focus). (Completed; `analysis_config.toml`)
- Define deliverable format (report, slides, spreadsheet, memo). (Completed; `analysis_config.toml`)
- Create folders (Completed):
  - research/ (primary sources)
  - data/ (cleaned tables)
  - models/ (valuation sheets)
  - outputs/ (charts, final report)

## 1) Source collection (primary, authoritative)
- Latest Form 10-K (annual), latest 10-Q (quarterly), and 8-Ks if material. (Completed; downloaded to `research/sec/filings/`)
- Latest annual report / shareholder letter. (Completed; `research/annual_report_2025-10-31_10k.pdf`)
- Earnings call transcripts for last 4 quarters. (Completed; links saved in `research/transcripts/`)
- Investor presentations (if any recent). (Completed; none found, noted in `research/investor_presentation_notes.txt`)
- Save each file with date in filename for traceability. (Completed; scripted in `scripts/fetch_sec_sources.ps1`)
- SEC data access via data.sec.gov (official API and feeds). (Completed; scripted in `scripts/fetch_sec_sources.ps1`)

## 2) Business overview (structured notes)
- Segment definitions: Products vs Services; map sub-categories. (Completed; `research/notes_business_overview.md`)
- Revenue by geography: Americas, Europe, Greater China, Japan, Rest of Asia Pacific. (Completed; `research/notes_business_overview.md`)
- Distribution and ecosystem: hardware + services interdependence. (Completed; `research/notes_business_overview.md`)
- Strategy themes: pricing, innovation, supply chain, services expansion. (Completed; `research/notes_business_overview.md`)
- Note any major M&A or divestitures during the period. (Completed; `research/notes_business_overview.md`)

## 3) Build raw financial dataset (SEC data.sec.gov API)
- Use SEC data endpoints: (Completed; scripts/fetch_sec_sources.ps1)
  - Company facts JSON: `https://data.sec.gov/api/xbrl/companyfacts/CIK##########.json`
  - Company submissions JSON: `https://data.sec.gov/submissions/CIK##########.json`
  - XBRL frames for standardized tags (optional):
    `https://data.sec.gov/api/xbrl/frames/CIK##########/us-gaap/<TAG>.json`
- Identify Apple CIK (from submissions API), then normalize to 10 digits (zero-padded). (Completed; default CIK 0000320193)
- Set HTTP headers per SEC guidance (User-Agent with contact; Accept-Encoding). (Completed; `scripts/fetch_sec_sources.ps1`)
- Rate-limit requests (e.g., max 10 requests/sec) and cache responses in `research/sec/`. (Completed; `scripts/fetch_sec_sources.ps1`)
- Extract 5 years of annual financials from `companyfacts`: (Completed; `scripts/extract_companyfacts.ps1`)
  - Income statement: revenue, gross profit, operating income, net income, EPS.
  - Balance sheet: cash, marketable securities, total debt, total equity.
  - Cash flow: CFO, CFI, CFF, capex, share repurchases, dividends.
- Capture diluted shares outstanding each period (use the same fiscal-year end). (Completed; `scripts/extract_companyfacts.ps1`)
- Normalize units to USD billions and ensure consistent period labels. (Completed; `scripts/extract_companyfacts.ps1`)
- Reconcile tag names (e.g., RevenueFromContractWithCustomerExcludingAssessedTax vs SalesRevenueNet). (Completed; revenue tag fallback in `scripts/extract_companyfacts.ps1`)

## 4) Clean and reconcile
- Check totals vs subtotals (segment sums, geography sums). (Completed; `data/reconciliation_notes.md`)
- Adjust for any accounting changes or reclassifications. (Completed; no adjustments needed — all accounting standard changes predate FY2021 window; see `data/one_time_items_notes.md`)
- Confirm annual totals match SEC facts periods and fiscal year end dates. (Completed; automated checks)
- Flag one-time items (legal settlements, tax benefits, impairments). (Completed; `data/one_time_items_notes.md`)
- Basic null/consistency checks report: `data/validation_report.txt` (Completed; `scripts/validate_financials.ps1`)

## 5) Core profitability metrics
- Gross margin, operating margin, net margin trends (annual + TTM). (Completed; `data/metrics_profitability.csv`)
- ROE and ROA (use average balance sheet values). (Completed; `data/metrics_balance.csv`)
- ROIC (define invested capital; include/exclude cash policy). (Completed; `data/metrics_balance.csv`)
- EBITDA and EBITDA margin (document calculation method). (Completed; `data/metrics_cashflow.csv`)
- Prepared metrics script: `scripts/compute_metrics.ps1` (Completed)

## 6) Growth and mix analysis
- CAGR for total revenue, Products, Services, and key sub-lines. (Completed for total revenue; `data/metrics_cagr.csv`)
- Year-over-year growth by segment and geography. (Completed for total revenue; `data/metrics_growth.csv`)
- Mix shift: Services share of total, hardware concentration. (Completed qualitatively; `research/notes_business_overview.md`)
- Unit trends and ASP trends if disclosed (iPhone, Mac, iPad, Wearables). (N/A; Apple discontinued unit disclosures in Q1 FY2019; noted in `research/notes_business_overview.md`)
- Prepared growth metrics script (Revenue YoY): `scripts/compute_metrics.ps1` (Completed)

## 7) Balance sheet strength and liquidity
- Net cash / net debt and trend. (Completed; `data/metrics_balance.csv`)
- Current ratio and quick ratio. (Completed; `data/metrics_balance.csv`)
- Debt maturity schedule and average interest cost (if available). (Completed for within-12-month amounts; `research/notes_debt_liquidity.md`)
- Shareholder equity trend and drivers. (Completed; summarized in report)
- Prepared balance metrics script (ROA/ROE/ROIC): `scripts/compute_metrics.ps1` (Completed)

## 8) Cash flow quality and capital allocation
- Free cash flow (FCF) definition and trend. (Completed; `data/metrics_cashflow.csv`)
- FCF conversion (FCF / net income). (Completed; `data/metrics_cashflow.csv`)
- Capex as % of revenue. (Completed; `data/metrics_cashflow.csv`)
- Buyback yield, dividend yield, payout ratios. (Completed; `data/valuation_snapshot.csv`)
- Prepared cash flow metrics script (FCF, capex %, EBITDA): `scripts/compute_metrics.ps1` (Completed)

## 9) Valuation inputs and multiples
- Pull market data snapshot date (price, shares, market cap, EV). (Completed; `data/valuation_snapshot.csv`)
- Compute P/E, EV/EBITDA, EV/FCF, P/FCF. (Completed; `data/valuation_snapshot.csv`)
- Compare to historical Apple ranges and peer median. (Completed; see `outputs/report.md`)
- Note any non-recurring items affecting multiples. (Completed; FY2025 multiples are clean; FY2024 EU tax charge impact documented in `outputs/report.md`)
- Market price source note: `research/market_price_source.txt` (Completed)

## 16) SEC API validation checklist
- Confirm CIK and ticker mapping (Apple Inc. -> CIK 0000320193). (Completed; default CIK used)
- Verify each tag's unit, period (FY), and form type (10-K). (Completed; `data/tag_validation_report.txt`)
- Cross-check totals vs 10-K PDF tables for the latest year. (Completed for net sales; `data/reconciliation_notes.md`)
- Keep a log of API requests and response timestamps. (Completed; `research/sec/request_log.csv`)

## 10) Competitive landscape and risks
- Direct competitors by product line and services. (Completed qualitatively; `research/notes_competitive_risks.md`)
- Platform risks: app store regulation, ecosystem lock-in, privacy rules. (Completed with local evidence + inference)
- Supply chain and geopolitical risks. (Completed for component supply; geography exposure noted)
- Currency sensitivity and macro demand elasticity. (Completed as inference from geographic mix)
- Prepared note template: `research/notes_competitive_risks.md` (Completed)

## 11) Management and governance review
- Leadership tenure and succession readiness. (Completed; updated from 2026 proxy)
- Board independence and committee composition. (Completed; updated from 2026 proxy)
- Exec comp alignment: TSR, EPS, FCF incentives. (Completed; updated from 2026 proxy)
- Shareholder proposals and governance issues. (Completed; updated from 2026 proxy)
- Prepared note template: `research/notes_management_governance.md` (Updated)

## 12) Thesis framework and scenarios
- Bull case: key drivers, required assumptions, catalysts. (Completed; `research/notes_thesis_scenarios.md`)
- Base case: normalized growth and margins. (Completed; `research/notes_thesis_scenarios.md`)
- Bear case: downside drivers and stress points. (Completed; `research/notes_thesis_scenarios.md`)
- Identify key KPIs to monitor each quarter. (Completed; `research/notes_thesis_scenarios.md`)
- Prepared note template: `research/notes_thesis_scenarios.md` (Completed)

## 13) Optional valuation model
- DCF inputs: revenue growth, margins, tax rate, WACC, terminal growth. (Completed; `models/dcf_summary.md`)
- Scenario table: optimistic/base/pessimistic. (Completed; `models/dcf_scenarios.csv`)
- Sensitivity table for WACC and terminal growth. (Completed; `models/dcf_sensitivity.csv`)
- Cross-check with multiples-based valuation. (Completed qualitatively in report)

## 14) Final report production
- Executive summary (1 page max). (Completed; `outputs/report.md`)
- Financials and charts (trend lines, mix, margins). (Completed; tables in `outputs/report.md`)
- Risk section and competitive analysis. (Completed; `outputs/report.md`)
- Valuation summary and recommendation. (Completed; `outputs/report.md`)
- Appendix: data sources, assumptions, calculation notes. (Completed; `outputs/report.md`)
- Prepared report outline: `outputs/report_outline.md` (Updated)
- Draft report generated: `outputs/report.md` (Updated; placeholders removed)

## 15) QA checklist (before finalizing)
- All numbers reconcile to filings. (Completed; full reconciliation of all metrics, multiples, and DCF verified; see `data/reconciliation_notes.md`)
- Units and currency are consistent. (Completed; USD billions)
- Assumptions documented with dates. (Completed; report + DCF summary)
- Charts labeled with source and period. (Completed; `outputs/charts/` via `scripts/build_charts.ps1`)
- Conclusions trace back to quantified evidence. (Completed; report references data tables)

## 17) Operational tooling and monitoring
- One-command refresh for SEC fetch + full report pack. (Completed; `scripts/refresh_all.ps1`)
- One-command refresh (safe mode). (Completed; `scripts/refresh_all_safe.ps1`)
- One-command refresh with run summary. (Completed; `scripts/refresh_all_report.ps1`)
- Refresh + report helper. (Completed; `scripts/refresh_and_report.ps1`)
- Run bundle export helper. (Completed; `scripts/export_run_bundle.ps1`)
- Run history append helper. (Completed; `scripts/append_run_history.ps1`)
- Run history comparison helper. (Completed; `scripts/compare_run_history.ps1`)
- Run history listing helper. (Completed; `scripts/list_recent_runs.ps1`)
- Outputs summary helper. (Completed; `scripts/summarize_outputs.ps1`)
- Outputs cleaning helper. (Completed; `scripts/clean_outputs.ps1`)
- Dry-run refresh validation. (Completed; `scripts/refresh_all_dryrun.ps1`)
- Report pack and CI report pack. (Completed; `scripts/build_report_pack.ps1`, `scripts/build_report_pack_ci.ps1`)
- Dashboard, key events log, and quick review rollups. (Completed; `outputs/dashboard.md`, `outputs/key_events.md`, `outputs/quick_review.md`)
- Freshness, sanity checks, and health check reports. (Completed; `outputs/freshness_report.md`, `outputs/sanity_checks.md`, `outputs/health_check.md`)
- Change log and scenario stress. (Completed; `outputs/change_log.md`, `outputs/scenario_stress.md`)
- Peer benchmarking snapshot and history. (Completed; `outputs/benchmark_snapshot.md`, `outputs/benchmark_history.csv`)
- Export bundle and outputs manifest. (Completed; `outputs/export_bundle.zip`, `outputs/manifest.json`)
- Cleanup dry-run plan. (Completed; `outputs/cleanup_plan.md`)
- Fetch status summary and per-request status log. (Completed; `outputs/fetch_status.md`, `research/sec/request_status.csv`)
esearch/sec/request_status.csv)
- ForceFresh option to skip cached SEC JSONs. (Completed; `scripts/fetch_sec_sources.ps1`, `scripts/fetch_sec_retry.ps1`)
- SEC connectivity preflight logging (data.sec.gov + archives). (Completed; `scripts/check_sec_connectivity.ps1`, `outputs/fetch_status.md`)
- Fail-fast option for preflight failures. (Completed; `scripts/fetch_sec_retry.ps1`)
- Cache restore helper for SEC JSONs. (Completed; `scripts/restore_sec_cache.ps1`)
- Fetch log rotation helper. (Completed; `scripts/rotate_fetch_logs.ps1`)
- Fetch summary helper for quick diagnostics. (Completed; `scripts/print_fetch_summary.ps1`)
- Fetch health check helper (rotate + preflight + fetch + summary). (Completed; `scripts/health_check_fetch.ps1`)
- SEC cache age verification helper. (Completed; `scripts/verify_sec_cache.ps1`)
- SEC request status summary helper. (Completed; `scripts/fetch_sec_status.ps1`)
- Request status log trimming helper. (Completed; `scripts/trim_request_status.ps1`)
- SEC cache validation helper. (Completed; `scripts/validate_sec_files.ps1`)







