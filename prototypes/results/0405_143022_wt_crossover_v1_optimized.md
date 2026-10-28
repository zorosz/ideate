# Result: wt_crossover — v1 optimized
Date: 2026-04-05
Period: 2025.01-2026.01
Passes: 269

## Parameters
| Parameter | Default | Optimized | Range |
|-----------|---------|-----------|-------|
| WTChannel | 10 | 15 | 5-20 |
| WTAverage | 21 | 30 | 10-30 |
| WTOBLevel | 53 | 70 | 40-80 |
| WTOSLevel | -53 | -70 | -80 to -40 |
| SL_Pips | 15 | 30 | 10-50 |
| TP_Pips | 30 | 10 | 10-60 |

## Metrics
- Total trades: 209
- Win rate: ~65% (inferred from PF/EV)
- EV per trade: $0.12
- Profit factor: 1.18
- Max drawdown: 0.30%
- Total net profit: $24.36
- Sharpe ratio: 3.17
- Recovery factor: 0.81

## Note
Optimizer flipped R:R to SL=30/TP=10 (scalp style, high win rate).
Alt #2 (SL=15/TP=50, 401 trades, PF=1.23) is more robust.
