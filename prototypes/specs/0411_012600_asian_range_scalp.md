# Asian Session Range Scalp

## Thesis

During the Asian session (00:00-07:00 CET), EURUSD is in caretaker mode.
London is closed, NY is closed, Tokyo desks don't trade EUR heavily. The
result is a tight, low-volatility range — typically 15-40 pips peak to
trough — anchored around the European close price. There is no directional
driver, only noise around equilibrium.

In this regime, the simplest mean-reversion edge exists: scalp the range
extremes back toward the middle. Tight stops, small targets, high win rate.
The trade is structurally protected because the regime ITSELF is mean
reverting — there is no force trying to break the range until London
opens. We are not betting on reversion; we are betting on absence of trend.

This fills the project's "idle time" gap explicitly: WaveTrend mean
reversion fires rarely on Asian session because oscillator extremes are
also rare in low volatility; this strategy THRIVES on that same stability.

## Evidence

1. **Key Learning #25 — Session filter HURTS hedge accumulators**:
   removing Asian session harvests dropped PF from 1.83 to 1.67. This
   proves Asian session has tradeable volatility. The hedge made money
   harvesting tiny moves; a directed scalper should do the same or better.

2. **WT crossover validated (#1, PF 1.09) — but signal density is low**:
   WT crosses are not enough to keep the EA active in Asian hours. A
   different trigger family (range location) is needed.

3. **Failed Asian Range Breakout (#2)**: ARB failed because Asian
   breakouts are FAKES. The inverse — fading Asian range extremes —
   should work for the same reason. Same evidence, opposite trade.

4. **DECISION 2026-04-03 — Mean reversion needs ranging market**: Asian
   session is the most reliably ranging session on EURUSD. ADX would
   nearly always pass during these hours. The session pre-filters for the
   correct regime.

5. **Project context — idle time problem**: WT-only strategies are
   silent 00:00-07:00 CET. This window has 7 hours of unused time per
   day. A scalper that captures 1-3 setups per night would dramatically
   increase total trade-hours of the EA.

6. **Order Block Rejection Scalp validated profile (#3)**: low WR /
   high RR was OBR's result. This strategy targets the INVERSE profile —
   high WR / low RR — which is the natural shape of range scalping.
   Different statistical signature, same family.

## Base (v1)

**Timeframe**: M1

**Range definition** (recomputed every M1 bar during Asian session):
- RangeHigh = max(High) over last `RangeLookbackBars` bars (default 60)
- RangeLow  = min(Low)  over last `RangeLookbackBars` bars
- RangeWidth = (RangeHigh - RangeLow) in pips
- Trade only if `MinRangePips <= RangeWidth <= MaxRangePips`

**Setup**:
- BUY  if `Bid <= RangeLow + ProximityPips`
- SELL if `Bid >= RangeHigh - ProximityPips`

**Time filter**:
- Only between `WindowStartHour` (default 00:30 CET) and `WindowEndHour`
  (default 07:00 CET)
- 00:30 start avoids the rollover spread spike (23:00-00:30 server time)

**Entry**:
- Market entry, single position, never both directions

**Exit**:
- TP: middle of range (RangeLow + RangeWidth/2)
- SL: opposite range edge + `StopBufferPips`
- Time stop: hard close at 07:30 CET

**Indicators**: None — pure price action

## v2: WaveTrend confirmation

Same as v1 but require WT in matching exhaustion (`> +60` for SELL,
`< -60` for BUY) on entry bar.

**Why this might work**: Validated WT edge gives a quality filter. Asian
session WT extremes should be cleanest because no directional flow
drowns the oscillator.

**Why this might fail**: Asian volatility is so low that WT extremes are
themselves rare. Filter may collapse signal count to near-zero.

## v3: Multi-touch range strength

Same as v1 but require RangeHigh/RangeLow to have been touched at least
2 times within the last `RangeLookbackBars` bars. Tested levels are
stronger.

**Why this might work**: Single-touch ranges may not be real ranges —
could be early-stage moves. Multi-touch confirms genuine equilibrium and
real liquidity at the levels.

**Why this might fail**: M1 noise creates artificial multi-touches as
spread fluctuates around a tight range. Filter may not actually
distinguish real ranges from random.

## v4: Range-width sweet spot

Same as v1 but tighter range filter (e.g. 15-25 pips width). Skip narrow
ranges (no juice) and wide ranges (regime change imminent).

**Why this might work**: Sweet-spot range is wide enough for spread to be
overcome, narrow enough that reversion is statistically reliable. Targets
optimal microstructure.

**Why this might fail**: Tighter range filter = fewer trades. May reduce
to single-digit trades per week, losing statistical significance.

## v5: Asian + early London (00:30-09:00 CET)

Same as v1 but extend the window through the first 2 hours of London
session.

**Why this might work**: London open often produces a fake breakout that
reverses back into the Asian range. Trading those reversals would capture
the inverse alpha of what ARB tried to capture.

**Why this might fail**: Once London proper begins (~09:00 CET), the
regime shifts to directional and the range scalper bleeds. Crossing the
session boundary is risky — one bad day could erase weeks of gains.

## v6: ATR percentile regime gate

Same as v1 but additionally require ATR(14) on M15 to be in the bottom
40% of its 20-day distribution. Targets only verifiably-quiet sessions.

**Why this might work**: Volatility regime is the actual filter we want;
range width is just a proxy. Direct ATR filter is more honest.

**Why this might fail**: Percentile filters are inherently look-ahead
unless implemented carefully. ATR distribution must be computed on prior
20 days only, NEVER including current.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: WT is mostly silent during
  Asian hours due to low volatility. This strategy fills exactly that
  gap. Trade overlap should be near-zero.

- **vs Liquidity Sweep Reversal (sister)**: Sweeps target swing extreme
  pierces — different trigger. Sweeps are rare in Asian session because
  liquidity isn't deep enough for institutional sweeps. Should not
  conflict.

- **vs hedge accumulators**: Hedges trade Asian session profitably (Key
  Learning #25). This scalper would compete for tick movements with
  hedges. Different magic numbers prevent direct conflict, but they may
  fight for fills if running on the same chart. Should test in isolation
  first.

- **vs London Close Mean Reversion (sister 0411_012500)**: Both are
  session-anchored mean reversion but at opposite ends of the day.
  Together they cover the calmest hours and the unwinding hours, leaving
  the middle session for trend strategies.

- **vs NY Open Continuation (sister 0411_012700)**: No time overlap.
  Complementary by design.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `RangeLookbackBars` | 30-120 | 15 | Bars used to define range |
| `MinRangePips` | 8-25 | 3 | Minimum range to trade |
| `MaxRangePips` | 25-60 | 5 | Maximum range to trade |
| `ProximityPips` | 1-5 | 1 | Distance to edge for trigger |
| `StopBufferPips` | 2-8 | 1 | SL buffer beyond range |
| `WindowStartHour` | 0-2 | 1 | CET start hour (>= 00:30 for spread) |
| `WindowEndHour` | 6-9 | 1 | CET end hour |

## Notes

**Market condition targeted**: Asian session low-volatility ranging on
EURUSD. Strategy is silent ~17 hours/day, active ~7 hours.

**Risk profile**: High win rate (target 65-75%), low R:R (target 0.7-1.2:1).
Profile is natural for range scalping but psychologically vulnerable to
runaway losses if regime breaks. Time stop is critical.

**Spread risk**: Spread is widest during rollover (23:00-00:30 server
time). The 00:30 start avoids this. NEVER lower the start hour below
00:30 without verifying spread by chart inspection.

**Edge cases**:
1. **News during Asian hours** (RBA, BoJ, Chinese data): can break the
   range. NewsFreezeGuard handles macro news but Asian-Pacific data may
   not be in the calendar. Watch for unexplained losses around 02:00 CET
   (Sydney/Tokyo data times).
2. **Holiday Asian session**: lower volume, narrower ranges. May not
   meet `MinRangePips`. Strategy naturally skips, no special handling
   needed.
3. **Spread spike at 00:00**: rollover. Skip first 30 min — handled by
   `WindowStartHour` default.
4. **End-of-Asian breakout (07:00-08:00)**: traders position for London,
   range may break. Time stop at 07:30 limits this.

**Failure modes to watch**:
- Win rate < 55% → range definition wrong, false ranges being traded
- Avg loss > 1.5× avg win → stops too tight or regime breaks too often
- Profitable in low-vol years only → may need ATR-percentile filter
- Total trades < 100/year → range filter too restrictive

**Open question**: should the range be defined as a simple lookback
window or as the M15-bar range (e.g. last 4 M15 candles)? M15 range is
more structurally meaningful but less responsive to mid-session
contractions.
