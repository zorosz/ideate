# Result: liquidity_sweep_reversal — v6 default
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1

## Parameters
- SwingLength = 20
- MaxSwingAge = 30
- MaxBarsInTrade = 30
- StopBufferPips = 2.0
- SmallPierceMaxPips = 2.0 (skip)
- MediumPierceMaxPips = 8.0 (standard tier)

## Metrics
- Total Net Profit: -$1.81
- Profit Factor: 0.91
- Sharpe Ratio: -5.00
- Total trades: 57 (filtered down from 149)
- Win rate: 45.61% (26/57)
- Avg win: $0.75
- Avg loss: $0.63
- R:R: 1.19:1
- Equity DD: 0.05% ($4.82)

## Notes
- Pierce-magnitude tier filter REMOVES the edge
- Filtering out small pierces (<2 pips) drops trade count from 149 to 57
- PF drops from 1.06 to 0.91 — strongly negative
- Avg win is HIGHER ($0.75 vs $0.62) but win rate is LOWER (45.61% vs 47.65%)
- Conclusion: small-pierce trades were NOT noise. They contained the edge.
- The strategy's profile is "many small wins from clean reversals," not
  "rare big wins from violent sweeps"
- Confirms spec's "why this might fail": pierce size doesn't correlate
  linearly with reversal probability
