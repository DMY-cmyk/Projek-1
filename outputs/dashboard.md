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

## Quarterly Inputs (Optional)
If quarterly CSVs exist, drop them into data/quarterly_*.csv and re-run this script.
Expected columns: Period, Revenue, GrossMargin, OperatingMargin, NetMargin, FCF.
