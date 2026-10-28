# Validated: dynamic_lots — v2 optimized + v5 default

## v2 optimized OOS: 2022.01.01-2024.01.01
Params: H=3, MaxPos=8, BatchClose=3, RiskPct=0.20, IncrRatio=1.0, MaxLoss=3
- Trades: 259341, Win%: 61.12%, PF: 1.28, Sharpe: 34.81, DD: 4.05%, Recovery: 23.76
- Net profit: $10,634,917 (compound from $10K)
Verdict: **VALIDATED**

## v5 default OOS: 2022.01.01-2024.01.01
Params: H=5, MaxPos=4, BatchClose=4, RiskPct=0.5, IncrRatio=0.5, MaxLoss=4
- Trades: 56350, Win%: 63.67%, PF: 1.23, Sharpe: 7.47, DD: 14.47%, Recovery: 5.75
- Net profit: $340,190 (compound from $10K)
Verdict: **VALIDATED** (but DD 14.47% is concerning)

## Period comparison (v2 optimized)
| Period | Trades | PF | Sharpe | DD% |
|--------|--------|------|--------|-----|
| In-sample 2024-2026 | 179373 | 1.37 | 25.46 | 3.4% |
| OOS 2022-2024 | 259341 | 1.28 | 34.81 | 4.1% |

## Final verdict: STRONG
Both in-sample and OOS profitable. DD under 4.1% with compound growth.
Dynamic lot sizing enables exponential returns while maintaining risk control.
v2 optimized (conservative Risk=0.20%) is preferred over aggressive options.
