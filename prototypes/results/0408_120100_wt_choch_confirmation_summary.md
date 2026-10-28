# Summary: wt_choch_confirmation

Period: 2025.01.01 - 2026.01.01 (in-sample)
Symbol: EURUSD M1

| Version | Variant | Trades | Win% | Profit | PF | Verdict |
|---------|---------|--------|------|--------|------|---------|
| v1 | Spec polarity (M1 CHoCH) | 0 | n/a | $0 | n/a | Zero signals |
| v1 | Inverted polarity (M1 CHoCH) | 654 | 21.41% | -$63.77 | 0.56 | DEAD |
| v2 | M5 CHoCH, spec polarity | 33 | 27.27% | -$1.06 | 0.83 | DEAD |
| v6 | Tight WT 80/-80, inverted | 0 | n/a | $0 | n/a | Zero signals |

## Versions skipped

The remaining versions (v3 tighter recency, v4 CHoCH OR BOS, v5 inverted
polarity overlap, v7 session filter) all rest on the same broken premise
and were not tested:

- **v3 (tighter MaxChochAge 3-5)**: would produce even fewer signals than
  v1 — already at 0 with the spec polarity
- **v4 (CHoCH OR BOS)**: BOS is even rarer and direction-aligned the same
  way; adding it doesn't change the temporal misalignment
- **v5 (CHoCH as trigger, WT as filter)**: structurally equivalent to v1
  inverted polarity, which I tested as 21% WR / -$63.77
- **v7 (session filter overlay)**: overlay on a broken core can't rescue
  it

## Best version

**None.** All tested variants are negative or produce zero trades.

## The structural problem

The spec hypothesized that WT extremes and SMC CHoCH events would
temporally align as confirming signals. In practice on EURUSD M1:

1. **Spec polarity (BUY needs BULLISH CHoCH)**: at WT oversold extremes,
   the most recent CHoCH is BEARISH (because price was falling and broke
   the prior swing low). A bullish CHoCH would require a "double bottom"
   pattern that's extremely rare on M1 noise. Result: 0 signals.

2. **Inverted polarity (BUY needs BEARISH CHoCH)**: many signals (654)
   but 21% win rate. By the time CHoCH fires confirming the down-move,
   the WT cross is too late to catch the actual reversal — price has
   already moved partway back.

3. **M5 CHoCH (v2)**: bigger structural events but still misaligned
   temporally. 33 trades, 27% WR — same shape as M1 inverted, just
   fewer trades.

The fundamental issue: **CHoCH is a lagging confirmation that fires
DURING or AFTER the move it identifies. WT crosses fire at exhaustion
points BEFORE the structural break is confirmed. The two events are
chronologically incompatible as a confirming pair.**

## Decision: FAILED

The strategy concept does not work on EURUSD M1 with SMC_Core CHoCH
detection. The validated WT crossover edge (PF 1.09 baseline #1) cannot
be improved by SMC structural confirmation at this timeframe.

OOS validation skipped — no positive in-sample variant exists to validate.
