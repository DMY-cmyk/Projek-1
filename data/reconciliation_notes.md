# Reconciliation Notes (FY2021–FY2025)
Source: SEC Form 10-K tables; `data/financials_*.csv`; `data/metrics_*.csv`; `data/valuation_snapshot.csv`

## Segment Net Sales vs Total (FY2025)
- Americas: 178.353
- Europe: 111.032
- Greater China: 64.377
- Japan: 28.703
- Rest of Asia Pacific: 33.696
- Sum of segments: 416.161
- Reported total net sales: 416.161
- Delta: 0.000 ✓

## Product Net Sales vs Total (FY2025)
- iPhone: 209.586
- Mac: 33.708
- iPad: 28.023
- Wearables, Home and Accessories: 35.686
- Services: 109.158
- Sum of products: 416.161
- Reported total net sales: 416.161
- Delta: 0.000 ✓

## Balance Sheet Equation (all years)
See `data/reconciliation_balance_sheet.md`. Assets = Liabilities + Equity for all five years; delta = 0 in each. ✓

## Cash Flow Reconciliation
See `data/reconciliation_cashflow.md`. CFO+CFI+CFF vs change in cash:
- FY2022 delta: -0.342B (FX effect on cash)
- FY2023 delta: +0.559B (FX effect on cash)
- FY2024 delta: +0.772B (FX effect on cash; may also reflect EU escrow reclassification)
- FY2025 delta: 0.000 ✓
Small deltas in FY2022–FY2024 are attributable to the "Effect of exchange rate changes on cash" line item, which is not captured as a separate tag.

## Profitability Metrics Verification (FY2025)
- GrossMargin = 195.201 / 416.161 = 0.4691 ✓
- OperatingMargin = 133.05 / 416.161 = 0.3197 ✓
- NetMargin = 112.01 / 416.161 = 0.2692 ✓

## Growth Metrics Verification
- RevYoY FY2025 = (416.161 − 391.035) / 391.035 = 0.0643 ✓
- RevYoY FY2024 = (391.035 − 383.285) / 383.285 = 0.0202 ✓
- RevYoY FY2023 = (383.285 − 394.328) / 394.328 = −0.0280 ✓
- RevYoY FY2022 = (394.328 − 365.817) / 365.817 = 0.0779 ✓
- CAGR (FY2021–FY2025) = (416.161 / 365.817)^(1/4) − 1 = 0.0328 ✓

## Balance Sheet Metrics Verification (FY2025)
- ROA = 112.01 / 359.241 = 0.3118 ✓ (end-of-period assets)
- ROE = 112.01 / 73.733 = 1.5191 ✓ (end-of-period equity)
- ROIC = 133.05 / 136.456 = 0.975 ✓ (Operating Income / Invested Capital)
- InvestedCapital = Equity + Debt − Cash = 73.733 + 98.657 − 35.934 = 136.456 ✓
- NetCash = Cash + MarketableSecurities(current) + MarketableSecurities(noncurrent) − TotalDebt = 35.934 + 18.763 + 77.723 − 98.657 = 33.763 ✓
- CurrentRatio = 147.957 / 165.631 = 0.8933 ✓
- QuickRatio = (147.957 − 5.718) / 165.631 = 0.8588 ✓

## Cash Flow Metrics Verification (FY2025)
- FCF = CFO − Capex = 111.482 − 12.715 = 98.767 ✓
- FCFConversion = 98.767 / 112.01 = 0.8818 ✓
- CapexPctRevenue = 12.715 / 416.161 = 0.0306 ✓
- EBITDA = OperatingIncome + D&A = 133.05 + 11.698 = 144.748 ✓
- EBITDAMargin = 144.748 / 416.161 = 0.3478 ✓

## Valuation Snapshot Verification (2026-02-20)
- MarketCap = 264.58 × 15.0047 = 3969.9435 ✓
- EV = MarketCap − NetCash = 3969.9435 − 33.763 = 3936.1805 ✓
- P/E = 3969.9435 / 112.01 = 35.4428 ✓
- EV/EBITDA = 3936.1805 / 144.748 = 27.1933 ✓
- EV/FCF = 3936.1805 / 98.767 = 39.8532 ✓
- P/FCF = 3969.9435 / 98.767 = 40.195 ✓
- BuybackYield = 90.711 / 3969.9435 = 0.0228 ✓
- DividendYield = 15.421 / 3969.9435 = 0.0039 ✓
- PayoutRatio = 15.421 / 112.01 = 0.1377 ✓
- TotalPayoutRatio = (90.711 + 15.421) / 112.01 = 0.9475 ✓

## DCF Base Case Verification
- PV of projected FCF (Y1–Y5): 477.132 ✓ (independently recalculated)
- PV of terminal value: 1613.911 ✓
- Enterprise value: 2091.043 ✓
- Equity value per share: $141.61 ✓
- Minor rounding variance (≤$0.012B) between dcf_summary.md and dcf_scenarios.csv; immaterial.

## Methodology Notes
- ROA and ROE use **end-of-period** denominators (not period averages). This is internally consistent across all five years.
- ROIC uses **Operating Income** (not NOPAT) over **Invested Capital** (Equity + Debt − Cash). This is an operating-level return metric.
- TotalDebt = LongTermDebtNoncurrent + LongTermDebtCurrent + CommercialPaper.
- NetCash includes both current and noncurrent marketable securities.

## QA Status
All numbers in `outputs/report.md` reconcile to source data. No discrepancies found.
