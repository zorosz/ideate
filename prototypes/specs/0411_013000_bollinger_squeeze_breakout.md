# Bollinger Squeeze Breakout

## Thesis

Volatility on EURUSD is mean-reverting. Periods of compression (low
Bollinger Band width, low ATR, narrow ranges) are followed by periods of
expansion (high band width, high ATR, wide ranges). This is one of the
most documented patterns in technical analysis: the squeeze precedes the
move.

When BB width contracts to a multi-bar minimum, the market is in
equilibrium — buyers and sellers have neutralized. When equilibrium
breaks, the pent-up imbalance releases as a directional move. Trading
the breakout direction from the squeeze captures the expansion.

The strategic role of this strategy in the EA is to provide a
MOMENTUM-CAPTURE component during periods when mean reversion is
structurally wrong. After a squeeze, the market expands; mean reversion
strategies will fade the expansion and lose. This strategy profits from
the same conditions that hurt the rest of the stack — natural hedge.

## Evidence

1. **Combined hedge strongest in 2023 trending year (#10)**: PF 1.54 in
   2023 (vs 1.19 in 2024). 2023 is the year with the most directional
   moves on EURUSD. A direct momentum strategy in trending years should
   profit even more than the hedge's indirect mechanism.

2. **All existing strategies are mean-reverting** — strategic gap. The
   absence of a momentum component means trending months are pure drag.
   This squeeze breakout is the simplest possible momentum trigger.

3. **Failed Asian Range Breakout (#2)**: ARB failed because it used
   TIME (Asian session) as the regime indicator. Asian session is not
   reliably "compression followed by expansion." This strategy uses
   VOLATILITY directly (BB width percentile), which is the actual
   regime indicator. Different mechanism, related thesis.

4. **DECISION 2026-04-07 — Symmetric hedge structurally unprofitable**:
   the hedge variants that don't capture directional movement lose
   money. Direct momentum should profit where directional capture is
   needed.

5. **Bollinger 1992** (Bollinger on Bollinger Bands, original
   publication): the squeeze is documented as a pre-expansion signal.
   Validated for decades on equity markets and FX.

6. **Project context — idle time between WT signals**: squeeze events
   happen 2-5 times per day on EURUSD M1. Trigger frequency is high
   enough to fill significant idle time without overwhelming the EA.

## Base (v1)

**Timeframe**: M1

**Squeeze detection** (every M1 bar):
- Compute BB(20, 2.0) on M1
- BBWidth = (UpperBand - LowerBand) in pips
- BBWidthMin = min(BBWidth) over last `LookbackBars` bars (default 100)
- Squeeze condition: `BBWidth <= BBWidthMin * 1.05` (within 5% of min)
- Track squeeze state: enter SQUEEZE when condition first met,
  exit SQUEEZE when BBWidth > BBWidthMin * 1.5

**Setup** (squeeze release):
- During SQUEEZE state, watch for breakout:
  - BUY if Close > UpperBand (cross above)
  - SELL if Close < LowerBand (cross below)
- Squeeze must have lasted at least `MinSqueezeBars` (default 5) before
  the breakout counts

**Entry**:
- Market entry on breakout bar close
- Single position, never both directions

**Exit**:
- TP: BB middle (20 SMA) + (`TPMultiplier` × ATR(14)) in trade direction
- SL: opposite BB band at entry time + (`SL_ATR` × ATR(14)) buffer
- Trail to breakeven after price moves `TrailTrigger` × ATR in profit

**Indicators**: Bollinger Bands (20, 2.0), ATR(14)

## v2: ADX confirmation

Same as v1 but require ADX(14) to rise above `ADX_Threshold` (default 25)
on the breakout bar — confirming directional strength.

**Why this might work**: ADX rising during a breakout confirms real
trend formation, not just a temporary spike. Filters out fake breakouts
where the market briefly pierces and returns.

**Why this might fail**: ADX is lagging. By the time it crosses 25, the
move may already be half-done. Entry quality may suffer despite higher
WR.

## v3: Tick volume spike

Same as v1 but require tick volume on the breakout bar to be above its
20-bar moving average by at least `VolumeMultiplier` (default 1.5x).

**Why this might work**: Real breakouts have participation. Volume
spike confirms institutional involvement, not just thin-market drift.

**Why this might fail**: M1 tick volume on EURUSD is unreliable. Spikes
may be noise. Filter may not actually distinguish real moves from
random.

## v4: Retest entry

Same as v1 but instead of entering on the breakout bar, wait for a
retest of the broken band. Enter on the retest bar if the band holds.

**Why this might work**: Retest entries have tighter stops and better
R:R. Most breakouts retest within 5-10 bars; trading the retest gets
in at a better price.

**Why this might fail**: Some breakouts don't retest. The strategy
misses the cleanest moves and only catches the messy ones. Reduces
sample size.

## v5: Skip Asian session

Same as v1 but skip the 00:00-08:00 CET window entirely (Asian session).

**Why this might work**: ARB failure (#2) showed Asian session
breakouts don't work. Filter explicitly excludes the regime where this
strategy fails. Targets only London + NY hours.

**Why this might fail**: Asian session squeezes are the cleanest
(narrowest BB widths). Excluding them removes the highest-confidence
setups. Only test if v1 shows Asian session as net loser.

## v6: ATR percentile instead of BB width

Same as v1 but use ATR percentile (current ATR vs prior 100 bars) as
the squeeze indicator instead of BB width.

**Why this might work**: ATR is a cleaner volatility measure (it
includes gaps and wicks). Percentile threshold is more interpretable
than "within 5% of min."

**Why this might fail**: ATR and BB width are highly correlated. Using
ATR doesn't add new information, just changes the metric. Performance
should be similar to v1.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: Direct counter-strategy. WT
  fades; this rides. Should produce OPPOSITE signals on breakout bars.
  May need explicit suppression of WT signals during active squeeze
  breakouts.

- **vs hedge accumulators (combined hedge #10)**: Combined hedge
  benefits from trending markets. This strategy explicitly captures
  trends. Could be complementary or could fight for the same alpha.
  Different magic numbers + parallel testing required.

- **vs Liquidity Sweep Reversal (sister)**: Sweep fades pierces; this
  rides breaks. They are direct opposites. The key question: is a
  pierce-of-swing-extreme the same event as a BB breakout? Sometimes
  yes (a sweep through a BB band edge is also a squeeze release). Need
  to verify they don't fire on opposite directions on the same bar.

- **vs NY Open Continuation (sister 0411_012700)**: Both are
  momentum-following. NY open is time-anchored; this is volatility-
  anchored. Should be uncorrelated in time. Together they form the
  EA's full momentum coverage.

- **vs Asian Range Scalp (sister 0411_012600)**: Range scalp profits
  inside Asian ranges; this profits from the BREAK of those ranges.
  Direct opposites. v5 explicitly avoids the Asian conflict.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `BB_Period` | 10-30 | 5 | Bollinger Band period |
| `BB_StdDev` | 1.5-2.5 | 0.25 | Bollinger Band standard deviations |
| `LookbackBars` | 50-200 | 25 | Squeeze min calculation lookback |
| `MinSqueezeBars` | 3-15 | 2 | Minimum bars in squeeze state |
| `TPMultiplier` | 1.0-3.0 | 0.5 | TP as ATR multiplier from middle BB |
| `SL_ATR` | 0.5-2.0 | 0.5 | SL ATR buffer |
| `TrailTrigger` | 0.5-2.0 | 0.5 | ATR multiplier for BE move |
| `ADX_Threshold` (v2) | 20-30 | 2 | ADX confirmation level |
| `VolumeMultiplier` (v3) | 1.2-2.5 | 0.25 | Volume spike threshold |

## Notes

**Market condition targeted**: Squeeze-then-expansion regime. Performance
should be best during HIGH-volatility-variance periods (markets that
alternate between calm and stormy). Should be worst in STEADY volatility
markets where squeezes either don't form or don't release.

**Risk profile**: Low-mid win rate (target 40-50%), high R:R (target
1.5-3:1). Trend-following has natural shape: many small losses, fewer
big wins.

**Critical: distinguish squeeze from quiet ranging**:
- A squeeze is BB width at multi-bar low THEN releasing
- A quiet range is BB width consistently low without release
- The strategy needs the RELEASE event, not just the compression

**Edge cases**:
1. **News during squeeze**: news creates a violent breakout. v1 catches
   it but exits at TP within minutes. NewsFreezeGuard may block entry —
   verify behavior.
2. **False breakout**: price breaks band, closes back inside next bar.
   v1 stops out. v4 retest version may avoid this.
3. **Squeeze during Asian session**: cleanest squeezes form here, but
   ARB lesson says Asian breakouts fail. v5 explicitly excludes.
4. **Spread spike at entry**: 5-pip spread on a 8-pip TP eats most of
   the profit. Add spread filter.

**Failure modes to watch**:
- WR < 30% → squeezes producing fakeouts; need ADX or volume filter
- Avg win < spread*3 → TP too tight, spread eating gains
- Profitable in 2023 only → trending regime dependent (acceptable for
  this strategy's role)
- Total trades > 500/year → trigger too loose, treating noise as squeezes

**Open question**: should the breakout direction be confirmed by the
PRIOR bar's close direction? E.g. only BUY if prior bar also closed
green. Adds a small confirmation filter.
