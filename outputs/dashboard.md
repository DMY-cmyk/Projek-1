# Apple Quarterly Monitoring Dashboard

## Snapshot (Latest Annual)
- Fiscal year: FY2025
- Revenue: 416.161B (YoY 6.43%)
- Gross margin: 46.91%
- Operating margin: 31.97%
- Net margin: 26.92%
- Free cash flow: 98.767B (FCF conversion 88.18%)

## Market Snapshot
|AsOfDate|Price|MarketCapBillions|EnterpriseValueBillions|PE|EV_EBITDA|EV_FCF|P_FCF|BuybackYield|DividendYield|
|---|---|---|---|---|---|---|---|---|---|
|2026-02-20|264.58|3969.9435|3936.1805|35.4428|27.1933|39.8532|40.195|0.0228|0.0039|

## KPI Trend (Annual)
Charts source: outputs/charts/ (run scripts/build_charts.ps1).

![Revenue and Operating Income](charts/revenue_operating_income.png)

![Margins](charts/margins.png)

![Free Cash Flow and Capital Returns](charts/fcf_capital_returns.png)

## Key Events
See outputs/key_events.md (run scripts/build_key_events.ps1).

## Data Freshness
See outputs/freshness_report.md (run scripts/check_data_freshness.ps1).

## Change Log
See outputs/change_log.md (run scripts/build_change_log.ps1).

## Drift Alerts
See outputs/drift_alerts.md (run scripts/build_drift_alerts.ps1).

## Scenario Stress
See outputs/scenario_stress.md (run scripts/build_scenario_stress.ps1).

## Report Pack
Run all generators and capture a run log in outputs/run_log.md (run scripts/build_report_pack.ps1).

## Refresh Status
Verify expected outputs with outputs/refresh_status.md (run scripts/refresh_all_status.ps1).

## Quick Review
Summarize key outputs in outputs/quick_review.md (run scripts/build_quick_review.ps1).

## Cleanup Plan
See outputs/cleanup_plan.md (dry run via scripts/cleanup_runs.ps1).

## Health Check
See outputs/health_check.md (run scripts/build_health_check.ps1).

## Summary JSON
Machine-readable snapshot in outputs/summary.json (run scripts/build_summary_json.ps1).

## Export Bundle
Zip bundle in outputs/export_bundle.zip (run scripts/build_export_bundle.ps1).

## Outputs Manifest
Integrity manifest in outputs/manifest.json (run scripts/build_outputs_manifest.ps1).

## Report Pack (CI)
CI-friendly run log in outputs/run_log_ci.md (run scripts/build_report_pack_ci.ps1).

## Sanity Checks
Validate basic relationships in outputs/sanity_checks.md (run scripts/build_sanity_checks.ps1).

## Data Dictionary
Column reference in outputs/data_dictionary.md (run scripts/build_data_dictionary.ps1).

## Release Notes
Latest changes in outputs/release_notes.md (run scripts/build_release_notes.ps1).

## Benchmark Snapshot
Peer snapshot in outputs/benchmark_snapshot.md (run scripts/build_benchmark_snapshot.ps1).

## Benchmark History
Append history to outputs/benchmark_history.csv (run scripts/append_benchmark_history.ps1).

## Quarterly Inputs (Optional)
If quarterly CSVs exist, drop them into data/quarterly_*.csv and re-run this script.
Expected columns: Period, Revenue, GrossMargin, OperatingMargin, NetMargin, FCF.
