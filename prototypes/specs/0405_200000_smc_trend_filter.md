# SMC Trend Filter for WT Entries

## Thesis
The current EA takes WaveTrend crossover signals in both directions regardless
of market structure. But SMC BOS/CHoCH already tells us which direction
institutional flow is moving. WT signals that ALIGN with the prevailing SMC
structure are pullback entries in a trend — they have better follow-through
because institutional order flow supports the move. Counter-structure WT signals
are fighting the flow and more likely to stop out. Filtering by structure should
improve the EA's 15.5% win rate and PF 1.09 without reducing the R:R.

## Evidence
- **WT crossover validated (PF 1.09, Sharpe 1.21)** — the signal is real but
  marginal. Improvement must come from filtering, not adding indicators.
- **RSI confirmed redundant** — momentum-based filters don't help because WT
  already captures momentum. We need a STRUCTURAL filter, not another momentum one.
- **Earlier decision (2026-04-03) proposed 200 SMA trend filter** — same
  intuition (trade with trend), but 200 SMA is a lagging indicator that doesn't
  reflect real market structure. SMC BOS/CHoCH is event-driven and reacts to
  actual structural breaks.
- **SMC_Core.mqh already computes BOS/CHoCH** — the g_breaks[] array and
  g_smcState.trend are already updated every bar. No new indicators needed.
- **OB rejection scalp showed SMC has predictive power (PF 1.06, 384 trades)** —
  structure-based signals produce real, if thin, edges on M1.

## Base (v1): BOS direction filter
Timeframe: M1
Logic: Only take WT signals that match the most recent BOS direction.
Entry buy: WT oversold crossover AND g_smcState.trend == 1 (last BOS was bullish)
Entry sell: WT overbought crossover AND g_smcState.trend == -1 (last BOS was bearish)
Exit: Same as current EA (ATR SL, SMC zone TP)
Indicators: WaveTrend.mqh + SMC_Core.mqh (both already loaded)
M10 confirmation: keep as-is

## v2: BOS direction filter + CHoCH pause
Same as v1, but also pause ALL entries for N bars after a CHoCH event.
CHoCH means structure just reversed — the new trend isn't confirmed yet.
Wait for the next BOS in the new direction before re-entering.
Why this might work: CHoCH is the highest-uncertainty moment. The bars
immediately after CHoCH are choppy as buyers and sellers fight for control.
Sitting out avoids whipsaw losses.
Why this might fail: On M1, CHoCH happens frequently. The pause window
might eat up too many potential entries, reducing trade count below useful levels.

## v3: Consecutive BOS filter (2+ in same direction)
Same as v1, but require 2+ consecutive BOS in the same direction before
allowing entries. Single BOS could be noise; consecutive BOS confirms
a real structural trend.
Why this might work: This is the "established trend" definition from
the ROADMAP M2 milestone. Multiple BOS = clear institutional commitment.
WT pullback entries in an established trend are the textbook setup.
Why this might fail: Requiring 2+ consecutive BOS dramatically narrows
opportunities. On M1, structural trends are short-lived — by the time
we have 2 BOS, the move might already be exhausted.

## v4: Opposing structure = counter-trend block
Instead of filtering entries, use structure to MODIFY position management.
Take all WT signals (both directions), but:
- If signal aligns with structure: normal SL
- If signal opposes structure: use tighter SL (0.75x ATR instead of 1.5x)
Why this might work: We don't miss any trades, but we size the risk
appropriately. Counter-trend trades get tight stops (small loss if wrong),
trend-aligned trades get room to breathe.
Why this might fail: Tighter SL on counter-trend trades might just cause
more frequent stops without improving overall EV. The trades that would
have worked now get stopped out too early.

## v5: Structure trend + time decay
Same as v1, but the structure filter "decays" over time. If no new BOS
has occurred in the last 200 bars, treat the structure as neutral and
allow both directions again.
Why this might work: SMC trends on M1 have a shelf life. A BOS from
3 hours ago doesn't tell us much about current conditions. Adding decay
prevents stale structure from blocking valid signals.
Why this might fail: 200 bars is arbitrary. The optimal decay window
would need optimization, adding a parameter that risks overfitting.

## Interaction with existing strategies
This is NOT a new strategy — it's a filter on the existing WT entry.
The EA currently uses SMC only for TP targeting (SMC_FindNearestZone).
This would add SMC as an entry filter too. Both uses are already computed
in OnTick() — no additional indicator handles or warmup needed.

Risk: if the filter removes too many trades, the already-marginal PF 1.09
edge becomes statistically insignificant (too few trades). The baseline
has 251 trades/year — a 50% filter would leave ~125, which is still OK.

## Optimize
- BOS direction: require match (v1) vs require 2+ consecutive (v3)
- CHoCH pause: 0, 10, 20, 50 bars (v2)
- Opposing SL multiplier: 0.5x, 0.75x, 1.0x ATR (v4)
- Structure decay: 0 (no decay), 100, 200, 500 bars (v5)

## Notes
This is the highest-leverage idea because it improves the existing
validated edge rather than building a new unproven strategy. The
infrastructure is already in place — just logic changes in CheckEntry().
If v1 improves PF even to 1.15, that's more valuable than any new
strategy at PF 1.06.
