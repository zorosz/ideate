# Summary: impulse_fade

| Version | Params | Trades | Win% | EV | PF | MaxDD | Sharpe |
|---------|--------|--------|------|-------|------|-------|--------|
| v1 | Default | 2853 | 60.6% | -0.05 | 0.75 | 1.43% | -5.00 |
| v1 | Optimized | 171 | - | +0.07 | 1.18 | 0.16% | 4.53 |

## Analysis

**Default: clearly negative.** 2853 trades, 60.6% win rate but R:R is terrible (0.24 avg win / 0.41 avg loss = 0.58:1). The 38.2% retracement target with wide SL produces lots of small wins eaten by fewer larger losses.

**Optimization insight:** Only works with extreme impulses (4x ATR, rare events) and deeper retracement target (60%). This flipped PF to 1.18 but with only 171 trades. Only 1 of 3 top results was positive — the edge is barely there.

**Why it fails:** On M1, most "impulses" are just normal volatility noise. Even 2x ATR bars happen frequently and don't produce meaningful retracements. You need 4x ATR (major spikes) for the thesis to hold, but those are rare.

## Verdict

**FAILED** on defaults. Optimization found a narrow positive but fragile.

This thesis may work better on H1/H4 where impulse bars represent real institutional moves rather than M1 noise.
