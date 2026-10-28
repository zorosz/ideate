# London Close Mean Reversion

## Thesis

At London close (16:00 GMT, ~17:00-18:00 CET depending on DST), the largest
FX session in the world unwinds for the day. London-based institutional
desks neutralize positions ahead of book settlement, day traders take
profit, and the volume-weighted center of London's session becomes a
magnet as participants exit toward fair value.

The structural pattern is consistent: in the final 30-60 minutes of London,
whichever direction the day moved most in becomes a fade target. Price
drifts back toward the session midpoint or daily pivot. This is NOT
WaveTrend-style oscillator mean reversion — it is calendar-driven, flow-
based mean reversion. The trigger is the clock, not an indicator.

The window is narrow (16:00-18:00 CET, ~120 minutes max), exactly the kind
of structural trigger that fills the idle gap between WT signals without
overlapping with them.

## Evidence

1. **WT crossover validated (#1, PF 1.09)**: Mean reversion edge exists on
   EURUSD M1. We're applying the same principle in a session-specific
   window where the structural driver is documented (institutional
   unwinding) rather than indicator-driven.

2. **Project context — 17:00-22:00 CEST is strongest session**: London
   close is at the START of this window. The strategy targets the highest-
   quality hour of the EA's preferred session.

3. **DECISION 2026-04-03 — Mean reversion needs ranging market filter**:
   London close is structurally ranging because the directional driver
   (London flow) is exiting. The session itself filters for the correct
   regime.

4. **Failed Asian Range Breakout (#2)**: shows that session-anchored
   strategies CAN fail on M1 when the direction is wrong. ARB tested
   breakouts; this tests the inverse (mean reversion). Different trade,
   complementary lesson.

5. **Order Block Rejection Scalp (#3) — 23% WR / 3.7:1 RR validated**:
   reversal patterns at structural extremes do produce edge. London
   close anchors are structurally similar to fresh order blocks (real
   institutional levels).

6. **Engle and Patton 2001** (academic): foreign exchange mean reverts to
   fair value after liquidity providers absorb directional flow. London
   close is one of the cleanest examples of this pattern in FX.

## Base (v1)

**Timeframe**: M1

**Setup detection** (every M1 bar):
- Current CET hour must be within `[WindowStartHour, WindowEndHour)` —
  default [16:00, 18:00)
- Compute today's London session anchor:
  - SessionHigh = max(High) since 09:00 CET
  - SessionLow  = min(Low)  since 09:00 CET
  - SessionMid  = (SessionHigh + SessionLow) / 2
  - SessionRange = SessionHigh - SessionLow (in pips)
- Distance from current bid to extreme:
  - distHigh = (SessionHigh - Bid) in pips
  - distLow  = (Bid - SessionLow)  in pips
- Setup conditions:
  - SELL if `distHigh < ProximityPips` AND `SessionRange >= MinRangePips`
  - BUY  if `distLow  < ProximityPips` AND `SessionRange >= MinRangePips`

**Confirmation**:
- WaveTrend in matching exhaustion zone:
  - SELL: `WT > +WT_OB`
  - BUY:  `WT < -WT_OS`

**Entry**:
- Market entry on confirmed signal bar
- Single position, never both directions

**Exit**:
- TP: SessionMid (variable distance, structural target)
- SL: SessionExtreme + (`SL_ATR` × ATR(14))
- Time stop: hard close at `WindowEndHour` regardless of P&L

**Indicators**: WaveTrend, ATR(14), session anchor (custom)

## v2: Daily pivot anchor

Same as v1 but use the daily pivot point (P = (PriorHigh + PriorLow +
PriorClose) / 3) as the TP target instead of SessionMid.

**Why this might work**: Daily pivot is universally watched by retail and
institutional traders alike. More eyes on the level = stronger magnet.
Removes session start/end ambiguity (DST issues).

**Why this might fail**: Daily pivot is calculated from PRIOR day, not
current. If current day moves strongly directional, pivot is "behind" the
market — already passed and irrelevant as a target.

## v3: VWAP target

Same as v1 but compute session VWAP (cumulative tick-volume-weighted
price since 09:00 CET) and use it as the TP target.

**Why this might work**: VWAP is the institutional benchmark used to
measure desk performance. Closing the day near VWAP is a real metric for
many traders. Magnet effect should be strongest.

**Why this might fail**: M1 tick volume on EURUSD is unreliable (no real
volume in FX). VWAP becomes a noisy approximation of "real" VWAP. Added
complexity may not outperform simple session midpoint.

## v4: Wider time window

Same as v1 but window is `[15:00, 19:00)` CET (4 hours instead of 2).

**Why this might work**: Includes the late London session and the start
of NY proper. More signal opportunities. Catches late-arriving unwinds.

**Why this might fail**: After 17:30 CET, NY session takes over and the
mean-reversion regime ends. Trades after that point may be against
emerging NY trends — directly conflicting with the NY Open Continuation
sister idea.

## v5: Range-day filter

Same as v1 but only trade if `MinRangePips <= SessionRange <= MaxRangePips`.
Excludes both quiet days (no juice) and trending days (reversion fails).

**Why this might work**: Filters for the correct regime — the strategy
needs movement to fade but not so much that mean reversion breaks. Range
is the cleanest objective regime indicator.

**Why this might fail**: Adds two parameters that may be optimized to a
specific period. Range thresholds vary by year (2023 ranges differ from
2025). Risk of curve fit.

## v6: WT cross required (not just exhaustion)

Same as v1 but require an actual WT bull/bear cross within the last
`MaxCrossAge` bars during the session window — not just OS/OB.

**Why this might work**: Cross is the validated signal (#1). Proximity
to extreme + WT cross + session window = triple confirmation. Higher
quality, lower frequency.

**Why this might fail**: Cross requirement collapses signal count inside
a 2-hour window. May leave only single-digit trades per year.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: This IS a session-restricted WT
  strategy (with v1 using exhaustion confirmation). Filter is additive —
  most existing WT signals fall outside this window, so the strategies
  share few trades.

- **vs WT + CHoCH (sister 0408_120100)**: CHoCH variant uses structural
  trigger; this uses session/calendar trigger. Should be uncorrelated and
  complementary.

- **vs Liquidity Sweep Reversal (sister 0408_120000)**: Sweep is any-time
  structural fade; this is specific time-of-day fade. Some overlap
  possible at London close (sweeps cluster at session end), but triggers
  are different enough to coexist.

- **vs NY Open Continuation (sister 0411_012700)**: 1-hour overlap from
  16:00-17:00. NY open is going long-momentum, this is fading the day.
  Direct conflict possible. Resolve via either time-window separation or
  by accepting that contradicting positions cancel risk.

- **vs hedge accumulators**: Different magic, no conflict. Hedge runs
  24/7; this only runs 16:00-18:00 CET.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `WindowStartHour` | 15-17 | 1 | Start of session-close window (CET) |
| `WindowEndHour` | 17-19 | 1 | End of session-close window (CET) |
| `ProximityPips` | 5-30 | 5 | Distance from extreme to trigger |
| `MinRangePips` | 30-100 | 10 | Day must have moved this much |
| `MaxRangePips` (v5) | 100-200 | 25 | Day mustn't be too directional |
| `WT_OB` | 50-70 | 5 | Overbought confirmation level |
| `WT_OS` | -70 to -50 | 5 | Oversold confirmation level |
| `SL_ATR` | 1.0-2.5 | 0.5 | ATR multiplier for SL |
| `MaxCrossAge` (v6) | 3-15 | 3 | Bars allowed since WT cross |

## Notes

**Market condition targeted**: London close winding-down regime — narrow
2-hour window per trading day. Strategy is silent ~22 hours/day.

**Risk profile**: Mid win rate (target 55-65%), modest R:R (target
1.2-1.8:1). Session-anchor TP is variable, so R:R isn't fixed. Time stop
at WindowEndHour caps holding period.

**DST handling**: London close is 16:00 GMT year-round, but CET clock
changes twice a year. Use `TimeTradeServer` in GMT, convert to local clock
for the window check. NEVER hard-code 16-18 CET without DST awareness or
the strategy will be 1 hour off for half the year.

**Edge cases**:
1. **Day's range very small (< MinRangePips)**: no real "extreme" exists.
   Skip via filter.
2. **Strong news at 17:00** (e.g. ECB meeting late) — NewsFreezeGuard
   handles the freeze; don't override.
3. **Holiday weeks** (Christmas, Easter): London volume drops sharply.
   Strategy may misfire because the unwind isn't real. Consider a holiday
   filter for production but probably not for v1.
4. **Overlap with NY open at 15:30-16:30**: for window starting at 16:00,
   the first 30 min is overlap. NY momentum may push price further, not
   reverse it. Watch for early-window losses in backtest.

**Failure modes to watch**:
- Win rate < 50% → window timing wrong, NY trend dominates the close
- Avg loss > 2× avg win → time stop too loose, holding into NY hours
- All winners in 2024-2025, fail in 2023 → regime-dependent (expected;
  2023 was a strongly trending year)
- Total trades < 30/year → window or proximity filter too strict
