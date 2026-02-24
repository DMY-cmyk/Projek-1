# Quick Review

## Key Events
# Key Events Log

Source: D:\VsCode\Projek-1\research\sec\submissions_2026-02-24.json

Latest filings (10-K, 10-Q, 8-K):
|Form|FilingDate|ReportDate|Accession|
|---|---|---|---|
|10-Q|2026-01-30|2025-12-27|0000320193-26-000006|
|8-K|2026-01-29|2026-01-29|0000320193-26-000005|
|8-K|2026-01-02|2025-12-30|0001140361-26-000199|
|8-K|2025-12-05|2025-12-04|0001140361-25-044561|
|10-K|2025-10-31|2025-09-27|0000320193-25-000079|
|8-K|2025-10-30|2025-10-30|0000320193-25-000077|
|10-Q|2025-08-01|2025-06-28|0000320193-25-000073|
|8-K|2025-07-31|2025-07-31|0000320193-25-000071|

## Freshness
# Data Freshness Report

Generated: 2026-02-24 21:56:49 local time
Warning threshold: 60 days

## Latest SEC Filing
|Form|FilingDate|ReportDate|Accession|
|---|---|---|---|
|10-Q|2026-01-30|2025-12-27|0000320193-26-000006|
Age (days): 25

## Latest Valuation Snapshot
|AsOfDate|Price|MarketCapBillions|EnterpriseValueBillions|PE|EV_EBITDA|EV_FCF|P_FCF|
|---|---|---|---|---|---|---|---|
|2026-02-20|264.58|3969.9435|3936.1805|35.4428|27.1933|39.8532|40.195|
Age (days): 4

## Alerts
- No freshness warnings.


## Change Log
# Change Log

Latest vs prior fiscal year: FY2025 vs FY2024

|Metric|Latest|Prior|Change|
|---|---|---|---|
|Revenue (USD B)|416.161|391.035|25.126|
|Operating Income (USD B)|133.05|123.216|9.834|
|Net Income (USD B)|112.01|93.736|18.274|
|Gross Margin|0.4691|0.4621|0.007|
|Operating Margin|0.3197|0.3151|0.0046|
|Net Margin|0.2692|0.2397|0.0295|
|Net Cash (USD B)|33.763|50.021|-16.258|
|Free Cash Flow (USD B)|98.767|108.807|-10.04|
|Buybacks (USD B)|90.711|94.949|-4.238|
|Dividends (USD B)|15.421|15.234|0.187|

Notes:
- Positive Change means latest year is higher than the prior year.
- Margins are shown as decimals (e.g., 0.4691 = 46.91%).

## Drift Alerts
# Metrics Drift Alerts

Latest fiscal year: FY2025
Threshold: |Z| >= 2

## Z-Score Summary
|Metric|Latest|Mean|StdDev|ZScore|
|---|---|---|---|---|
|Gross Margin|0.4691|0.4447|0.021|1.16|
|Operating Margin|0.3197|0.3067|0.0101|1.29|
|Net Margin|0.2692|0.2548|0.0107|1.35|
|FCF Conversion|0.8818|1.0335|0.1105|-1.37|
|Capex % Revenue|0.0306|0.0282|0.0026|0.93|
|ROIC|0.975|0.8439|0.1045|1.26|
|Current Ratio|0.8933|0.9405|0.0888|-0.53|

## Alerts
- No drift alerts.


## Scenario Stress
# Scenario Stress Tester

Base year: FY2025
Base revenue: 416.161 (USD B)
Base operating margin: 31.97%

Shocks:
- Revenue shocks: 0%, 5%, -5%
- Operating margin shocks: 0%, 2%, -2%
- WACC base: 8.00%, shocks: 0%, 1%, 2%

|RevenueShock|MarginShock|Wacc|AdjRevenue|AdjOperatingIncome|
|---|---|---|---|---|
|-5%|-2%|8.00%|395.35|118.49|
|-5%|-2%|9.00%|395.35|118.49|
|-5%|-2%|10.00%|395.35|118.49|
|-5%|0%|8.00%|395.35|126.4|
|-5%|0%|9.00%|395.35|126.4|
|-5%|0%|10.00%|395.35|126.4|
|-5%|2%|8.00%|395.35|134.3|
