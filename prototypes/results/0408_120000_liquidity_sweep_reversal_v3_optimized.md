# Result: liquidity_sweep_reversal — v3 optimized
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1
Optimization: genetic, criterion = Balance + PF max
Total passes: 196

## Best optimized parameters
| Parameter | Default | Optimized |
|-----------|---------|-----------|
| SessionStartHour | 15 | 11 |
| SessionEndHour | 20 | 18 |
| SwingLength | 20 | 20 (fixed) |
| MaxSwingAge | 30 | 30 (fixed) |
| MinPierceMult | 1.5 | 1.5 (fixed) |
| MaxBarsInTrade | 30 | 30 (fixed) |
| StopBufferPips | 2.0 | 2.0 (fixed) |

## Optimized metrics
- Total Net Profit: +$7.97
- Profit Factor: 1.42
- Sharpe Ratio: 23.86
- Total Trades: 71
- Equity DD: 0.035%

## Top 5 optimized session windows
| Rank | Profit | PF   | Sharpe | Trades | Start | End |
|------|--------|------|--------|--------|-------|-----|
| 1    | $7.97  | 1.42 | 23.86  | 71     | 11    | 18  |
| 2    | $7.57  | 1.52 | 28.68  | 59     | 11    | 17  |
| 3    | $6.83  | 1.29 | 17.18  | 85     | 8     | 18  |
| 4    | $6.43  | 1.30 | 17.45  | 78     | 10    | 18  |
| 5    | $6.43  | 1.33 | 19.63  | 73     | 8     | 17  |

## Comparison vs default
| Metric | Default (15-20) | Optimized (11-18) | Δ |
|--------|-----------------|--------------------|---|
| Profit | -$0.02   | +$7.97   | dramatic |
| PF     | 1.00     | 1.42     | +42% |
| Sharpe | -0.08    | 23.86    | dramatic |
| Trades | 56       | 71       | +27% |

## Sensitivity verdict
**SENSITIVE** — optimization improved EV substantially (~400%+).
Top 5 results all converge on similar window: start 8-11, end 17-18.
This is **London proper through London close** in broker time
(GMT+2/3 → ~9:00-16:00 GMT).

## Notes
- Default session (15-20) was wrong — that's NY proper, when sweeps
  are continuations not reversals
- Optimal window is London proper (8-11) through London close (17-18)
- The convergence of top 5 results adds confidence: ALL share the
  London pattern, not just the top one
- 71 trades is below ideal (100+ would be safer) but acceptable
- Equity DD remains trivial at 0.035%
- CONCERN: session windows discovered by optimization are inherently
  curve-fit risk. OOS validation is critical.
