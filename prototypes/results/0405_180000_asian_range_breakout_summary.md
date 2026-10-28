# Summary: asian_range_breakout

| Version | Params | Trades | Win% | EV | PF | MaxDD | Sharpe |
|---------|--------|--------|------|-------|------|-------|--------|
| v1 | Default | 79 | 36.7% | -0.30 | 0.81 | 0.39% | -2.81 |
| v1 | Optimized | 99 | - | +0.16 | 1.14 | 0.19% | 2.36 |
| v2 (WT) | Default | 79 | 36.7% | -0.30 | 0.81 | 0.39% | -2.80 |
| v4 (range) | Default | 54 | 37.0% | -0.29 | 0.82 | 0.30% | -2.23 |

## Analysis

**Defaults: all negative.** The Asian range breakout at 07:00 UTC doesn't work on EURUSD.

**Optimization insight:** Shifting to AsianEnd=08:00, LondonEnd=10:00, Buffer=5 pips flipped it positive (PF 1.14). This suggests the real breakout happens later — possibly after the Frankfurt pre-open (07:00-08:00) absorbs initial Asian flow, and the real London move starts at 08:00-10:00.

**WT filter (v2) useless** — identical results to v1. The breakout is momentum-driven; WT oscillator adds nothing in this context.

**Range filter (v4)** marginally better but still negative with defaults.

## Verdict

**FAILED** on defaults. Optimization found a marginal edge with shifted hours but too thin to validate. The thesis (Asian range → London breakout) may hold on higher timeframes (H1/H4) but not M1.

Not proceeding to full validation.
