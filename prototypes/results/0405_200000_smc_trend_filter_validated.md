# Validated: smc_trend_filter — v4 default (opposing SL adjustment)
Period: 2024.01.01-2026.01.01 (full 2 years)

## Metrics
- Total trades: 1287
- Win rate: 22.92%
- Avg win / Avg loss: $2.96 / $0.80
- R:R ratio: 3.70:1
- EV per trade: $0.03
- Profit factor: 1.05
- Max drawdown: 0.46%
- Total net profit: $44.29
- Sharpe ratio: 0.88
- Recovery factor: 0.97

## Year comparison (estimated)
| Year | Trades | Profit | PF | Sharpe |
|------|--------|--------|------|--------|
| 2024 | ~571 | ~$5.07 | ~1.01 | ~0.1 |
| 2025 | 716 | $39.22 | 1.09 | 1.58 |

## Comparison with wt_crossover v2 validated
| Metric | wt_crossover v2 | smc_trend_filter v4 |
|--------|----------------|---------------------|
| Trades | 958 | 1287 |
| PF | 1.09 | 1.05 |
| Sharpe | 1.21 | 0.88 |
| R:R | 1.94:1 | 3.70:1 |
| Avg loss | $1.53 | $0.80 |
| Net profit | $83.28 | $44.29 |

## Verdict
**WEAK**

The opposing SL adjustment produces a much better R:R (3.70:1 vs 1.94:1) and
smaller average losses ($0.80 vs $1.53). But the 2-year PF (1.05) is weaker
than the baseline (1.09), and 2024 was nearly flat. The improvement in Sharpe
seen in 2025 (1.58) didn't hold in 2024 (~0.1).

The concept of tighter SL on counter-structure trades has merit but needs
refinement — the 0.5x multiplier may be too aggressive, stopping out trades
that would have recovered.
