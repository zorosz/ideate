# Summary: wt_crossover

| Version | Params | Trades | Win% | EV | PF | MaxDD | Sharpe | Sensitivity |
|---------|--------|--------|------|-------|------|-------|--------|-------------|
| v1 | Default | 965 | 35.9% | +0.05 | 1.05 | 0.59% | 0.81 | |
| v1 | Optimized | 209 | ~65% | +0.12 | 1.18 | 0.30% | 3.17 | Sensitive |
| v2 | Default | 547 | 36.6% | +0.08 | 1.08 | 0.44% | 1.28 | |
| v2 | Optimized | 28 | - | +0.44 | 2.53 | 0.04% | 28.64 | Fragile |
| v3 | Default | 432 | 35.7% | +0.04 | 1.04 | 0.61% | 0.67 | |
| v3 | Optimized | 34 | - | +1.41 | 1.97 | 0.19% | 6.76 | Fragile |
| v4 | Default | 820 | 35.9% | +0.05 | 1.05 | 0.71% | 0.78 | |
| v4 | Optimized | 25 | - | +0.91 | 2.52 | 0.08% | 16.93 | Fragile |

## Analysis

**Default winner: v2** (M10 confirmation) — best Sharpe (1.28), best PF (1.08), lowest DD (0.44%), best EV ($0.08). The M10 filter cuts trades from 965 to 547 while improving quality.

**Optimization reality check:** All versions went fragile under optimization. The optimizer narrowed trade counts to 25-34 by pushing OB/OS to 70-80. This is classic curve-fitting — finding a tiny pocket of lucky trades, not a robust edge.

**v1 optimized is the most honest** — 209 trades with modest improvement (Sharpe 0.81 → 3.17). But it achieved this by flipping to SL=30/TP=10 scalp style, which is a fundamentally different strategy.

**Key insight across all versions:**
- WT crossover at default levels (53/-53) generates ~2 trades/day with ~36% win rate and ~2:1 R:R
- The edge is real but thin (PF 1.04-1.08)
- M10 confirmation helps (v2 > v1 in defaults)
- RSI adds nothing meaningful (v4 ≈ v1 in defaults)
- Stronger levels (v3) just reduce trades without improving quality

## Best for validation

**v2 default** — most robust edge, best risk-adjusted return without optimization.
Validate with optimized M10 levels from optimization (OB=60, OS=-50) since those are the only parameters that stayed reasonable.
