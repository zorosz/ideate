# Tick Volume Climax Reversal

## Thesis

In FX, tick volume is the only volume proxy available — it counts the
number of price changes (ticks) per bar, not actual transaction
volume. While imperfect, tick volume correlates well with order flow
intensity on liquid pairs like EURUSD. When tick volume on a single M1
bar spikes to >2x its 20-bar moving average, the move is climactic:
panic positioning, stop cascades, or news reaction concentrated in 60
seconds.

Climaxes typically mark short-term reversal points. The participants
who needed to act NOW have acted. The remaining flow is mean-reverting
because the urgency has passed. Fading the close direction of a
climactic bar captures the immediate relief move.

This is fundamentally different from the validated WT edge: WT
measures price-derived momentum exhaustion, this measures activity-
derived exhaustion. Different signal source, potentially uncorrelated
in time. Fills the idle gap with a microstructure-anchored trigger.

## Evidence

1. **Order Block Rejection Scalp validated profile (#3)**: 23% WR /
   3.7:1 RR. Confirms that rare-but-extreme reversal patterns produce
   tradeable edge on EURUSD M1. Volume climax has the same statistical
   shape (rare, big-RR).

2. **WT divergence FAILED (#6)**: pure oscillator divergence is M1
   noise. **However**, divergence is price-vs-indicator. Volume
   climax is price-vs-activity, a different signal type. The failure
   of one doesn't invalidate the other.

3. **Impulse Fade FAILED (#4)**: random impulses on M1 are noise.
   But impulses with HIGH VOLUME are not random — they're concentrated
   activity events. Volume filter isolates the cases where Impulse Fade
   should have worked.

4. **Combined hedge generates 50K+ trades/year (#15)**: extreme volume
   bars are an underexplored event class. With ~390K M1 bars per year
   and ~2-5 climactic bars per day, there are 500-1500 setups per year.

5. **Wyckoff (1931) — "The Richard D. Wyckoff Method of Trading"**:
   classical TA literature on volume climax as reversal signal.
   Foundational concept in technical analysis.

6. **Lyons 2001 — "The Microstructure Approach to Exchange Rates"**:
   activity intensity (proxied by tick frequency in FX) corresponds to
   information arrival. Information-driven moves are followed by
   absorption phases.

## Base (v1)

**Timeframe**: M1

**Volume detection** (every M1 bar):
- TickVolume = `iVolume(_Symbol, PERIOD_M1, 1)` (last completed bar)
- AvgVolume = SMA of TickVolume over last `VolumeAvgBars` bars (default 20)
- Climax condition: `TickVolume >= AvgVolume * VolumeMultiplier`
  (default 2.0x)

**Setup**:
- Climax bar must close in a clear direction:
  - Bullish climax: close > open AND body > 60% of range
  - Bearish climax: close < open AND body > 60% of range
- Setup:
  - SELL on bullish climax (fade up move)
  - BUY on bearish climax (fade down move)

**Entry**:
- Market entry at next bar open (after climax bar closes)
- Single position, never both directions

**Exit**:
- TP: 50% retracement of climax bar's range from close
- SL: full climax bar range × `SL_Multiplier` (default 1.0) past entry
- Time stop: hard close after `MaxBarsInTrade` bars (default 30)

**Indicators**: None — pure tick volume

## v2: WaveTrend exhaustion confluence

Same as v1 but require WT in matching exhaustion zone on climax bar:
- SELL: `WT > +60`
- BUY: `WT < -60`

**Why this might work**: Combines volume climax (activity exhaustion)
with WT exhaustion (momentum exhaustion). Two independent confirmations
of the same underlying state.

**Why this might fail**: Volume climaxes can occur from neutral WT
states (e.g. on news). Filter may collapse signal frequency.

## v3: SMC zone confluence

Same as v1 but require an SMC swing high/low or order block within
`ZonePips` of the climax bar's extreme.

**Why this might work**: Confluence of climactic flow + structural
level = high-conviction reversal. The level provides the absorption;
the volume confirms the urgency.

**Why this might fail**: SMC detection on M1 is noisy. May not add
real filtering value.

## v4: Sequential climax (climax zone)

Same as v1 but require 2-3 consecutive bars of high volume (not just
one). This is "climax zone" instead of "climax bar."

**Why this might work**: Multiple consecutive high-volume bars
indicate sustained urgency, not random spikes. Reversal after a
multi-bar climax is more reliable than after a single bar.

**Why this might fail**: Reduces frequency. By the time the third
high-volume bar closes, the move is too extended for a clean fade.

## v5: NY session only (where tick volume matters most)

Same as v1 but only trade between 15:30 and 22:00 CET.

**Why this might work**: NY session has the highest tick activity
(real volume is concentrated here). Tick volume signals are most
meaningful when transactions are dense. Asian session tick volume is
unreliable.

**Why this might fail**: Most volume climaxes happen during news
events, which can be at any time (e.g. CPI at 14:30 CET, before NY
open). Filtering by session may exclude the best setups.

## v6: Reversal candle pattern + volume

Same as v1 but the climax bar must ALSO be a reversal candle pattern:
- Bullish climax + bearish engulfing or shooting star → SELL
- Bearish climax + bullish engulfing or hammer → BUY

**Why this might work**: Pattern + volume is the classical "smart
money" reversal signature. Wyckoff documented this combination as the
strongest reversal signal.

**Why this might fail**: Adds price-action complexity. Patterns are
subjective on M1 noise. Filter may collapse signal frequency.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: Different trigger family
  (volume vs oscillator). Should be uncorrelated in time. v2 explicitly
  combines them.

- **vs Liquidity Sweep Reversal (sister)**: Sweep targets pierces of
  swings; this targets activity climaxes. Different triggers but both
  fade rapid moves. Some overlap on bars where both fire (sweep +
  high volume = strong confluence).

- **vs Order Block Rejection Scalp (#3)**: Both target rare/extreme
  reversal events. v3 explicitly combines volume climax + SMC zones.

- **vs News Volatility Fade (sister 0411_013200)**: News fade waits
  30-90 min after release. Volume climax can fire DURING the news
  spike (climax bar + reversal). Different timing windows for the
  same underlying event.

- **vs Bollinger Squeeze Breakout (sister 0411_013000)**: Squeeze
  breakout RIDES expansion; volume climax FADES extreme expansion.
  They are sequential — squeeze break starts the move, climax
  reverses it. Could potentially run together with different magic
  numbers.

- **vs hedge accumulators**: No conflict. Different magic.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `VolumeAvgBars` | 10-40 | 5 | Volume MA period |
| `VolumeMultiplier` | 1.5-3.5 | 0.25 | Climax threshold |
| `BodyRatio` | 0.4-0.8 | 0.1 | Body % of range required |
| `RetracementTP` | 0.3-0.7 | 0.1 | TP as fraction of climax range |
| `SL_Multiplier` | 0.8-1.5 | 0.1 | SL relative to climax range |
| `MaxBarsInTrade` | 15-60 | 15 | Time stop |
| `ZonePips` (v3) | 3-15 | 2 | SMC confluence distance |
| `ConsecutiveBars` (v4) | 2-4 | 1 | Sequential climax bars |

## Notes

**Market condition targeted**: All sessions where tick volume is
reliable (London + NY primarily). Should DEGRADE in Asian session
where tick volume is sparse and noisy. Should EXCEL during news-
adjacent periods.

**Risk profile**: Low-mid win rate (target 35-50%), high R:R (target
1.5-2.5:1). Climax fades are similar to OBR profile — fewer winners,
bigger when right.

**Critical: tick volume is NOT real volume**:
- It's a count of ticks (price changes), not contracts
- Reliability varies by broker and session
- May spike on connectivity issues, not market activity
- Validate with multiple brokers' data if possible

**Edge cases**:
1. **News-driven climax**: NewsFreezeGuard may block entry during
   freeze. Strategy will only fire on climaxes OUTSIDE news windows
   (correct behavior).
2. **Spread spike masquerading as climax**: spread spikes increase
   tick count without real activity. Filter by checking tick count vs
   price range — true climaxes have wide ranges, fake climaxes have
   narrow ranges.
3. **Multi-bar climaxes**: when 5 bars all have high volume, only
   the FIRST gets the trade (avoid stacking). v4 handles this
   explicitly.
4. **Friday afternoon**: low tick activity, climax threshold rarely
   met. Strategy naturally silent — may be a feature, not a bug.

**Failure modes to watch**:
- WR < 30% → climax bars are continuations, not reversals (regime
  mismatch)
- Avg loss > 2× avg win → SL too tight or wrong (climax range × 1.0
  may be insufficient)
- Profitable only in volatile months → volume climax is regime-
  dependent
- Total trades < 100/year → multiplier too high, too few qualifying
  bars
- Total trades > 1500/year → multiplier too low, treating noise as
  climax

**Validation note**: tick volume backtest results may not match
forward performance due to broker tick differences. Always validate
with FORWARD test on demo before deploying. The strategy is
particularly sensitive to broker quality.
