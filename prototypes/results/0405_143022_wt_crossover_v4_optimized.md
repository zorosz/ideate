# Result: wt_crossover — v4 optimized (WT + RSI)
Date: 2026-04-05
Period: 2025.01-2026.01
Passes: 3705

## Parameters
| Parameter | Default | Optimized | Range |
|-----------|---------|-----------|-------|
| WTChannel | 10 | 15 | 5-20 |
| WTAverage | 21 | 25 | 10-30 |
| WTOBLevel | 53 | 80 | 40-80 |
| WTOSLevel | -53 | -80 | -80 to -40 |
| RSIPeriod | 14 | 14 | 7-21 |
| RSIOBLevel | 65 | 80 | 55-80 |
| RSIOSLevel | 35 | 25 | 20-45 |
| SL_Pips | 15 | 10 | 10-50 |
| TP_Pips | 30 | 35 | 10-60 |

## Metrics
- Total trades: 25
- EV per trade: $0.91
- Profit factor: 2.52
- Max drawdown: 0.08%
- Total net profit: $22.87
- Sharpe ratio: 16.93
- Recovery factor: 3.03

## Note
25 trades — fewest of all. Both WT and RSI pushed to extremes (80/-80).
Double filter narrows too much. FRAGILE.
