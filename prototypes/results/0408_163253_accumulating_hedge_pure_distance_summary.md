# Summary: accumulating_hedge_pure_distance

## All versions — default vs optimized

| Version | Params | Trades | Win% | EV | PF | Sharpe | MaxDD | Sensitivity |
|---------|--------|--------|------|------|------|--------|-------|-------------|
| v1 H100,B10 | Default | 209 | 64.6% | -1.85 | 0.71 | -0.49 | 10.0% | |
| v1 | Opt H30,B40,M20 | 1897 | — | +1.78 | 2.34 | 1.32 | 12.2% | Fragile |
| v2 H50,B10 | Default | 763 | 71.7% | +0.52 | 1.20 | 0.32 | 10.1% | |
| v2 | Opt H60,B90,M5 | 469 | — | +2.19 | 1.92 | 1.37 | 4.9% | Sensitive |
| v3 H150,B10 | Default | 96 | 59.4% | -6.47 | 0.49 | -0.94 | 10.0% | |
| v3 | Opt H30,B40,M20 | 1897 | — | +1.78 | 2.34 | 1.32 | 12.2% | Fragile |
| v4 H100,B50 | Default | 197 | 68.5% | -1.40 | 0.79 | -0.43 | 10.1% | |
| v4 | Opt H30,B25,M15 | 1934 | — | +1.65 | 2.28 | 1.24 | 13.0% | Fragile |
| v5 H100,noBatch | Default | 166 | 65.1% | -2.81 | 0.77 | -0.72 | 11.0% | |
| v5 | Opt H40,M5 | 968 | — | -0.19 | 0.97 | -0.26 | 4.7% | N/A (losing) |

## Best: v2 optimized (EV = +2.19)

Parameters: HarvestPips=60, BatchClosePips=90, MaxFloatingLossPct=5

v2 wins on risk-adjusted metrics:
- Highest EV per trade ($2.19)
- Highest Sharpe ratio (1.37)
- Lowest max drawdown (4.89%)
- Strong recovery factor (2.04)

## Key findings

1. **Harvest distance is the dominant parameter.** Tighter harvest (30-60 pips) consistently
   outperforms wider (100-200). The optimizer pushed every version toward the minimum.

2. **Batch close threshold matters more than expected.** High BatchClosePips (40-90) works
   better than low (10). Waiting for a bigger reversal before batch-closing avoids premature
   exits that lock in losses.

3. **v5 proves batch close is essential.** Without it, the accumulated losing side has no
   exit mechanism. Even optimized, v5 never turns profitable.

4. **v1/v3/v4 are Fragile** — defaults lose money, optimization saves them. Only v2 is
   naturally close to its optimum.

5. **All batch-close versions converge to H=30.** The range minimum (30) is the best,
   suggesting even tighter harvest could work. This is a sign to test H=10-30 in a future spec.

Sensitivity guide:
- Robust: optimization improved EV < 50% — defaults are good
- Sensitive: optimization improved EV 50-200% — needs specific params
- Fragile: optimization improved EV > 200% — likely overfitting
