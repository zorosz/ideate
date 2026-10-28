# WaveTrend + CHoCH Confirmation

## Thesis

The validated WaveTrend mean-reversion edge (PF 1.09 with M10 confirmation) is
a TIMING signal — it tells you WHEN the oscillator is exhausted but says
nothing about whether the underlying market structure is shifting. Adding
structure as confirmation should improve win rate. But the BOS (Break of
Structure) filter has already been tested and failed: too restrictive, only
~9 trades over a year, well into overfitting territory.

CHoCH (Change of Character) is the smaller cousin of BOS in SMC theory: it
fires when price breaks the most recent counter-trend swing, signaling that
immediate momentum has changed even though the larger trend hasn't yet
broken. CHoCH is therefore:

1. **More frequent than BOS** — more signals, less risk of statistical noise
2. **Earlier than BOS** — catches reversals at first sign of weakness
3. **Still structural** — filters out random WT noise unlike pure oscillator
   confluence

The hypothesis is that **WT + CHoCH lands in the sweet spot between "WT alone"
(validated but PF 1.09) and "WT + BOS" (over-filtered to statistical
irrelevance)**. We are explicitly searching for the loosest valid structural
filter.

## Evidence

1. **WT crossover with M10 confirmation validated (#1 in IDEAS.md)**: PF 1.09.
   This is the baseline we are trying to improve. Any new variant must beat
   1.09 PF AND retain at least ~50% of the trade count to claim improvement.

2. **BOS direction filter failed (#5 v1/v2)**: ~9 trades over a year. The
   diagnosis was that BOS events are too rare on M1 to be a useful filter.
   CHoCH events should be 3-10× more frequent because they fire on smaller
   swings.

3. **Key Learning #1: M10 confirmation is the most valuable filter**:
   Cross-timeframe agreement matters. CHoCH on M5 or M10 should fire more
   often than BOS on the same timeframe AND provide similar structural
   confirmation value.

4. **SMC_Core already detects CHoCH**: `SStructureBreak` struct in
   `Include/SMC_Core.mqh` has an `isChoch` boolean flag. The detection logic
   is implemented; only the filter usage needs to be added. Zero
   infrastructure cost.

5. **DECISION 2026-04-05: Do NOT add RSI** (DECISIONS.md): The principle is
   "don't pile filters on top of filters that detect the same thing." RSI is
   redundant with WT. CHoCH is a different category — structural, not
   oscillator — so the principle does not apply against it. The principle
   actually argues FOR diverse filter types.

6. **SMC Trend Filter weak/conditional (#7)**: Trend-direction filtering
   produced inconsistent results. CHoCH is event-based, not trend-based — it
   detects shifts, not direction. Different angle, different test.

7. **DECISION 2026-04-05: Zone age filter validated for entries**: Recency
   of structural events matters. Apply same principle to CHoCH: prefer
   recent CHoCH events over stale ones. This becomes a key parameter.

8. **Key Learning #4: Fresh SMC zones matter**: Same lesson, applied to
   CHoCH events. Stale CHoCH is no longer informative.

## Base (v1)

**Timeframe**: M1 entries, M1 CHoCH detection

**Setup**:
- WaveTrend cross from oversold (`WT < -WT_OS`) → potential BUY
- WaveTrend cross from overbought (`WT > +WT_OB`) → potential SELL

**Confirmation**:
- Most recent CHoCH event (from `SMC_DetectStructureBreak` with
  `isChoch=true`) must agree with WT signal direction:
  - BUY signal: most recent CHoCH must be BULLISH (broke a down-swing high)
  - SELL signal: most recent CHoCH must be BEARISH (broke an up-swing low)
- CHoCH must be within last `MaxChochAge` bars (recency filter)

**Entry**:
- Market entry at WT cross bar close
- One position max per direction
- Max 2 concurrent positions total (project rule)

**Exit**:
- SL: ATR(14) * `SL_Mult` from entry
- TP: ATR(14) * `TP_Mult` from entry
- Move SL to break-even after price moves ATR(14) * `TrailTrigger` in profit

**Indicators**: WaveTrend, SMC_Core (CHoCH detection via SStructureBreak),
ATR(14), ND_Proto utilities

## v2: CHoCH on M5 timeframe

Same as v1 but CHoCH detection runs on M5 chart (cross-timeframe filter)
instead of M1.

**Why this might work**: M5 CHoCH is more meaningful than M1 CHoCH (less
noise, larger swings). Aligns with key learning #1 ("M10 confirmation is
the most valuable filter") by introducing higher-TF structure agreement.
This is the version most likely to succeed if M1 CHoCH is too noisy.

**Why this might fail**: M5 CHoCH may still be too rare on EURUSD — could
recreate the same overfitting problem as BOS on M1. The point of choosing
CHoCH over BOS is frequency; if we lose that on M5, we've gained nothing.

## v3: Tighter recency filter

Same as v1 but `MaxChochAge` is much tighter (3-5 bars instead of 10-20).

**Why this might work**: A CHoCH from 20 bars ago is no longer a confirming
event for a CURRENT WT cross — too much price action has happened in
between. Recency matters most for momentum signals because the structural
shift has either resolved or been invalidated.

**Why this might fail**: 5 bars on M1 = 5 minutes. Most WT crosses won't
have a CHoCH that recent. Could collapse signal frequency to near-zero,
recreating the BOS-filter problem in a different way.

## v4: CHoCH OR BOS (whichever comes first)

Same as v1 but accept either CHoCH or BOS in the agreed direction. Track
which type triggered each entry (in trade comment) for post-test analysis.

**Why this might work**: BOS is rarer but structurally stronger; CHoCH is
more frequent but weaker. Combined, they cover the full range of
structural confirmations and may produce a richer signal set than either
alone.

**Why this might fail**: We may be back to a "loose OR" filter that just
re-introduces the WT-alone behavior with extra logging. To rule this out,
the post-test analysis must verify that BOTH types contributed
non-trivially to the trade count and PnL.

## v5: WT exhaustion zone (no cross required) + CHoCH as trigger

Inverts the polarity: WT must be in exhaustion zone (`< -WT_OS` or
`> +WT_OB`) when a CHoCH fires. CHoCH is the trigger event; WT is the
filter.

**Why this might work**: CHoCH is the structural confirmation, so it
should be the trigger, not just a filter. Using CHoCH as the filter and WT
cross as the trigger inverts the natural sequence. This version corrects
the polarity: structure leads, oscillator confirms.

**Why this might fail**: Without a WT cross, you may enter in the middle of
a continuation, not a reversal. WT cross is the actual reversal moment. If
you enter on CHoCH while WT is exhausted but not crossing, you might be
catching a temporary pause inside a strong move.

## v6: Tighter WT thresholds + CHoCH

Same as v1 but with extreme WT thresholds (`WT_OB = 80`, `WT_OS = -80`).

**Why this might work**: Tightening WT thresholds isolates the most extreme
exhaustion moments. Combined with CHoCH structural shift, this should be
a very high-conviction entry. Trades should be rare but high quality.

**Why this might fail**: We're stacking two restrictive filters, which is
exactly what created the WT+BOS overfit problem. May collapse to single
digit trades per year.

## v7: Session filter overlay

Same as v1 but only trade during 17:00-22:00 CEST.

**Why this might work**: Sample size for CHoCH events on M1 is high enough
that session filtering still leaves enough signals. Quality during NY
overlap is highest. Aligns with project's strongest session.

**Why this might fail**: We may be filtering away valid morning London
signals. Asian session has low volatility anyway, so the real cost is
~3-4 hours of London-only time being removed.

## Interaction with existing strategies

- **vs baseline WT mean reversion**: This IS the baseline + a structural
  filter. By design, it should produce a SUBSET of WT signals with higher
  win rate. The signal frequency drop is the key risk to monitor.

- **vs WT + BOS filter (failed #5)**: This is the looser-confirmation cousin
  of the failed BOS filter. The hypothesis is that loosening from BOS to
  CHoCH lands above the overfit threshold while still adding value over
  raw WT. Direct comparison required.

- **vs Liquidity Sweep Reversal (sister idea, 0408_120000)**: Different
  signal source entirely (oscillator-driven vs structural-driven). Should
  be uncorrelated in time. Both could run side by side with different
  magic numbers, doubling the EA's active hours.

- **vs hedge accumulators (multi-pair, dynamic lots, all_time_hedge)**:
  Different magic, different trigger family. No conflict.

- **vs Order Block Rejection Scalp (#3)**: OBR uses zones as the trigger;
  this uses CHoCH as the filter and WT cross as the trigger. Different
  enough to coexist, similar enough to potentially overlap on rare bars
  (an OBR setup AND a WT cross AND a CHoCH all aligned would be the
  highest-conviction signal in the entire system).

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `WT_OB` | 50-70 | 5 | Overbought threshold |
| `WT_OS` | -70 to -50 | 5 | Oversold threshold |
| `MaxChochAge` | 3-30 | 3 | CHoCH recency in bars |
| `ATR_Period` | 7-21 | 7 | ATR for SL/TP |
| `SL_Mult` | 1.0-2.5 | 0.5 | ATR SL multiplier |
| `TP_Mult` | 1.5-4.0 | 0.5 | ATR TP multiplier |
| `TrailTrigger` | 0.5-2.0 | 0.5 | ATR multiplier for BE move |
| `ChochTimeframe` (v2) | M5/M10/M15 | — | Cross-TF CHoCH source |

## Notes

**Market condition targeted**: Mean-reverting and consolidating markets where
WT exhaustion is reliable. Filter explicitly avoids trades when structure is
silent (no recent CHoCH), reducing exposure during low-information ranges.

**Risk profile**: Mid win rate (target 50-55%), modest R:R (target 1.5-2:1).
Should produce smoother equity curve than v1 baseline IF hypothesis holds.

**Critical comparisons** (after each version's backtest):
- Trade count vs WT-alone baseline (#1)
- Trade count vs WT+BOS baseline (#5)
- PF improvement over WT-alone
- Whether the improvement comes from filtering OUT losers (WR up, avg win
  flat) or filtering IN winners (avg win up, WR flat) — diagnostic for
  whether the filter is real or noise

**Failure modes to watch**:
- Trade count < 50/year → over-filtering, same problem as BOS — this version
  fails the "frequency" hypothesis that motivated the whole idea
- Trade count > 200/year → CHoCH detection is too noisy on M1, no meaningful
  filter applied — falls back to WT-alone behavior
- PF improves < 5% over WT-alone → CHoCH adds nothing real, abandon the line
- PF improves > 30% over WT-alone → suspicious, check for overfitting on the
  in-sample period; extra OOS validation required before deployment

**Edge cases**:
1. Multiple CHoCH in opposing directions in quick succession — accept the
   most recent one only.
2. CHoCH and WT cross on the SAME bar — process both, allow entry. This is
   the cleanest possible signal.
3. CHoCH from a different timeframe (v2) — synchronize timestamps carefully
   to avoid look-ahead bias. Always evaluate M5 CHoCH on COMPLETED M5 bars
   only (`iBars(_Symbol, PERIOD_M5)` previous bar, never current).

**Open questions for prototype phase**:
- Does v1 (M1 CHoCH) or v2 (M5 CHoCH) perform better? Hypothesis: v2 wins
  because M5 structure is more meaningful, but v1 wins on frequency.
- Is the inverted polarity in v5 actually a different strategy or just the
  same trades in a different order? Check trade overlap with v1.
- Should we promote the BEST version to a dedicated EA, or merge into
  new_dawn as an additional signal source?

**Compatibility note**: The existing `new_dawn.mq5` uses BB+RSI as its
mean-reversion stack, not WaveTrend. WaveTrend is the prototype-validated
edge but lives in `WaveTrend.mqh` and is used in `Include/MultiStrategy/`.
This spec uses WaveTrend (the edge), not BB+RSI (the current production
stack). Decision deferred until validation.
