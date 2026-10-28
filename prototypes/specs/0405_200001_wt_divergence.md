# WaveTrend Divergence Entry

## Thesis
The current EA enters on WT crossover — when wt1 crosses wt2 in an extreme zone.
But by the time the cross happens, the reversal is already underway and price has
moved off the extreme. Divergence (price makes a new extreme while WT makes a
LESS extreme reading) detects the turn BEFORE the cross, giving a better entry
price. The microstructure: divergence occurs when large participants begin
unwinding (reducing momentum) while price is still being pushed by smaller
participants who haven't yet noticed. The momentum loss IS the institutional
signal — it precedes the price turn by several bars.

## Evidence
- **Current EA profile: 15.5% win rate, 6.4:1 R:R** — the win rate suggests
  we're entering too late. By the time WT crosses, the reversal window is narrow.
  Earlier entry (divergence) would widen the window and potentially improve win rate.
- **M10 confirmation was the best filter found** — it works because it captures
  higher-TF momentum context. Divergence serves a similar role but on the M1 chart
  itself — it shows that the current M1 momentum wave is weaker than the previous
  one, regardless of M10.
- **Impulse fade failed on raw impulse detection (PF 0.75)** — but its thesis
  (momentum exhaustion → reversal) is sound. The problem was using ATR bar size
  as the exhaustion signal, which is too crude. WT divergence is a much more
  precise exhaustion signal — it measures the actual oscillator momentum, not
  just candle size.
- **OB rejection: 23% win rate, 3.7:1 R:R** — showed that early entry (wick
  into zone) works conceptually but needs a confirmation signal. Divergence could
  be that confirmation: "price reached the zone AND momentum is exhausting."

## Base (v1): Classic divergence
Timeframe: M1
Divergence detection: Compare the last 2 WT extremes (swing lows in wt1 for
bullish, swing highs for bearish) against the corresponding price extremes.
Entry buy: Price made a lower low but wt1 made a higher low (bullish divergence),
AND wt1 is below -30 (still in oversold territory)
Entry sell: Price made a higher high but wt1 made a lower high (bearish divergence),
AND wt1 is above 30 (still in overbought territory)
Exit: ATR SL (same as main EA), SMC zone TP (same as main EA)
Indicators: WaveTrend.mqh (track last 2 wt1 extremes and corresponding price levels)
Lookback: detect divergence within last 20 bars

## v2: Divergence triggers, cross confirms
Don't enter immediately on divergence detection. Instead, set a "divergence flag"
and wait for the WT cross (wt1 crosses wt2) that follows. Enter on the cross.
This is like the current EA but only takes crosses that were preceded by divergence.
Why this might work: Best of both worlds — divergence ensures momentum exhaustion,
cross ensures the actual reversal has started. Filters out crosses that happen
without divergence (just oscillation, not exhaustion).
Why this might fail: Adding the divergence requirement on top of the cross
significantly reduces trade count. If the current 251 trades/year drops to <50,
the edge can't be measured.

## v3: Divergence + M10 confirmation
Same as v1 (enter on divergence directly), but add the M10 WT confirmation
filter from the validated v2 prototype (M10 wt1 must be in matching zone).
Why this might work: M10 confirmation was the single best filter in all testing.
Divergence gives timing, M10 gives directional bias. Together they answer
"is the turn real?" (divergence) and "does the bigger picture agree?" (M10).
Why this might fail: Double filter on top of divergence may leave too few trades.

## v4: Divergence at SMC zones only
Same as v1, but only take divergence signals when price is AT or INSIDE an
SMC order block. Divergence in open space is less meaningful — divergence at
a structural level means institutional orders ARE present AND momentum is fading.
Why this might work: This is the OB rejection idea (PF 1.06) combined with
a better timing signal (divergence instead of raw wick). The prototype showed
OB rejection has an edge; this should amplify it with better entry timing.
Why this might fail: Requiring price to be at an SMC zone AND show divergence
is extremely restrictive. Might produce <10 trades/year, which is untestable.

## v5: Hidden divergence (trend continuation)
Regular divergence catches reversals. Hidden divergence catches trend continuations:
- Bullish hidden: price makes higher low, wt1 makes lower low → uptrend continues
- Bearish hidden: price makes lower high, wt1 makes higher high → downtrend continues
This would complement the current mean reversion by adding a TREND entry type.
Why this might work: Hidden divergence is the "smart money accumulating during
a pullback" signal. It could capture the trend-following trades the EA currently
misses. Aligns with ROADMAP M2 (trend following).
Why this might fail: On M1, distinguishing hidden divergence from regular
divergence is hard — the oscillator noise makes both look similar. Also, the
exit logic (SMC zone TP) may not suit trend trades well.

## v6: Divergence strength scoring
Instead of binary divergence (yes/no), score the divergence by how much WT
diverged from price. Larger divergence = stronger signal = enter with normal
size. Small divergence = weaker signal = skip or enter with half size.
Score = abs(WT swing difference) / abs(price swing difference)
Why this might work: Not all divergences are equal. A huge price drop with
a barely lower WT dip is much stronger than a marginal divergence.
Why this might fail: Adding a continuous score adds a parameter (threshold)
that risks overfitting. Binary is simpler and the prototype testing showed
that simple beats complex on M1.

## Interaction with existing strategies
Divergence entry is a REPLACEMENT or COMPLEMENT to the current WT cross entry.
Options:
A) Replace: remove WT cross, use only divergence
B) Complement: enter on whichever fires first (divergence OR cross)
C) Filter: only take crosses preceded by divergence (v2)

Option C is safest — it doesn't change the existing strategy, just adds a
pre-condition. If it reduces trade count too much, fall back to option B.

Implementation needs:
- Track last 2 WT wt1 local minima and maxima (new state variables)
- Track corresponding price levels at those WT extremes
- Compare to detect divergence pattern
- ~20-30 lines of new code in a helper function

## Optimize
- WT zone threshold for divergence: -20, -30, -40 (buy), 20, 30, 40 (sell)
- Lookback window for swing comparison: 10, 20, 30, 50 bars
- Min WT divergence amount: 0 (any), 5, 10 (wt1 units)
- Entry mode: on divergence (v1), on cross after divergence (v2)
- M10 confirmation: yes/no (v3)
- SMC zone requirement: yes/no (v4)

## Notes
The divergence approach directly addresses the EA's main weakness: 15.5% win
rate. By entering earlier (before the cross), we get a better price, which means:
- The stop distance from entry to SL is potentially smaller
- The distance to TP is potentially larger
- Both effects improve R:R and could push win rate up

The risk is that divergence on M1 produces false signals — price can show
divergence and then continue in the original direction for many bars before
actually reversing. The extreme-zone requirement (wt1 < -30) mitigates this
by ensuring we only look for divergence when WT is already overextended.
