# Summary: ob_rejection_scalp

| Version | Params | Trades | Win% | EV | PF | MaxDD | Sharpe |
|---------|--------|--------|------|-------|------|-------|--------|
| v1 | Default | 384 | 23.2% | +0.02 | 1.06 | 0.33% | 1.09 |
| v1 | Optimized | 19 | - | +0.53 | 2.14 | 0.09% | 9.62 |
| v2 (WT) | Default | 283 | 21.6% | -0.02 | 0.95 | 0.31% | -1.07 |

## Analysis

**v1 default is positive** — PF 1.06 with 384 trades. Unusual profile: 23% win rate but 3.7:1 R:R. The order block rejection concept works but most rejections fail (77% of touches break through). When they do reject, the move is large.

**v2 (WT confirmation) hurt** — adding WT filter reduced trades to 283 and flipped to negative. WT oversold/overbought doesn't align with zone rejection timing.

**Key optimization insight:** MaxZoneAgeBars=50 appeared in all top results — only very fresh zones (< 50 M1 bars = ~50 min) have real institutional backing. Default 200 bars lets in stale zones that pollute signals.

**Optimized is fragile** — 19 trades with narrow params.

## Verdict

**WEAK** — v1 shows a real edge (positive defaults, logical thesis) but too thin to trade standalone. The fresh-zone insight (MaxZoneAgeBars=50) is valuable for the main EA's SMC TP targeting too.

Not proceeding to full validation.
