# Summary: wt_divergence

Baseline: wt_crossover v2 (M10 confirm) = 547 trades, PF 1.08, Sharpe 1.28

| Version | Params | Trades | Win% | EV | PF | MaxDD | Sharpe |
|---------|--------|--------|------|-------|------|-------|--------|
| v1 Raw divergence | Default | 1094 | 35.4% | +0.03 | 1.03 | 0.83% | 0.46 |
| v2 Div + cross | Default | 381 | 33.9% | -0.04 | 0.96 | 0.50% | -0.64 |

## Analysis

**v1: positive but weaker than baseline.** 1094 trades (2x more than baseline)
but PF 1.03 vs 1.08 and Sharpe 0.46 vs 1.28. Divergence produces more signals
but lower quality — many M1 divergence patterns are noise that doesn't lead to
actual reversals.

**v2: negative.** Requiring both divergence AND cross was supposed to produce
the highest-quality signals. Instead, the double filter selected for the worst
subset — by the time divergence forms AND the cross happens, the reversal
window has often already passed.

**Why divergence underperforms on M1:** On M1, WT oscillates rapidly, producing
many local troughs/peaks. A "divergence" between two adjacent troughs (20 bars
apart = 20 minutes) doesn't reflect real momentum exhaustion — it's just normal
oscillation. The crossover, despite being a "lagging" signal, is actually more
reliable because it requires WT to reach an extreme zone AND reverse, which
filters out the noise that divergence doesn't.

## Verdict

**FAILED** — divergence does not improve on the WT crossover signal at M1.
Not proceeding to optimization or validation.
