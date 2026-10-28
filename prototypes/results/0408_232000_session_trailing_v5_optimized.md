# Result: session_trailing — v5 optimized
Date: 2026-04-09
Period: 2025.01-2026.01

## Parameters
| Parameter | Default | Optimized | Range |
|-----------|---------|-----------|-------|
| HarvestPips | 5 | 3 | 3-10 |
| MaxPositionsPerSide | 6 | 6 | 3-10 |
| BatchCloseMinPositions | 4 | 4 | 2-6 |
| LotIncrement | 0.025 | 0.025 | 0.01-0.05 |
| MaxFloatingLossPct | 4 | 3 | 3-10 |
| TrailActivatePips | 3.0 | 2.0 | 2-15 |
| TrailDistancePips | 1.5 | 7.0 | 1-10 |

## Metrics
- Total trades: 92247
- Profit factor: 1.73
- Sharpe ratio: 15.50
- Total net profit: +$28,295
- Max drawdown: 3.03%
- Recovery factor: 29.49

Note: IDENTICAL to v2 optimized — both converge to Trail=2/7 with H=3, MaxLoss=3.
