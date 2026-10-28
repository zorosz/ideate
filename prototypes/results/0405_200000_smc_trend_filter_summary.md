# Summary: smc_trend_filter

Baseline comparison: wt_crossover v2 (M10 confirm, no SMC filter) = 547 trades, PF 1.08, Sharpe 1.28

| Version | Params | Trades | Win% | EV | PF | MaxDD | Sharpe |
|---------|--------|--------|------|-------|------|-------|--------|
| v1 BOS filter | Default | 9 | 11.1% | -1.10 | 0.23 | 0.15% | -2.27 |
| v2 BOS+CHoCH | Default | 9 | 11.1% | -1.10 | 0.23 | 0.15% | -2.27 |
| v4 Opposing SL | Default | 716 | 23.3% | +0.05 | 1.09 | 0.44% | 1.58 |

## Analysis

**v1/v2: BOS direction filter kills the strategy.** Only 9 trades in 12 months.
On M1, SMC trend changes very frequently — by the time a BOS is confirmed and
a WT signal fires in the same direction, the opportunity is already passed.
The filter is too restrictive for this timeframe.

**v4: Opposing SL adjustment is the winner.** Takes all signals but uses
OpposingSLMult=0.5 (7.5 pip SL) for counter-structure trades vs 15 pip for
aligned trades. Results vs baseline:
- Trades: 716 vs 547 (more, because tight SL → faster position cycling)
- PF: 1.09 vs 1.08 (marginally better)
- Sharpe: 1.58 vs 1.28 (noticeably better risk-adjusted return)
- Avg loss: $0.79 vs $1.53 (47% smaller average loss)
- R:R: 3.76:1 vs 1.94:1 (nearly doubled)

The tight SL on counter-trend trades cuts losses fast. When the counter-trend
trade was wrong, loss is tiny. When it works, TP is the same $2.97.

**Optimization: no XML generated** — likely too many parameters for the genetic
algo to find robust positive passes, or ShutdownTerminal timing issue.

## Best for validation

**v4 default** — already improves Sharpe from 1.28 to 1.58 without optimization.
