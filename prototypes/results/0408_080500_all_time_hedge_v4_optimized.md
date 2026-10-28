# Result: all_time_hedge — v4 optimized
Date: 2026-04-08
Period: 2025.01-2026.01

## Parameters
| Parameter | Default | Optimized | Range |
|-----------|---------|-----------|-------|
| HarvestPips | 30 | 45 | 10-50 |
| WTChannel | 10 | 15 | 5-20 |
| WTAverage | 21 | 10 | 5-30 |
| WTOBLevel | 53 | 70 | 50-80 |
| WTOSLevel | -53 | -50 | -80--50 |
| MaxFloatingLossPct | 10 | 15 | 5-20 |

## Metrics
- Total trades: 1109
- EV per trade: $0.06
- Profit factor: 1.04
- Total net profit: $67
- Sharpe ratio: 4.42
- Equity DD max: 0.36%

## Notes
Near-zero profit. WT filter too aggressive — filters out nearly all batch close signals.
