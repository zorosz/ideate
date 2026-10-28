# Impulse Fade

## Thesis
After a sharp directional impulse (BOS candle or news spike), price almost
always retraces 38-50% of the move before deciding on continuation or reversal.
This retracement happens because aggressive participants take profit and
counter-trend limit orders get filled at institutional levels. The current mean
reversion strategy avoids these spikes (WT gets pinned at extremes). This
strategy specifically targets the aftermath — fading the impulse once it
exhausts, using the retracement as a high-probability scalp.

## Base (v1)
Timeframe: M1
Impulse detection: A single bar where |close - open| > 2.0x ATR(14).
Entry buy (fade down-impulse): After a bearish impulse bar, wait for price
to stop making new lows for 3 bars, then buy. SL below impulse low.
TP at 38.2% retracement of impulse (measured from impulse high to low).
Entry sell (fade up-impulse): After a bullish impulse bar, wait for price
to stop making new highs for 3 bars, then sell. SL above impulse high.
TP at 38.2% retracement of impulse (measured from impulse low to high).
Indicators: ATR(14) for impulse detection. Pure price action for entry.
Max 1 fade per impulse (don't re-enter if stopped out).

## v2: Deeper retracement target
Same as v1, but TP at 50% retracement instead of 38.2%.
Wider target means fewer winners but larger per-trade profit.
Also tighten SL to 1 pip beyond impulse extreme (instead of full candle).

## v3: WaveTrend divergence confirmation
Same as v1, but require WT to show divergence after the impulse:
Price makes new extreme but WT doesn't = momentum exhaustion confirmed.
This filters out impulses that are the START of a trend (continuation)
vs impulses that are blow-off tops/bottoms (fadeable).

## v4: SMC zone confluence
Same as v1, but only fade impulses that terminate at or near an SMC zone.
Impulse into demand zone + exhaustion = high-confidence buy fade.
Impulse into supply zone + exhaustion = high-confidence sell fade.
The zone provides the "why" for the reversal.

## Optimize
- Impulse threshold: 1.5x, 2.0x, 2.5x, 3.0x ATR
- Pause bars (wait for exhaustion): 2, 3, 5 bars
- TP level: 23.6%, 38.2%, 50% retracement
- SL method: impulse extreme vs impulse extreme + 2 pips
- Cooldown: minimum 10, 20, 30 bars between impulse trades
- Session filter: London+NY only vs all sessions

## Notes
This is a counter-trend scalp, so position sizing should be conservative
(0.5x normal size). The edge is that most impulses overshoot and retrace —
the question is whether we can reliably identify exhaustion before continuation.
v3 (WT divergence) and v4 (SMC zone) are the highest-conviction filters.
Expect low frequency — maybe 1-3 trades per day on M1.
