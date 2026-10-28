# NY Open Momentum Continuation

## Thesis

The NY open at 14:30 GMT (15:30 CET in winter, 14:30 CEST in summer)
brings the second-largest FX trading session online. US-based
institutional flow arrives, overnight algorithmic orders are released,
and US traders react to the price action that already developed during
London. The first 60-90 minutes of NY are typically a CONTINUATION of
the London bias, not a reversal. Mean reversion doesn't take over until
the late afternoon.

This is structurally different from every other strategy in the project:
it's a MOMENTUM-FOLLOWING trade, not mean reversion. The current EA
stack is heavily mean-reversion biased (WaveTrend, BB+RSI, hedge
accumulators, sister Liquidity Sweep, sister WT+CHoCH). The absence of a
directional momentum component is a real coverage gap — during strongly
trending months, the EA underperforms because it has no strategy that
profits from continuation.

The window is narrow (15:30-17:00 CET) and the trigger is simple:
identify London's net direction and trade with it for one hour. This
avoids the typical problem of trend-following on M1 (too much noise) by
using a structural cue (session change) rather than an indicator
threshold.

## Evidence

1. **Combined hedge strongest in 2023 trending year (#10)**: PF 1.54 in
   2023 vs PF 1.19 in 2024. Key Learning #23: "the lot increment profits
   MORE in trends because larger positions move further on reversal."
   This proves momentum exists on EURUSD M1; the hedge captures it
   indirectly. A direct momentum strategy should profit even more.

2. **All existing strategies are mean-reverting** — WT, BB+RSI, hedge
   accumulators, sister Liquidity Sweep, sister WT+CHoCH. **This is a
   documented strategic gap.** The EA is asymmetric in its market view.

3. **Failed Asian Range Breakout (#2)**: ARB failed because Asian
   session has no real flow to break the range. NY open is the OPPOSITE
   — the highest-flow moment of the trading day. The same trigger
   family (breakout/momentum) that failed in Asian session should work
   when the structural conditions are inverted.

4. **Project context — 17:00-22:00 CEST is strongest session**: NY
   proper starts at 15:30 CET. The first 90 min of NY is the entry to
   the project's preferred window. This strategy fills the OPENING of
   the strongest session.

5. **Key Learning #6 — BOS direction filter too aggressive on M1**: BOS
   is too rare to be a momentum filter. Using session change as a
   "structural session BOS" (one-shot per day) avoids the over-filtering
   problem because it uses time, not structure-detection, as the trigger.

6. **Lyons 2001 / Evans 2002** (academic): order flow at session changes
   has the largest impact on FX prices because liquidity providers are
   recalibrating risk. The first hour of NY is one of the highest-
   information moments of the trading day.

## Base (v1)

**Timeframe**: M1

**Setup detection** (every M1 bar):
- Wait until current CET hour reaches `WindowStartHour` (default 15:30)
- At `WindowStartHour`, evaluate London session bias:
  - LondonOpenPrice = price at 09:00 CET (today)
  - LondonClosePrice = current bid
  - LondonMove = (LondonClosePrice - LondonOpenPrice) in pips
- Direction:
  - LondonMove > +`MinMovePips` → BULLISH bias → BUY
  - LondonMove < -`MinMovePips` → BEARISH bias → SELL
  - `|LondonMove| < MinMovePips` → SKIP (no clear bias)

**Entry**:
- Single market order at `WindowStartHour` (or first available bar after)
- Single position only, no scaling

**Exit**:
- TP: |LondonMove| × `TPMultiplier` (e.g. 0.6 × London move) added to
  current price in trade direction
- SL: ATR(14) × `SL_ATR` (e.g. 1.5 × ATR) against entry
- Time stop: hard close at `WindowEndHour` if neither hit

**Indicators**: ATR(14), session anchor (custom)

## v2: Breakout confirmation

Same as v1 but require price to BREAK either today's London high or
London low at the moment of entry, not just close in a direction.

**Why this might work**: Breakout is a stronger continuation signal
than close-direction. Reduces false starts where London closed near
range middle.

**Why this might fail**: Adds latency — breakout may happen at 16:30
CET, leaving only 30 min for the trade. Time stop becomes the dominant
exit and trade duration is too short for momentum to develop.

## v3: First impulse extension

Same as v1 but instead of trading at exactly `WindowStartHour`, wait for
the first M1 bar after `WindowStartHour` with `(High - Low) > MinImpulsePips`.
Trade in that bar's body direction.

**Why this might work**: First impulse bar identifies the moment when NY
flow actually arrives, not just when the clock changes. More precise
timing.

**Why this might fail**: First impulse may be a fakeout that reverses.
Need stop placed beyond the impulse bar to handle this; otherwise the
fake spike costs the trade.

## v4: NewsFreezeGuard veto

Same as v1 but query NewsFreezeGuard for high-impact events at or near
`WindowStartHour`. Skip the trade entirely if any event is within
±60 minutes.

**Why this might work**: News-driven NY opens are unpredictable —
overshoot followed by retracement. Skipping them isolates the
structural-momentum thesis from event-driven volatility.

**Why this might fail**: NFP (Non-Farm Payrolls) is at 14:30 CET — the
hour BEFORE NY open. Skipping these days may filter out the most
profitable setups (when news creates the directional move that NY then
continues).

## v5: ATR-percentile filter

Same as v1 but only trade if today's London ATR (= (London H - London L))
is in the 25-75 percentile of the prior 20 trading days. Skip extreme
days (already over-extended) and quiet days (no momentum to follow).

**Why this might work**: Filters for the regime where continuation is
most reliable — moderate volatility with directional bias. Avoids both
overextension and dead markets.

**Why this might fail**: Reduces sample size. Percentile thresholds are
inherently look-ahead unless implemented strictly on prior days only.

## v6: London-bias from last 2 hours only

Same as v1 but `LondonMove` is measured from 13:30 CET (last 2 hours of
London) instead of 09:00 CET (London open). The bias is the most recent
flow direction, not the day's net.

**Why this might work**: NY traders react to the LATEST flow, not what
happened 6 hours ago. Last-2-hours bias is closer to "what the market
is doing right now" than "what it did this morning."

**Why this might fail**: 2-hour windows are noisier. The full London
session bias has more statistical significance.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: Direct counter-strategy. WT
  fades the move; this rides it. They should produce OPPOSITE signals
  during NY open. **Need careful coexistence — perhaps WT signals are
  SUPPRESSED from 15:30-17:00 CET when this strategy is active.**

- **vs hedge accumulators**: Momentum strategy fights hedge harvest
  direction during strong trends. Different magic numbers separate them
  but the hedge's accumulating side may align with this strategy's
  direction. Should coexist via magic separation.

- **vs Liquidity Sweep Reversal (sister)**: Sweep is reversal, this is
  continuation. Direct opposites. Both may be valid in different
  microstructure regimes — verify they don't fire on the same bars.

- **vs London Close Mean Reversion (sister 0411_012500)**: Sequential —
  this strategy is active 15:30-17:00, that one is active 16:00-18:00.
  There is a 1-hour overlap (16:00-17:00). During overlap, this is
  closing positions and that is opening new ones. Coexistence acceptable
  with separate magic numbers.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `WindowStartHour` | 15-16 | 0.5 | NY open hour (CET) |
| `WindowEndHour` | 16-18 | 0.5 | Trade window end |
| `MinMovePips` | 10-50 | 5 | London move threshold for bias |
| `TPMultiplier` | 0.4-1.0 | 0.1 | TP as fraction of London move |
| `SL_ATR` | 1.0-3.0 | 0.5 | ATR multiplier for SL |
| `MinImpulsePips` (v3) | 5-15 | 2 | First impulse threshold |
| `LondonStartHour` (v6) | 09-13 | 1 | London window start for bias calc |

## Notes

**Market condition targeted**: NY open momentum window. Strategy active
~90 min/day, silent ~22.5 hours/day.

**Risk profile**: Mid-low win rate (target 45-55%), high R:R (target
1.5-2.5:1). Trend-following has natural low WR and bigger winners.

**DST handling**: NY open is 14:30 GMT, but CET clock changes twice a
year. Use `TimeTradeServer` in GMT, then convert to local clock for
window check. NEVER hard-code CET hours without DST awareness.

**Critical dependency**: This strategy requires London session to have a
clear direction. If London is choppy (range close to open), no setup
fires. Trade frequency will be 100-150 setups per year max — rough
estimate based on ~250 trading days × 50% having clear direction.

**Edge cases**:
1. **NFP/CPI day**: 14:30 CET news creates the move that NY then
   continues. v1 trades the continuation; v4 skips entirely. Both
   should be tested side-by-side.
2. **Late London move (after 13:30 CET)**: most of London's directional
   move may happen in the LAST 2 hours. v6 tests this specifically.
3. **Friday afternoon**: NY momentum is weaker on Fridays (weekend
   unwinding starts). May want a Friday-skip filter or a Friday-only
   counter-strategy.
4. **US holidays**: Thanksgiving, Independence Day, MLK Day —
   reduced NY volume. Skip via calendar.

**Failure modes to watch**:
- Win rate < 35% → momentum thesis wrong, NY open is mean-reverting
- All trades stop out at time stop → TP too aggressive, market doesn't
  reach in 90 min
- Profitable in 2023 only → momentum strategy is regime-dependent. This
  is acceptable (it's the gap-filler for trending years).
- Total trades < 50/year → bias filter too strict, lower `MinMovePips`

**Open question**: Does this work as a STANDALONE EA, or only as a
hedge alongside the mean-reversion stack? Initial test should be
standalone for clean evaluation, then merged if validated.
