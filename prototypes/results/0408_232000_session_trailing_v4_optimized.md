# Result: session_trailing — v4 optimized
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
| SessionStart | 07:00 | 06:00 | 06-10 |
| SessionEnd | 22:00 | 23:00 | 19-23 |

## Metrics
- Total trades: 81305
- Profit factor: 1.73
- Sharpe ratio: 14.80
- Total net profit: +$25,371
- Max drawdown: 3.08%
- Recovery factor: 27.83

Note: IDENTICAL to v1 optimized — optimizer picks same session window (6-23).
