# Result: liquidity_sweep_reversal — v1 optimized
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1
Optimization: genetic, criterion = Balance + PF max
Total passes: 162

## Best optimized (with min 50 trades filter)
| Parameter | Default | Optimized |
|-----------|---------|-----------|
| SwingLength | 20 | 20 |
| MaxSwingAge | 30 | 30 |
| MinPierceMult | 1.5 | 2.5 |
| MaxBarsInTrade | 30 | 60 |
| StopBufferPips | 2.0 | 5.0 |

## Optimized metrics
- Total Net Profit: +$0.19
- Profit Factor: 1.003
- Sharpe Ratio: 0.17
- Total Trades: 148
- Equity DD: 0.12%

## Comparison vs default
| Metric | Default | Optimized | Δ |
|--------|---------|-----------|---|
| Profit | +$2.43 | +$0.19 | -92% |
| PF     | 1.06   | 1.003 | -5% |
| Trades | 149    | 148   | flat |

## Sensitivity verdict
**ROBUST (negative)** — optimization could not improve on defaults.
Genetic search ran 162 passes; 89 had ≥50 trades; only 2 were profitable.
The single best overfit pass (Pass 155: PF 1.56) had only 5 trades —
clearly curve-fit and not statistically meaningful.

## Notes
- The strategy's parameters are essentially fixed: SwingLength=20,
  MaxSwingAge=30, MinPierceMult=1.5 are all near-optimal as-is
- Wider stops, longer time stops, or stricter pierce thresholds all hurt
- Default is the baseline — optimization yields no improvement
- Only 5-trade overfit pass beats baseline: NOT trustable
- The strategy is a marginal-edge "as designed" — not fragile but not
  improvable either
